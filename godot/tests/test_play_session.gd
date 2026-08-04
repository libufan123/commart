# test_play_session.gd  (GUT)
# E6 六屏状态机烟雾（QA §7-4）+ D8 安全失败（QA §7-3）+ A7 运行时降级（QA §7-5）
# 对齐 test-scaffolding.md §1.3 / Sprint2 QA §7。
# 读取 choice id 一律取自 get_scenario 的真实数据（不用占位 c1/c2/c3）：
#   skilled 选型取 type=="skilled"；trigger correct label 取 triggers.correct；trap 取 type=="trap"。

extends GutTest

var _done := false


func before_each() -> void:
	_done = false


func _mark_done() -> void:
	_done = true


# 取 type==skilled 的 choice 真实 id。
func _skilled_id(scen: Scenario) -> String:
	for c in scen.choices:
		if c.type == "skilled":
			return c.id
	return ""


# 取 type==trap 的 choice 真实 id。
func _trap_id(scen: Scenario) -> String:
	for c in scen.choices:
		if c.type == "trap":
			return c.id
	return ""


# QA §7-4：六屏状态机烟雾 S2→S4→S5→S6→再练→下一→all_done。
func test_six_stage_state_machine_smoke():
	var scen: Scenario = DataLoader.get_scenario("s01_scene_01")
	assert_not_null(scen, "s01_scene_01 应已加载")

	var ps := PlaySession.new()
	ps.load_scenario(scen)
	assert_eq(ps._stage, PlaySession.Stage.S2_SCENARIO, "初始应在 S2 场景卡")

	var correct_label: String = scen.triggers.correct
	ps.submit_trigger(correct_label)
	assert_eq(ps._stage, PlaySession.Stage.S4_CHOICE, "识别正确应进 S4 抉择")
	assert_true(ps.can_choose(), "识别正确后可抉择")

	var sid := _skilled_id(scen)
	ps.choose(sid)
	assert_eq(ps._stage, PlaySession.Stage.S5_CONSEQUENCE, "抉择后应进 S5 后果")
	assert_not_null(ps._resolved, "S5 应有当次 consequence（_resolved 非空）")

	ps._show_review()
	assert_eq(ps._stage, PlaySession.Stage.S6_REVIEW, "应进 S6 复盘")

	ps.replay_current()
	assert_eq(ps._stage, PlaySession.Stage.S2_SCENARIO, "再练应重置回 S2")

	ps.next_scenario()
	assert_eq(ps._scenario.id, "s01_scene_02", "下一场景应切到 s01_scene_02")

	# 遍历剩余场景，末尾应触发 all_done。
	ps.all_done.connect(_mark_done)
	var safety := 0
	while not _done and safety < 12:
		ps.next_scenario()
		safety += 1
	assert_true(_done, "遍历完所有场景应触发 all_done")


# QA §7-3（D8 / E3-S5）：连续两次选 trap —— 后果照常、复盘不封锁、replay 无冷却（幂等安全失败）。
func test_double_trap_safe_failure():
	var scen: Scenario = DataLoader.get_scenario("s01_scene_01")
	var ps := PlaySession.new()
	ps.load_scenario(scen)
	ps.submit_trigger(scen.triggers.correct)

	var ok1 := ps.choose(_trap_id(scen))
	var cons1 = ps._resolved
	assert_true(ok1, "第一次选 trap 应成功")
	assert_not_null(cons1, "第一次后果非空")

	# 复盘照常展开（不封锁）
	ps._show_review()
	assert_eq(ps._stage, PlaySession.Stage.S6_REVIEW, "复盘应正常展开，不封锁")

	# 再练（无冷却），再次选同一 trap
	ps.replay_current()
	assert_eq(ps._stage, PlaySession.Stage.S2_SCENARIO, "再练重置回 S2（无冷却）")
	ps.submit_trigger(scen.triggers.correct)
	var ok2 := ps.choose(_trap_id(scen))
	var cons2 = ps._resolved
	assert_true(ok2, "第二次选 trap 应成功（无封锁/无冷却）")
	assert_not_null(cons2, "第二次后果非空")
	assert_eq(cons1.npc_reaction, cons2.npc_reaction,
			"连续两次选 trap 后果一致（幂等安全失败，无异常）")


# QA §7-5（A7）：review.case 缺失 → CaseSection.visible == false（运行时降级，不崩溃）。
func test_review_case_missing_hides_section():
	var d: Dictionary = DataLoader.load_dict("res://data/scenarios/s01_scene_01.json")
	if d.has("review") and d["review"] is Dictionary:
		(d["review"] as Dictionary)["case"] = ""   # 构造缺 case 的 scenario
	var scen := Scenario.new(d)

	var ps := PlaySession.new()
	ps.load_scenario(scen)
	ps._show_review()

	var case_section = ps.get_node_or_null("StageRoot/ReviewPanel/CaseSection")
	assert_not_null(case_section, "CaseSection 节点应存在")
	assert_false(case_section.visible, "review.case 缺失时 CaseSection 应隐藏（A7 降级）")


# Phase 5 Sprint 3 P1 根因级测试（QA §6 P1）：单次单局跨多场景时，已玩结果含每个场景 id，
# 且 skilled/trap 按各自场景正确归因（非统一误归因入口 / 末屏）。
# 锁定 PlaySession.get_played_results() 的累积契约（SkillMap 遍历逻辑为纯赋值、低风险，
# 其正确性由本根因锁 + 静态审阅保证；导航层真链路待用户侧 GUT/真机跑证）。
func test_multi_scene_progress_recorded():
	var scen1: Scenario = DataLoader.get_scenario("s01_scene_01")
	var scen2: Scenario = DataLoader.get_scenario("s01_scene_02")
	assert_not_null(scen1, "s01_scene_01 应已加载")
	assert_not_null(scen2, "s01_scene_02 应已加载")

	var ps := PlaySession.new()
	# 场景 1：识别正确 + 选 skilled。
	ps.load_scenario(scen1)
	ps.submit_trigger(scen1.triggers.correct)
	assert_true(ps.can_choose(), "s01_scene_01 识别正确后可抉择")
	ps.choose(_skilled_id(scen1))

	# 切到场景 2（不触发 all_done，仅推进）。
	ps.next_scenario()
	assert_eq(ps._scenario.id, "s01_scene_02", "next_scenario 应切到 s01_scene_02")

	# 场景 2：识别正确 + 选 trap（证明非统一 skilled / 非误归因入口）。
	ps.submit_trigger(scen2.triggers.correct)
	assert_true(ps.can_choose(), "s01_scene_02 识别正确后可抉择")
	ps.choose(_trap_id(scen2))

	# 根因断言：已玩结果含两个场景 id，且各自归因正确。
	var results: Dictionary = ps.get_played_results()
	assert_true(results.has("s01_scene_01"), "已玩结果应含 s01_scene_01（不丢）")
	assert_true(results.has("s01_scene_02"), "已玩结果应含 s01_scene_02（不丢）")
	assert_eq(results.get("s01_scene_01"), "skilled", "s01_scene_01 应归因 skilled")
	assert_eq(results.get("s01_scene_02"), "trap", "s01_scene_02 应归因其自身选择的 trap（非入口/末屏误归因）")
