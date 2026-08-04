# PlaySession.gd  (systems / 编排器，挂在 PlaySession.tscn 根 Node)
# E2/E3/E4-S1 状态机编排（控制清单 D2/D3/D4/D5/D6/D7 / A7 降级）
#
# 顺序状态机：S2 场景卡 → S3 识别 → (正确) S4 抉择 → S5 后果 → S6 复盘 → (再练/下一)
#            (错误) 跳过 S4 直接播放 triggers.miss（S5）。
# 一次一屏互斥显示（engin-architecture §3）。
#
# 内存态（沿用 §6.2 RunState 内容；本 Sprint RunState Autoload 未注册，状态本地持有，
# 不跨场景累积，更不出盘）：
#   selected_trigger / trigger_correct / chosen_choice_id / chosen_type
#   _resolved（当次 consequence，含 relationship_signal，仅当次渲染用，绝不写盘 / 不累积）
#
# 测试 API 对齐 test-scaffolding.md §2.2/§2.3：
#   load_scenario / submit_trigger / can_choose / choose /
#   resolve_consequence / current_relationship_signal / replay_current / next_scenario

class_name PlaySession
extends Node

const ScenarioCardScene := preload("res://scenes/play/ScenarioCard.tscn")
const TriggerPanelScene := preload("res://scenes/play/TriggerPanel.tscn")
const ChoicePanelScene := preload("res://scenes/play/ChoicePanel.tscn")
const ConsequenceStageScene := preload("res://scenes/play/ConsequenceStage.tscn")
const ReviewPanelScene := preload("res://scenes/play/ReviewPanel.tscn")

enum Stage { S2_SCENARIO, S3_TRIGGER, S4_CHOICE, S5_CONSEQUENCE, S6_REVIEW }

signal all_done
signal stage_changed(stage: int)

# 切片有序场景 id（取自 skills_index；缺失则回退文档化顺序。仅 id，非场景文案）
const FALLBACK_ORDER := PackedStringArray([
	"s01_scene_01", "s01_scene_02", "s03_scene_01", "s03_scene_02", "s04_scene_01"
])

var _stage: int = Stage.S2_SCENARIO
var _scenario: Scenario = null
var _ordered_ids: PackedStringArray = PackedStringArray()
var _cursor: int = -1

# Sprint 3（E4-S2 导航接线）：外部（SkillMap）实例化并显式 load_scenario 时置 true，
# 使 _ready 不自动 load 首个场景，避免与导航冲突。PlaySession 作为 main_scene 直接运行时为 false。
var external_boot: bool = false

var _trigger_system: TriggerSystem = null
var _choice_system: ChoiceSystem = null
var _consequence_engine: ConsequenceEngine = null
var _resolved: Consequence = null

# Sprint3 P1 修复（QA §6 P1）：已玩结果字典。
# 键 = 场景 id 字符串；值 = 该场景最后一次 chosen_type 字符串（"skilled"/"trap"/"boundary"/""）。
# "" 表示识别错或未抉择。每次结算（进入 S5 前）记录，供导航层 _on_session_done 经
# get_played_results() 全量回传，避免多场景单局仅记入口场景导致后续进度全部丢失。
# replay 用同 key 覆盖、不膨胀；load 不清除（跨场景累积）。
var _played: Dictionary = {}

var _stage_root: Control = null
var _scenario_card: MarginContainer = null
var _trigger_panel: TriggerSystem = null
var _choice_panel: ChoiceSystem = null
var _consequence_stage: VBoxContainer = null
var _review_panel: VBoxContainer = null


func _ready() -> void:
	var root_margin := get_node_or_null("RootMargin") as MarginContainer
	if root_margin != null:
		UIAdapter.apply_safe_area(root_margin)   # E0-S3：安全区单点接入
	_ordered_ids = _build_order()
	_ensure_panels()
	if _scenario == null and not external_boot:
		var first_id := _ordered_ids[0] if not _ordered_ids.is_empty() else ""
		if first_id != "":
			load_scenario(DataLoader.get_scenario(first_id))


# ---- 有序场景列表（来自 skills_index，扁平化；缺失则回退）----
func _build_order() -> PackedStringArray:
	var idx: Dictionary = DataLoader.get_skills_index()
	if idx.has("skills"):
		var out: PackedStringArray = PackedStringArray()
		for skill in idx["skills"]:
			if skill is Dictionary and skill.has("scenes"):
				for sid in skill["scenes"]:
					out.append(String(sid))
		if out.size() > 0:
			return out
	return FALLBACK_ORDER


