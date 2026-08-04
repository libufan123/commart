# ChoiceSystem.gd  (systems + S4 面板控制器)
# E3-S1 / S4 抉择（控制清单 D4）
#
# 双重职责（ChoicePanel.tscn ↔ ChoiceSystem.gd）：
#   1) 逻辑：choose(choice_id) 查表写入 chosen_choice_id / chosen_type（仅内存，RunState §6.2）。
#   2) 渲染：把 choices[].text 实例化为 ChoiceCard（样式不标 type 对错，P1 无主导策略）。
# 文本全部来自 choices[].text，无硬编码（ADR-001）。type 仅引擎透传，UI 不渲染类型名。

class_name ChoiceSystem
extends VBoxContainer

const ChoiceCardScene := preload("res://scenes/components/ChoiceCard.tscn")

signal chosen(choice_id: String, choice_type: String)

var chosen_choice_id: String = ""
var chosen_type: String = ""

var _scenario: Scenario = null

@onready var _choice_list: VBoxContainer = $ChoiceList


func load_scenario(scenario: Scenario) -> void:
	_scenario = scenario
	chosen_choice_id = ""
	chosen_type = ""
	_rebuild()


func _rebuild() -> void:
	if _choice_list == null or _scenario == null:
		return
	for child in _choice_list.get_children():
		child.queue_free()
	for choice in _scenario.choices:
		var c := choice as Choice
		if c == null:
			continue
		var card := ChoiceCardScene.instantiate() as Button
		if card == null:
			continue
		card.text = "⬡  " + c.text
		card.pressed.connect(_on_card_pressed.bind(c.id))
		_choice_list.add_child(card)


func _on_card_pressed(choice_id: String) -> void:
	choose(choice_id)


# 捕获所选选项，写入内存态 chosen_choice_id / chosen_type；返回是否成功（id 须存在）。
func choose(choice_id: String) -> bool:
	if _scenario == null:
		return false
	for choice in _scenario.choices:
		var c := choice as Choice
		if c != null and c.id == choice_id:
			chosen_choice_id = c.id
			chosen_type = c.type
			chosen.emit(c.id, c.type)
			return true
	return false
