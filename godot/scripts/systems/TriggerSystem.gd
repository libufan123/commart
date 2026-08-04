# TriggerSystem.gd  (systems + S3 面板控制器)
# E2-S2 / S3 触发识别（控制清单 D2/D3 / P3 支柱）
#
# 双重职责（沿用 engin-architecture.md §3：TriggerPanel.tscn ↔ TriggerSystem.gd）：
#   1) 逻辑：接收 Scenario；submit(label) 判定 label == triggers.correct → trigger_correct；
#      由识别结果派生「解锁选项集」（本切片所有 choice 均解锁，但闸门语义保留：
#      未识别则 ChoicePanel 不可交互，见 PlaySession.can_choose / D2）。
#   2) 渲染：把 triggers.candidates 实例化为 TagButton（点选即提交，无独立确认按钮，UX §2.3）。
# 文本全部来自 scenario.triggers.candidates，无硬编码候选（ADR-001）。

class_name TriggerSystem
extends VBoxContainer

const TagButtonScene := preload("res://scenes/components/TagButton.tscn")

signal submitted(label: String, correct: bool)

var _scenario: Scenario = null
var selected: String = ""
var trigger_correct: bool = false

@onready var _tag_list: VBoxContainer = $TagList


# 载入场景：重置识别态并重建候选标签。
func load_scenario(scenario: Scenario) -> void:
	_scenario = scenario
	selected = ""
	trigger_correct = false
	_rebuild()


func _rebuild() -> void:
	if _tag_list == null or _scenario == null or _scenario.triggers == null:
		return
	for child in _tag_list.get_children():
		child.queue_free()
	for candidate in _scenario.triggers.candidates:
		var btn := TagButtonScene.instantiate() as Button
		if btn == null:
			continue
		btn.text = "◌  " + String(candidate)
		btn.pressed.connect(_on_tag_pressed.bind(String(candidate)))
		_tag_list.add_child(btn)


func _on_tag_pressed(label: String) -> void:
	submit(label)


# 判定：label == triggers.correct → trigger_correct。PlaySession 据此做 S3→S4 硬闸门。
func submit(label: String) -> void:
	selected = label
	trigger_correct = (_scenario != null and _scenario.triggers != null
			and label == _scenario.triggers.correct)
	submitted.emit(label, trigger_correct)


# 派生解锁选项集（本切片全部 choice 解锁；返回 id 列表供 ChoiceSystem 用）。
func unlocked_choice_ids() -> Array:
	var out: Array = []
	if _scenario == null:
		return out
	for choice in _scenario.choices:
		var c := choice as Choice
		if c != null:
			out.append(c.id)
	return out
