# ConsequenceEngine.gd  (systems)
# E3-S2 / S5 后果引擎（控制清单 D5 / ADR-004 / E3-S3 forceBoundary）
#
# resolve(scenario, chosen_choice_id, trigger_correct) -> Consequence
#   - 纯静态查表，无分支 / 无随机（ADR-004 / 约束5）。
#   - 方案A（E1/G2 已决）：trigger_correct == false 且 triggers.miss 存在 →
#       优先返回 miss（同构 consequence），让后果自己说话、玩家自行发现「没看清情况」。
#   - miss 缺省 → 回退所选 choice 的 consequence；若仍未选（识别错且跳过 S4）→
#       返回首个 choice 的 consequence，保证非 null、不崩溃（E1 降级）。
#   - E2 边界强制（D6）：scenario.forceBoundary == true 时，无论所选 type，
#       确定性路由到 boundary 选项的 consequence（唯一引擎级确定性规则）。
# 暴露 relationship_signal 仅供渲染（从返回 Consequence 取 -1/0/+1）；本类不写任何存档。

class_name ConsequenceEngine
extends RefCounted


# 返回当次所选/所路由的 consequence（或降级后的兜底 consequence）。可能为 null 仅当
# 场景无任何 choice（数据层已由 Validator 拦截，正常不会发生）。
func resolve(scenario: Scenario, chosen_choice_id: String, trigger_correct: bool) -> Consequence:
	if scenario == null:
		return null

	# 方案A：识别错优先 miss（清晰、可感知的错位后果，不提示对错）
	if not trigger_correct and scenario.triggers != null and scenario.triggers.miss != null:
		return scenario.triggers.miss

	# E2 边界强制：forceBoundary 确定性路由到 boundary（无论所选 type）
	if scenario.force_boundary:
		var b := _find_by_type(scenario, "boundary")
		if b != null:
			return b.consequence

	# 正常路径：取所选 choice 的 consequence
	if chosen_choice_id != "":
		var c := _find_by_id(scenario, chosen_choice_id)
		if c != null:
			return c.consequence

	# 降级兜底：无 miss / 未选 → 返回首个 choice 的 consequence（不崩溃、非 null）
	if not scenario.choices.is_empty():
		var first := scenario.choices[0] as Choice
		if first != null and first.consequence != null:
			return first.consequence
	return null


func _find_by_id(scenario: Scenario, choice_id: String) -> Choice:
	for choice in scenario.choices:
		var c := choice as Choice
		if c != null and c.id == choice_id:
			return c
	return null


func _find_by_type(scenario: Scenario, type: String) -> Choice:
	for choice in scenario.choices:
		var c := choice as Choice
		if c != null and c.type == type:
			return c
	return null
