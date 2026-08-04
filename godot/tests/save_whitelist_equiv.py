#!/usr/bin/env python3
# save_whitelist_equiv.py
#
# 纯逻辑等价校验（非 Godot 运行；仅开发期核对 SaveManager / MasterySystem 的核心规则）。
# 镜像 godot/scripts/autoload/SaveManager.gd 的 _sanitize 白名单逻辑，
# 与 godot/scripts/core/MasterySystem.gd 的 mastery_for_skill 规则。
# 运行：python3 godot/tests/save_whitelist_equiv.py

ALLOWED_KEYS = ["saveVersion", "mastery", "visited", "settings"]
FORBIDDEN = ["relationshipSignal", "consequence", "s9Account"]
MAX_LEVEL = 3


def sanitize(d):
    """镜像 SaveManager._sanitize：仅保留白名单键；mastery 钳制 0-3；visited 转字符串。"""
    out = {"saveVersion": 1, "mastery": {}, "visited": [], "settings": {}}
    if "mastery" in d and isinstance(d["mastery"], dict):
        for k, v in d["mastery"].items():
            out["mastery"][str(k)] = max(0, min(MAX_LEVEL, int(v)))
    if "visited" in d and isinstance(d["visited"], list):
        out["visited"] = [str(x) for x in d["visited"]]
    if "settings" in d and isinstance(d["settings"], dict):
        out["settings"] = dict(d["settings"])
    return out


def mastery_for_skill(records, scenarios):
    """镜像 MasterySystem.mastery_for_skill：0-3 档；replay 累加；skilled 保底 1；钳制。"""
    if not scenarios:
        return 0
    plays = 0
    skilled = False
    for sid in scenarios:
        rec = records.get(sid)
        if rec:
            plays += rec["plays"]
            if rec["skilled"]:
                skilled = True
    lvl = max(0, min(MAX_LEVEL, plays))
    if skilled:
        lvl = max(lvl, 1)
    return max(0, min(MAX_LEVEL, lvl))


def record(records, sid, skilled):
    r = records.setdefault(sid, {"plays": 0, "skilled": False})
    r["plays"] += 1
    if skilled:
        r["skilled"] = True


def test_whitelist():
    dirty = {
        "saveVersion": 1,
        "mastery": {"s01-shake-the-hive": 3},
        "visited": ["s01_scene_01"],
        "settings": {},
        "relationshipSignal": -1,
        "consequence": {"npcReaction": "x", "relationshipSignal": 0},
        "s9Account": 42,
    }
    clean = sanitize(dirty)
    for k in clean.keys():
        assert k in ALLOWED_KEYS, f"非白名单键泄露: {k}"
    for f in FORBIDDEN:
        assert f not in clean, f"禁出盘字段未剔除: {f}"
    assert clean["mastery"]["s01-shake-the-hive"] == 3
    print("OK  whitelist: 仅留白名单键，relationshipSignal/S9/consequence 全程剔除")


def test_mastery():
    s01 = ["s01_a", "s01_b"]
    recs = {}
    assert mastery_for_skill(recs, s01) == 0
    record(recs, "s01_a", False)
    assert mastery_for_skill(recs, s01) == 1, "玩1场景→1"
    record(recs, "s01_b", False)
    assert mastery_for_skill(recs, s01) == 2, "玩2场景→2"
    record(recs, "s01_a", False)
    record(recs, "s01_a", False)
    assert mastery_for_skill(recs, s01) == 3, "超量replay钳制3"

    recs2 = {}
    record(recs2, "s01_a", True)
    assert mastery_for_skill(recs2, s01) == 1, "skilled保底1档"
    # 跨技能不串扰
    assert mastery_for_skill(recs2, ["s03_a"]) == 0
    # 空列表
    assert mastery_for_skill(recs2, []) == 0
    print("OK  mastery: replay递增 / skilled保底 / 不串扰 / 钳制3 / 空列表0")


if __name__ == "__main__":
    test_whitelist()
    test_mastery()
    print("ALL PY EQUIV CHECKS PASSED")
