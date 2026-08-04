#!/usr/bin/env python3
# session_progress_equiv.py
#
# 纯逻辑等价校验（非 Godot 运行；仅开发期核对 PlaySession._played 的累积契约）。
# 镜像 godot/scripts/systems/PlaySession.gd 中 P1 修复后的进度累积逻辑：
#   - load(sid)：切到某场景（不清除 _played，跨场景累积）
#   - resolve(chosen_type)：在结算（进入 S5 前）记录 _played[sid] = chosen_type
#                           （"" = 识别错 / 未抉择，仍记 visited）
#   - replay(sid)：重新 load 同 id 后再 resolve，用同 key 覆盖，不膨胀
#   - get_played_results()：返回 _played 副本
# 运行：python3 godot/tests/session_progress_equiv.py
# 与 Sprint2/Sprint3 的 save_whitelist_equiv.py 风格一致。

def make_session():
    """返回一张模拟 PlaySession 内部态的 dict（仅含本校验需要的字段）。"""
    return {"_played": {}, "_scenario_id": None}


def load(s, sid):
    """镜像 load_scenario：切到某场景；不清除 _played（跨场景累积）。"""
    s["_scenario_id"] = sid


def resolve(s, chosen_type):
    """镜像 _render_consequence 开头的记录：进入 S5 前记录当前场景已玩结果。"""
    sid = s["_scenario_id"]
    if sid is not None:
        s["_played"][sid] = chosen_type


def replay_resolve(s, sid, chosen_type):
    """镜像 replay_current：重新 load 同 id 后再 resolve（同 key 覆盖）。"""
    load(s, sid)
    resolve(s, chosen_type)


def get_played_results(s):
    """镜像 get_played_results：返回 _played 副本。"""
    return dict(s["_played"])


def test_multi_scene_no_loss():
    # s01_scene_01：识别正确 + 选 skilled；next → s01_scene_02：识别正确 + 选 trap。
    s = make_session()
    load(s, "s01_scene_01")
    resolve(s, "skilled")
    load(s, "s01_scene_02")
    resolve(s, "trap")

    res = get_played_results(s)
    assert "s01_scene_01" in res, "s01_scene_01 应被记录（多场景不丢）"
    assert "s01_scene_02" in res, "s01_scene_02 应被记录（多场景不丢）"
    assert res["s01_scene_01"] == "skilled", "s01_scene_01 归因 skilled"
    assert res["s01_scene_02"] == "trap", "s01_scene_02 归因 trap（非入口/末屏误归因）"
    print("OK  multi-scene: 两场景均记录、归因正确（不丢、不误归因入口）")


def test_miss_records_visited():
    # 识别错：chosen_type 为空串，仍记 visited（SkillMap 判 skilled=false 但仍 mark_visited）。
    s = make_session()
    load(s, "s01_scene_01")
    resolve(s, "")

    res = get_played_results(s)
    assert "s01_scene_01" in res, "识别错场景仍应在已玩结果中（记 visited）"
    assert res["s01_scene_01"] == "", "识别错记为空串 → skilled=false 但仍 visited"
    print("OK  miss: 识别错仍记 visited（chosen_type=''）")


def test_replay_no_inflation():
    # replay 同场景多次：同 key 覆盖，不膨胀；保留最后一次 chosen_type。
    s = make_session()
    load(s, "s01_scene_01")
    resolve(s, "trap")
    replay_resolve(s, "s01_scene_01", "skilled")
    replay_resolve(s, "s01_scene_01", "skilled")

    res = get_played_results(s)
    assert len(res) == 1, "replay 同 key 覆盖，字典不膨胀"
    assert res["s01_scene_01"] == "skilled", "replay 后保留最后一次 chosen_type"
    print("OK  replay: 同 key 覆盖不膨胀，保留末次值")


if __name__ == "__main__":
    test_multi_scene_no_loss()
    test_miss_records_visited()
    test_replay_no_inflation()
    print("ALL SESSION PROGRESS EQUIV CHECKS PASSED")
