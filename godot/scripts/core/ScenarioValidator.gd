# ScenarioValidator.gd  (core)
# E1-S3 加载期校验（约束4 / 控制清单 A6 / A7）
#
# validate(dict) -> Dictionary { ok, has_review_case, miss_isomorphic, errors[] }
#   规则：
#     - 必填字段齐全：id/skill/title/context/impulse/triggers/choices/review
#                      + npc{name,role,mood} + triggers{candidates,correct}
#                      + review{mechanism,migration}
#     - triggers.correct ∈ triggers.candidates                       (A6)
#     - choices 含 ≥1 个 type=="skilled"                            (A6)
#     - review.case 缺失 → ok 仍为 true，但 has_review_case=false    (A7 降级不崩溃)
#     - triggers.miss 若存在 → 须与 consequence 同构                  (约束4 / G2 方案A)
#        （含 npcReaction / relationshipSignal / judgement）；缺失则视为同构（无违例）
extends RefCounted

const REQUIRED_TOP := ["id", "skill", "title", "context", "impulse", "triggers", "choices", "review"]
const REQUIRED_NPC := ["name", "role", "mood"]
const REQUIRED_TRIGGERS := ["candidates", "correct"]
const REQUIRED_REVIEW := ["mechanism", "migration"]   # case 可选
const CONSEQUENCE_SHAPE := ["npcReaction", "relationshipSignal", "judgement"]


func validate(dict: Dictionary) -> Dictionary:
    var errors := []
    var ok := true

    # 顶层必填
    for k in REQUIRED_TOP:
        if not dict.has(k):
            errors.append("缺少必填字段: " + k)
            ok = false

    # npc 必填子字段
    if dict.has("npc"):
        var npc: Dictionary = dict["npc"]
        for k in REQUIRED_NPC:
            if not npc.has(k):
                errors.append("npc 缺少必填字段: " + k)
                ok = false

    # triggers 必填 + correct ∈ candidates
    var has_miss := false
    if dict.has("triggers"):
        var t: Dictionary = dict["triggers"]
        for k in REQUIRED_TRIGGERS:
            if not t.has(k):
                errors.append("triggers 缺少必填字段: " + k)
                ok = false
        if t.has("candidates") and t.has("correct"):
            var cands: Array = t["candidates"]
            var correct: String = t["correct"]
            if not cands.has(correct):
                errors.append("triggers.correct 不在 candidates 中: " + correct)
                ok = false
        has_miss = t.has("miss")

    # choices 含 ≥1 skilled
    if dict.has("choices"):
        var ch: Array = dict["choices"]
        var skilled := 0
        for c in ch:
            if c is Dictionary and c.get("type", "") == "skilled":
                skilled += 1
        if skilled < 1:
            errors.append("choices 需至少包含 1 个 type==\"skilled\"")
            ok = false

    # review 必填（case 可选）
    var has_review_case := false
    if dict.has("review"):
        var rv: Dictionary = dict["review"]
        for k in REQUIRED_REVIEW:
            if not rv.has(k):
                errors.append("review 缺少必填字段: " + k)
                ok = false
        has_review_case = rv.has("case")   # 缺失不影响 ok（A7 降级）
    else:
        has_review_case = false

    # triggers.miss 同构校验（G2 方案A / 约束4）
    var miss_isomorphic := true
    if has_miss:
        var miss_dict: Dictionary = dict["triggers"]["miss"]
        for k in CONSEQUENCE_SHAPE:
            if not miss_dict.has(k):
                errors.append("triggers.miss 缺少同构字段: " + k)
                miss_isomorphic = false
                ok = false
    # 若 miss 不存在，视为同构（无违例）

    return {
        "ok": ok,
        "has_review_case": has_review_case,
        "miss_isomorphic": miss_isomorphic,
        "errors": errors,
    }