# ---- 懒实例化五个面板（不依赖 _ready；测试中 RootMargin 缺失时挂到 self）----
func _ensure_panels() -> void:
	if _stage_root != null:
		return
	var parent: Node = get_node_or_null("RootMargin")
	if parent == null:
		parent = self

	_stage_root = Control.new()
	_stage_root.name = "StageRoot"
	_stage_root.anchors_preset = 15
	_stage_root.anchor_right = 1.0
	_stage_root.anchor_bottom = 1.0
	_stage_root.grow_horizontal = 2
	_stage_root.grow_vertical = 2
	parent.add_child(_stage_root)

	_scenario_card = ScenarioCardScene.instantiate() as MarginContainer
	_trigger_panel = TriggerPanelScene.instantiate() as TriggerSystem
	_choice_panel = ChoicePanelScene.instantiate() as ChoiceSystem
	_consequence_stage = ConsequenceStageScene.instantiate() as VBoxContainer
	_review_panel = ReviewPanelScene.instantiate() as VBoxContainer

	for p in [_scenario_card, _trigger_panel, _choice_panel, _consequence_stage, _review_panel]:
		if p != null:
			p.anchors_preset = 15
			p.anchor_right = 1.0
			p.anchor_bottom = 1.0
			p.grow_horizontal = 2
			p.grow_vertical = 2
			_stage_root.add_child(p)
			p.visible = false

	_consequence_engine = ConsequenceEngine.new()

	if _trigger_panel != null:
		_trigger_panel.submitted.connect(_on_trigger_submitted)
	if _choice_panel != null:
		_choice_panel.chosen.connect(_on_choice_chosen)
	_bind_scenario_card()
	_bind_consequence_stage()
	_bind_review_panel()


func _bind_scenario_card() -> void:
	if _scenario_card == null:
		return
	var btn := _scenario_card.get_node_or_null("ContinueButton") as Button
	if btn != null:
		btn.pressed.connect(_on_scenario_continue)


func _bind_consequence_stage() -> void:
	if _consequence_stage == null:
		return
	var replay := _consequence_stage.get_node_or_null("ReplayButton") as Button
	var insight := _consequence_stage.get_node_or_null("InsightButton") as Button
	if replay != null:
		replay.pressed.connect(replay_current)
	if insight != null:
		insight.pressed.connect(_show_review)


func _bind_review_panel() -> void:
	if _review_panel == null:
		return
	var replay := _review_panel.get_node_or_null("ReplayButton") as Button
	var nxt := _review_panel.get_node_or_null("NextButton") as Button
	var mp := _review_panel.get_node_or_null("MapButton") as Button
	if replay != null:
		replay.pressed.connect(replay_current)
	if nxt != null:
		nxt.pressed.connect(next_scenario)
	if mp != null:
		mp.pressed.connect(_on_return_map)


# ================= 测试 / 外部 API =================

func load_scenario(scenario: Scenario) -> void:
	if scenario == null:
		return
	_ensure_panels()
	_scenario = scenario
	_ordered_ids = _build_order()
	_cursor = _ordered_ids.find(scenario.id)
	_resolved = null
	if _trigger_panel != null:
		_trigger_panel.load_scenario(scenario)
	if _choice_panel != null:
		_choice_panel.load_scenario(scenario)
	if _scenario_card != null:
		ScenarioEngine.render_card(_scenario_card, scenario)   # 复用 Sprint 1 渲染逻辑
	_enter_stage(Stage.S2_SCENARIO)


# S3 提交识别：委托 TriggerSystem 判定；UI 流转由 _on_trigger_submitted 处理。
func submit_trigger(label: String) -> void:
	if _trigger_panel != null:
		_trigger_panel.submit(label)


# 硬闸门（D2/D3）：仅识别正确后才允许抉择；未完成或识别错均返回 false。
func can_choose() -> bool:
	if _trigger_panel != null:
		return _trigger_panel.trigger_correct
	return false


# 返回最近一次所选选项的 type（"skilled"/"trap"/"boundary"），供导航层记录掌握度。
func get_last_chosen_type() -> String:
	if _choice_panel != null:
		return _choice_panel.chosen_type
	return ""


# P1 修复：返回本局已玩结果副本（键=场景 id，值=最后一次 chosen_type；""=识别错/未抉择）。
# 导航层 _on_session_done 遍历此字典逐场景 mark_visited + record_scenario，
# 保证多场景单局不丢进度、且不把末屏 skilled 误归因到入口场景。
func get_played_results() -> Dictionary:
	return _played.duplicate()


# S4 捕获选择：仅当已正确识别才接受；选中后自动结算当次后果。
func choose(choice_id: String) -> bool:
	if not can_choose() or _choice_panel == null:
		return false
	var ok := _choice_panel.choose(choice_id)
	if ok:
		resolve_consequence()
	return ok


# 结算当次后果：返回 Consequence 对象（供测试读取 npc_reaction 等字段）。
func resolve_consequence() -> Consequence:
	if _scenario == null:
		return null
	var chosen_id := ""
	var trigger_correct := false
	if _choice_panel != null:
		chosen_id = _choice_panel.chosen_choice_id
	if _trigger_panel != null:
		trigger_correct = _trigger_panel.trigger_correct
	_resolved = _consequence_engine.resolve(_scenario, chosen_id, trigger_correct)
	_render_consequence()
	return _resolved


# 仅暴露当次 relationship_signal 供 ConsequenceStage 渲染（-1/0/+1）；
# 不写入任何持久字段（E2/E4 红项：绝不写盘 / 不跨场景累积）。
func current_relationship_signal() -> int:
	if _resolved != null:
		return _resolved.relationship_signal
	return 0


