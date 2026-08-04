# SkillMap.gd  (ui / S8 导航 · E4-S2/S3)
#
# 读 DataLoader.get_skills_index() 渲染 s01/s03/s04 入口（title 来自数据，按 section/order 排序）；
# visited 标记从 SaveManager 读取（已玩过则小标记）；点入口 → 启动该技能首场景。
#
# 接线（导航 → PlaySession）：
#   - 实例化 PlaySession.tscn，置 external_boot=true（避免其 _ready 自动 load 首个场景与导航冲突），
#     连接 all_done → _on_session_done（标记 visited + 记录 mastery，返回地图）。
#   - 调用 load_scenario(DataLoader.get_scenario(first_id))（PlaySession 现有 API 已支持）。
#
# 所有 UI 文本：技能名取自 skills_index.title；菜单 chrome（标题/篇章）为导航外壳，非场景文案。
# 地图节点占位文字（如「技能入口」）通用，但技能名强制取自数据（硬约束）。
# 关系信号在三态之后仍仅渲染、绝不由此屏持久化（见 SaveManager 白名单）。

extends Control

const PlaySessionScene := preload("res://scenes/play/PlaySession.tscn")
const MasteryScript := preload("res://scripts/core/MasterySystem.gd")

@onready var _skill_list: VBoxContainer = $RootMargin/VBox/SkillList

var _mastery = null                  # MasterySystem 实例


func _ready() -> void:
	var rm := get_node_or_null("RootMargin") as MarginContainer
	if rm != null:
		UIAdapter.apply_safe_area(rm)   # 安全区单点接入（E0-S3）
	_mastery = MasteryScript.new()
	_build_entries()
	_refresh_markers()


# 按 section/order 排序渲染技能入口（title 来自数据）。
func _build_entries() -> void:
	if _skill_list == null:
		return
	for child in _skill_list.get_children():
		child.queue_free()
	var idx: Dictionary = DataLoader.get_skills_index()
	var skills: Array = []
	if idx.has("skills"):
		skills = idx["skills"].duplicate()
	skills.sort_custom(_sort_by_section_order)
	for skill in skills:
		if skill is Dictionary:
			_add_entry(skill)


func _sort_by_section_order(a, b) -> bool:
	var sa := int(a.get("section", 0)) if a is Dictionary else 0
	var sb := int(b.get("section", 0)) if b is Dictionary else 0
	if sa != sb:
		return sa < sb
	var oa := int(a.get("order", 0)) if a is Dictionary else 0
	var ob := int(b.get("order", 0)) if b is Dictionary else 0
	return oa < ob


func _add_entry(skill: Dictionary) -> void:
	if _skill_list == null:
		return
	var id: String = String(skill.get("id", ""))
	var title: String = String(skill.get("title", "技能入口"))   # 缺省占位文字，技能名仍须来自数据
	var entry := VBoxContainer.new()
	entry.name = "Entry_" + id
	var btn := Button.new()
	btn.text = title
	btn.custom_minimum_size = Vector2(0, 56)   # 触控 ≥48pt（控制清单 C5）
	btn.pressed.connect(_start_skill.bind(id))
	entry.add_child(btn)
	var marker := Label.new()
	marker.name = "Marker"
	marker.text = "（未玩过）"
	entry.add_child(marker)
	_skill_list.add_child(entry)


# 刷新每个入口的 visited / mastery 小标记（全部从 SaveManager 读取）。
func _refresh_markers() -> void:
	if _skill_list == null or _mastery == null:
		return
	var idx: Dictionary = DataLoader.get_skills_index()
	for skill in idx.get("skills", []):
		if not (skill is Dictionary):
			continue
		var id: String = String(skill.get("id", ""))
		var entry := _skill_list.get_node_or_null("Entry_" + id)
		if entry == null:
			continue
		var marker := entry.get_node_or_null("Marker") as Label
		if marker == null:
			continue
		var visited_any := false
		for sid in skill.get("scenes", []):
			if SaveManager.get_visited().has(String(sid)):
				visited_any = true
				break
		var mlvl: int = _mastery.get_mastery(id)
		var hex := _hex_string(mlvl)
		if visited_any:
			marker.text = "%s  已玩过 · 掌握 %d/3" % [hex, mlvl]
		else:
			marker.text = "%s  未玩过" % hex


# 用 ◈（点亮）/ ◷（未点亮）表示 0–3 掌握度（UX §4.2 六边形标记占位，Lean 文本化）。
func _hex_string(level: int) -> String:
	var s := ""
	for i in range(3):
		if i < level:
			s += "◈"
		else:
			s += "◷"
	return s


# 入口点击：启动该技能首场景。
func _start_skill(skill_id: String) -> void:
	var idx: Dictionary = DataLoader.get_skills_index()
	var first_id: String = ""
	for skill in idx.get("skills", []):
		if skill is Dictionary and String(skill.get("id", "")) == skill_id:
			var scenes: Array = skill.get("scenes", [])
			if not scenes.is_empty():
				first_id = String(scenes[0])
			break
	if first_id == "":
		return

	var ps := PlaySessionScene.instantiate() as PlaySession
	if ps == null:
		return
	ps.external_boot = true                 # 防止 _ready 自动 load 与导航冲突
	ps.all_done.connect(_on_session_done.bind(ps))
	add_child(ps)
	var rm := get_node_or_null("RootMargin")
	if rm != null:
		rm.visible = false                  # 隐藏菜单，显示 PlaySession
	var scen := DataLoader.get_scenario(first_id)
	if scen != null:
		ps.load_scenario(scen)


# PlaySession.all_done → 逐场景 mark_visited + record_scenario（遍历本局已玩结果），返回地图。
# P1 修复（QA §6 P1）：原逻辑仅以入口场景 id 记一次，导致多场景单局后续场景进度全部丢失、
# 且最后一屏 skilled 误归因到入口。现改为遍历 ps.get_played_results() 全量回传每个已玩场景。
func _on_session_done(ps: PlaySession) -> void:
	var results: Dictionary = {}
	if ps != null:
		results = ps.get_played_results()
	for sid in results.keys():
		var sid_str: String = String(sid)
		SaveManager.mark_visited(sid_str)
		var skilled := String(results[sid]) == "skilled"
		if _mastery != null:
			_mastery.record_scenario(sid_str, skilled)
	if ps != null and ps.is_inside_tree():
		ps.queue_free()
	var rm := get_node_or_null("RootMargin")
	if rm != null:
		rm.visible = true                   # 返回地图
	_refresh_markers()
