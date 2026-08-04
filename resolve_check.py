#!/usr/bin/env python3
"""等价逻辑校验：复刻 ConsequenceEngine.resolve，跑真实 s01/s04 JSON 验证路由。"""
import json, os

BASE = r"c:\Users\admin\WorkBuddy\2026-08-04-09-27-03\godot\data\scenarios"


def load(name):
    with open(os.path.join(BASE, name), encoding="utf-8") as f:
        return json.load(f)


def find_by_id(scn, cid):
    for c in scn["choices"]:
        if c["id"] == cid:
            return c
    return None


def find_by_type(scn, t):
    for c in scn["choices"]:
        if c["type"] == t:
            return c
    return None


def resolve(scn, chosen_choice_id, trigger_correct):
    if scn is None:
        return None
    triggers = scn.get("triggers")
    miss = triggers.get("miss") if triggers else None
    # 方案A：识别错优先 miss
    if (not trigger_correct) and miss is not None:
        return miss
    # forceBoundary：确定性路由 boundary
    if scn.get("forceBoundary", False):
        b = find_by_type(scn, "boundary")
        if b is not None:
            return b["consequence"]
    # 正常：所选 choice
    if chosen_choice_id != "":
        c = find_by_id(scn, chosen_choice_id)
        if c is not None:
            return c["consequence"]
    # 降级：首个 choice
    if scn.get("choices"):
        first = scn["choices"][0]
        if first.get("consequence") is not None:
            return first["consequence"]
    return None


def check(name, cond):
    print(("PASS" if cond else "FAIL") + " - " + name)
    return cond


results = []
s01 = load("s01_scene_01.json")
s04 = load("s04_scene_01.json")

# 1) s01 识别错（无选）→ miss
r = resolve(s01, "", False)
results.append(check("s01 wrong-trigger -> miss", r is not None and r["npcReaction"] == s01["triggers"]["miss"]["npcReaction"]))

# 2) s04 forceBoundary 即便选 skilled(c1) 也路由 boundary
boundary = find_by_type(s04, "boundary")
r = resolve(s04, "c1", True)
results.append(check("s04 forceBoundary routes to boundary (even when skilled chosen)",
                     r is not None and r["npcReaction"] == boundary["consequence"]["npcReaction"]
                     and r["npcReaction"] != find_by_id(s04, "c1")["consequence"]["npcReaction"]))

# 3) s01 去掉 miss + 识别错（无选）→ 降级首个 choice，非 null 不崩溃
s01_nomiss = json.loads(json.dumps(s01))
del s01_nomiss["triggers"]["miss"]
r = resolve(s01_nomiss, "", False)
results.append(check("s01 no-miss fallback (non-null, no crash)",
                     r is not None and r["npcReaction"] == s01["choices"][0]["consequence"]["npcReaction"]))

# 4) s01 识别正确 + 选 c2(skilled) → 正常返回 c2
r = resolve(s01, "c2", True)
results.append(check("s01 correct + choose c2 -> c2 consequence",
                     r is not None and r["npcReaction"] == find_by_id(s01, "c2")["consequence"]["npcReaction"]))

# 5) 关系信号仅暴露：s01 选 c1(trap) 信号应为 -1；miss 信号 -1
r = resolve(s01, "c1", True)
results.append(check("s01 choose c1 relationshipSignal == -1", r["relationshipSignal"] == -1))
r = resolve(s01, "", False)
results.append(check("s01 wrong-trigger miss relationshipSignal == -1", r["relationshipSignal"] == -1))

print("\nALL PASS" if all(results) else "\nSOME FAILED")