func replay_current() -> void:
	if _scenario != null:
		load_scenario(_scenario)


func next_scenario() -> void:
	if _ordered_ids.is_empty():
		all_done.emit()
		return
	var next_idx := _cursor + 1
	if next_idx >= 0 and next_idx < _ordered_ids.size():
		var next_scen := DataLoader.get_scenario(_ordered_ids[next_idx])
		if next_scen != null:
			load_scenario(next_scen)
			return
	all_done.emit()


# ================= 内部流转 =================

func _enter_stage(stage: int) -> void:
	_stage = stage
	if _stage_root == null:
		stage_changed.emit(stage)
		return
	var visible_map := {
		Stage.S2_SCENARIO: _scenario_card,
		Stage.S3_TRIGGER: _trigger_panel,
		Stage.S4_CHOICE: _choice_panel,
		Stage.S5_CONSEQUENCE: _consequence_stage,
		Stage.S6_REVIEW: _review_panel,
	}
	var target = visible_map.get(stage, null)
	for node in [_scenario_card, _trigger_panel, _choice_panel, _consequence_stage, _review_panel]:
		if node != null:
			node.visible = (node == target)
	stage_changed.emit(stage)


func _on_trigger_submitted(_label: String, correct: bool) -> void:
	if correct:
		_enter_stage(Stage.S4_CHOICE)
	else:
		# 识别错：跳过 S4，直接 S5 播放 triggers.miss（miss 缺省则降级，不崩溃）
		resolve_consequence()


# @警示 已修复 P2-1（QA §7-6 / Sprint2 CONCERNS）：resolve 仅由 choose() 内显式调用一次，
# 本 handler 不再二次解析 —— 保证幂等只 resolve 一次（测试路径 / UI 路径行为一致）。
# chosen 信号仍连接（保留未来埋点扩展位），但不再承担结算职责。
func _on_choice_chosen(_choice_id: String, _choice_type: String) -> void:
	pass   # 单路径：结算统一在 choose() 内的 resolve_consequence() 完成


func _on_scenario_continue() -> void:
	_enter_stage(Stage.S3_TRIGGER)


func _show_review() -> void:
	_render_review()
	_enter_stage(Stage.S6_REVIEW)


func _on_return_map() -> void:
	all_done.emit()


# ---- S5 后果渲染（数据驱动，无硬编码文案）----
func _render_consequence() -> void:
	# P1 修复：进入 S5 前记录本场景已玩结果。识别错走 miss 时 _choice_panel.chosen_type 为 ""
	# （choose 未调用、load 时已重置），记为 "" → SkillMap 判 skilled=false，但仍记 visited。
	if _scenario != null:
		_played[_scenario.id] = (_choice_panel.chosen_type if _choice_panel != null else "")
	if _consequence_stage == null or _resolved == null:
		return
	var npc := _consequence_stage.get_node_or_null("NpcReactionLabel") as Label
	var judge := _consequence_stage.get_node_or_null("JudgementLabel") as Label
	if npc != null:
		npc.text = _resolved.npc_reaction
	if judge != null:
		judge.text = _resolved.judgement
	_apply_relationship_glyph(_resolved.relationship_signal)
	_enter_stage(Stage.S5_CONSEQUENCE)


# 关系信号双编码：符号 + 文字标签（不靠颜色，UX §5 可访问性 C）。仅供展示。
func _apply_relationship_glyph(sig: int) -> void:
	if _consequence_stage == null:
		return
	var glyph := _consequence_stage.get_node_or_null("RelationshipGlyph")
	if glyph == null:
		return
	var sym := glyph.get_node_or_null("SymbolLabel") as Label
	var txt := glyph.get_node_or_null("TextLabel") as Label
	var symbol := "0"
	var label := "关系平稳"
	if sig > 0:
		symbol = "+"
		label = "关系升温"
	elif sig < 0:
		symbol = "–"   # en dash
		label = "出现摩擦"
	if sym != null:
		sym.text = symbol
	if txt != null:
		txt.text = label


# ---- S6 复盘渲染（E4-S1 只读渲染；review.* 全部来自数据，无任何硬编码复盘文案）----
func _render_review() -> void:
	if _review_panel == null or _scenario == null or _scenario.review == null:
		return
	var skill := _review_panel.get_node_or_null("SkillLabel") as Label
	var mech := _review_panel.get_node_or_null("MechanismLabel") as Label
	var mig := _review_panel.get_node_or_null("MigrationLabel") as Label
	var case_section := _review_panel.get_node_or_null("CaseSection") as Control
	var case_lbl := _review_panel.get_node_or_null("CaseLabel") as Label
	if skill != null:
		skill.text = _scenario.skill          # 来自数据（skill id）
	if mech != null:
		mech.text = _scenario.review.mechanism
	if mig != null:
		mig.text = _scenario.review.migration
	if case_lbl != null:
		case_lbl.text = _scenario.review.case
	# A7 / E5 降级：review.case 缺失 → 跳过案例段，不崩溃
	if case_section != null:
		case_section.visible = not _scenario.review.case.is_empty()
