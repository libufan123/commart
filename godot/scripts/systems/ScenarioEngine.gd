# ScenarioEngine.gd  (systems)
# E2-S1 场景卡渲染（控制清单 D1 / G3 npc.line）
#
# 渲染 context + npc.line（若存在，否则仅 context）+ impulse 气泡。
# 全部文本来自 Scenario 数据，无硬编码场景文案（ADR-001 / 约束1）。
#
# Sprint 1 接线说明：本脚本临时作为 PlaySession.tscn 的控制器，在 _ready 中
#   1) 对根 MarginContainer 施加安全区（E0-S3 接线，单一入口 UIAdapter）
#   2) 经 DataLoader 取数据并渲染场景卡（E2-S1）
# 待 E2-S3 实现六屏状态机时，本文件将拆分为纯渲染系统 + PlaySession 状态机，
# 此处 _ready 的演示逻辑随之移除。
class_name ScenarioEngine
extends Node

const SCENARIO_CARD := preload("res://scenes/play/ScenarioCard.tscn")
const DEMO_SCENARIO_ID := "s01_scene_01"


func _ready() -> void:
    var root_margin := get_node("RootMargin") as MarginContainer
    if root_margin != null:
        UIAdapter.apply_safe_area(root_margin)   # E0-S3：安全区单点接入

    var scenario := DataLoader.get_scenario(DEMO_SCENARIO_ID)
    if scenario == null:
        push_error("未找到场景 '%s'：请确认 res://data/scenarios/ 下存在该场景文件（Sprint 1 可用 tests/fixtures/s01_ok.json 复制为 s01_scene_01.json 代位）。" % DEMO_SCENARIO_ID)
        return
    _show_card(root_margin, scenario)


func _show_card(root_margin: MarginContainer, scenario: Scenario) -> void:
    var card := SCENARIO_CARD.instantiate() as MarginContainer
    if root_margin != null:
        root_margin.add_child(card)
    render(card, scenario)


# 静态渲染入口（Sprint 2 起 PlaySession 复用此函数，避免重复渲染逻辑）。
# 数据驱动渲染：文本全部来自 scenario，无硬编码。路径与 ScenarioCard.tscn 的节点名一致。
static func render_card(card: MarginContainer, scenario: Scenario) -> void:
    if card == null or scenario == null:
        return
    var context_label := card.get_node_or_null("VBox/ContextLabel") as Label
    var npc_label := card.get_node_or_null("VBox/NpcLineBubble") as Label
    var impulse_label := card.get_node_or_null("VBox/ImpulseBubble") as Label

    if context_label != null:
        context_label.text = scenario.context

    if npc_label != null:
        # G3：npc.line 存在才渲染对方末句气泡；缺失则仅 context + impulse
        if scenario.npc != null and not scenario.npc.line.is_empty():
            npc_label.visible = true
            npc_label.text = scenario.npc.line
        else:
            npc_label.visible = false

    if impulse_label != null:
        impulse_label.text = scenario.impulse


# Sprint 1 兼容入口（保留；PlaySession 现改用静态 render_card）。
func render(card: MarginContainer, scenario: Scenario) -> void:
    render_card(card, scenario)
