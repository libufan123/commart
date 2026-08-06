# scenario_types.gd  (core)
# 类型封装：Scenario / Npc / Trigger / Choice / Consequence / Review
#
# 设计约束3 / ADR-005 / 控制清单 E2 / E4：
#   relationshipSignal 仅作为 Consequence 的「只读展示字段」，本 Sprint 不实现 SaveManager，
#   但边界已留好——后续存档逻辑（SaveManager，E4）只允许写入 mastery/visited/settings，
#   永远不得读取本文件的 relationship_signal 字段，更不得将其写盘。
#
# 字段通过 _init(d) 从数据字典一次性构造；运行时只读取、不回填（ADR-001 数据驱动）。
# GDScript 无真 const 属性，此处以约定 + 注释保证「只读」：除 DataLoader 构造期外不赋值。

class_name Scenario extends RefCounted
var id: String = ""
var skill: String = ""
var title: String = ""
var context: String = ""
var npc: Npc = null
var impulse: String = ""
var schema_version: String = "1"
var triggers: Trigger = null
var choices: Array = []        # Array[Choice]
var review: Review = null
var force_boundary: bool = false

func _init(d: Dictionary) -> void:
    id = d.get("id", "")
    skill = d.get("skill", "")
    title = d.get("title", "")
    context = d.get("context", "")
    impulse = d.get("impulse", "")
    schema_version = str(d.get("schemaVersion", "1"))
    force_boundary = bool(d.get("forceBoundary", false))
    if d.has("npc"):
        npc = Npc.new(d["npc"])
    if d.has("triggers"):
        triggers = Trigger.new(d["triggers"])
    if d.has("choices"):
        for c in d["choices"]:
            choices.append(Choice.new(c))
    if d.has("review"):
        review = Review.new(d["review"])


class Npc extends RefCounted
    var name: String = ""
    var role: String = ""
    var mood: String = ""
    var line: String = ""   # 可选（G3）；空串表示场景卡仅用 context + impulse
    func _init(d: Dictionary) -> void:
        name = d.get("name", "")
        role = d.get("role", "")
        mood = d.get("mood", "")
        line = d.get("line", "")


# ★ E7-S4 修复：Consequence 必须定义在 Trigger / Choice 之前。
#   Godot 4 GDScript 按源文件从上到下注册内部类；Trigger(var miss: Consequence)
#   和 Choice(var consequence: Consequence) 都在类型注解里引用了 Consequence，
#   如果 Consequence 在它们后面，解析到类型注解时类还未注册 → 整个 class_name
#   Scenario 解析失败 → DataLoader autoload 无法创建 → 工程导不出。
class Consequence extends RefCounted
    # 只读展示字段。relationship_signal 永不写盘（ADR-005 / E2 / E4）。
    var npc_reaction: String = ""
    var relationship_signal: int = 0   # -1 / 0 / +1，仅 ConsequenceStage 渲染用
    var judgement: String = ""
    func _init(d: Dictionary) -> void:
        npc_reaction = d.get("npcReaction", "")
        relationship_signal = int(d.get("relationshipSignal", 0))
        judgement = d.get("judgement", "")


class Trigger extends RefCounted
    var candidates: Array = []   # Array[String]
    var correct: String = ""
    var miss: Consequence = null  # 可选（G2 方案A：识别错播放的错位后果）
    func _init(d: Dictionary) -> void:
        candidates = d.get("candidates", [])
        correct = d.get("correct", "")
        if d.has("miss"):
            miss = Consequence.new(d["miss"])


class Choice extends RefCounted
    var id: String = ""
    var type: String = ""        # skilled / trap / boundary
    var text: String = ""
    var consequence: Consequence = null
    func _init(d: Dictionary) -> void:
        id = d.get("id", "")
        type = d.get("type", "")
        text = d.get("text", "")
        if d.has("consequence"):
            consequence = Consequence.new(d["consequence"])


class Review extends RefCounted
    var mechanism: String = ""
    var case: String = ""        # 可选（A7 降级）：缺失则 has_review_case=false，不崩溃
    var migration: String = ""
    func _init(d: Dictionary) -> void:
        mechanism = d.get("mechanism", "")
        case = d.get("case", "")
        migration = d.get("migration", "")
