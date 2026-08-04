# test_consequence_engine.gd  (GUT)
# E3：静态查表 + forceBoundary（D6 / E2 / 边界强制）+ 关系信号仅渲染（E2）
# 对齐 test-scaffolding.md §2.3（A/B）；持久化断言留 Sprint 3 SaveManager。
extends GutTest

# E2 / D6：forceBoundary:true 时，即便选 skilled 也确定性路由到 boundary 后果。
func test_force_boundary_routes_to_boundary():
	var scen: Scenario = DataLoader.get_scenario("s04_scene_01")   # forceBoundary:true
	var eng := ConsequenceEngine.new()
	var cons := eng.resolve(scen, "c1", true)   # 选 skilled（c1）
	var boundary := _find_boundary(scen)
	assert_not_null(boundary, "s04 应含 boundary 选项")
	assert_eq(cons.npc_reaction, boundary.consequence.npc_reaction,
			"forceBoundary 应确定性路由到 boundary")


# E2：关系信号仅暴露供渲染；断言可见（≠0）。持久化断言留 Sprint 3 SaveManager。
func test_relationship_signal_exposed_for_render():
	var ps := PlaySession.new()
	ps.load_scenario(DataLoader.get_scenario("s01_scene_01"))
	ps.submit_trigger("我正想批评 / 对方在防御")   # correct
	ps.choose("c1")                          # trap，relationshipSignal = -1
	assert_ne(ps.current_relationship_signal(), 0, "ConsequenceStage 渲染可见信号")


func _find_boundary(scen: Scenario) -> Choice:
	for c in scen.choices:
		var ch := c as Choice
		if ch != null and ch.type == "boundary":
			return ch
	return null
