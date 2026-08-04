# test_trigger_system.gd  (GUT)
# E2/E3：S3 硬闸门（D2）+ 识别错 miss 演出（方案A / G2 / E1）+ miss 缺省回退
# 对齐 test-scaffolding.md §2.2（A/B/C）。
extends GutTest

# 构造「无 miss」场景：取 s01 数据但移除 triggers.miss（E1 降级路径）。
func _scenario_without_miss() -> Scenario:
	var d: Dictionary = DataLoader.load_dict("res://data/scenarios/s01_scene_01.json")
	if d.has("triggers"):
		(d["triggers"] as Dictionary).erase("miss")
	return Scenario.new(d)


# D2 硬闸门：S3 未完成前不可抉择；识别正确后解锁。
func test_cannot_enter_choice_before_identification():
	var ps := PlaySession.new()
	ps.load_scenario(DataLoader.get_scenario("s01_scene_01"))
	assert_false(ps.can_choose(), "S3 未完成前 ChoicePanel 不可操作")
	ps.submit_trigger("我正想批评 / 对方在防御")   # == correct
	assert_true(ps.can_choose(), "识别正确后解锁抉择")


# D3 / E1 方案A：识别错 → 优先演出 triggers.miss。
func test_wrong_identification_plays_miss():
	var ps := PlaySession.new()
	ps.load_scenario(DataLoader.get_scenario("s01_scene_01"))
	ps.submit_trigger("纯事务沟通")            # != correct
	var cons := ps.resolve_consequence()
	var miss = DataLoader.get_scenario("s01_scene_01").triggers.miss
	assert_eq(cons.npc_reaction, miss.npc_reaction, "识别错应优先演出 triggers.miss")


# E1 降级：triggers.miss 缺省 → 回退所选 choice 的 consequence（此处无 chosen，回落首个 choice），不崩溃。
func test_missing_miss_falls_back_no_crash():
	var scen := _scenario_without_miss()    # triggers 无 miss 字段
	var ps := PlaySession.new()
	ps.load_scenario(scen)
	ps.submit_trigger("错误标签")
	var cons = ps.resolve_consequence()      # 回退（无 chosen → 首个 choice 后果）
	assert_not_null(cons, "miss 缺省应回退，不崩溃")
