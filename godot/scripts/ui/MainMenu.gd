# MainMenu.gd  (ui / E4-S5 主菜单入口)
#
# 标题 +〔开始学习〕→ SkillMap；〔继续〕若存在存档则进上次进度（Lean 简化为直接进入 SkillMap）。
# DataLoader 就绪前入口不可用（防空数据进入）：本工程 autoload 在 _ready 前已完成数据加载，
# 故直接可用；〔继续〕按 SaveManager.has_save() 启用。

extends Control

const SkillMapScene := preload("res://scenes/play/SkillMap.tscn")


func _ready() -> void:
	var rm := get_node_or_null("RootMargin") as MarginContainer
	if rm != null:
		UIAdapter.apply_safe_area(rm)   # 安全区单点接入（E0-S3）

	var start := get_node_or_null("RootMargin/VBox/StartButton") as Button
	var cont := get_node_or_null("RootMargin/VBox/ContinueButton") as Button
	if cont != null:
		cont.disabled = not SaveManager.has_save()   # 无存档时禁用「继续」
		cont.pressed.connect(_enter_map)
	if start != null:
		start.pressed.connect(_enter_map)


# 进入技能地图（开始学习 / 继续 在 Lean 下均进地图）。
func _enter_map() -> void:
	var sm := SkillMapScene.instantiate() as Control
	if sm == null:
		return
	add_child(sm)
	# 仅隐藏菜单 UI（RootMargin）；SkillMap 为其兄弟节点，仍可见（可见性沿父子链继承，
	# 故不可隐藏 self，否则会连子节点 SkillMap 一起隐藏）。
	var rm := get_node_or_null("RootMargin")
	if rm != null:
		rm.visible = false
