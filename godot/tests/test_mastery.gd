# test_mastery.gd  (GUT)
# E4-S3 轻量掌握度：0–3 档钳制、replay 递增、skilled 保底、跨场景不串扰，
# 并与 SaveManager 集成断言存档干净（仅白名单键）。

extends GutTest

func before_each() -> void:
	_reset_save()


func _reset_save() -> void:
	var da := DirAccess.open("user://")
	if da != null and da.file_exists("save_v1.json"):
		da.remove("save_v1.json")
	SaveManager.load_save()


func test_mastery_zero_initially():
	var ms := MasterySystem.new()
	assert_eq(ms.get_mastery("s01-shake-the-hive"), 0, "初始掌握度 0")


# 每场景 replay 累加（上限 3）。
func test_replay_increments_toward_cap():
	var ms := MasterySystem.new()
	ms.record_scenario("s01_scene_01", false)
	assert_eq(ms.get_mastery("s01-shake-the-hive"), 1, "玩 1 场景 → 1")
	ms.record_scenario("s01_scene_02", false)
	assert_eq(ms.get_mastery("s01-shake-the-hive"), 2, "玩 2 场景 → 2")
	ms.record_scenario("s01_scene_01", false)
	ms.record_scenario("s01_scene_01", false)
	assert_eq(ms.get_mastery("s01-shake-the-hive"), 3, "超量 replay 钳制 3")


# 至少一次选 skilled 计 1 档。
func test_skilled_bump_to_at_least_one():
	var ms := MasterySystem.new()
	ms.record_scenario("s01_scene_01", true)
	assert_eq(ms.get_mastery("s01-shake-the-hive"), 1, "至少一次 skilled 计 1 档")


# 跨技能不串扰。
func test_no_crosstalk_across_skills():
	var ms := MasterySystem.new()
	ms.record_scenario("s01_scene_01", true)
	assert_eq(ms.get_mastery("s01-shake-the-hive"), 1, "s01 应记录")
	assert_eq(ms.get_mastery("s03-sense-of-importance"), 0, "s03 不受 s01 串扰")
	assert_eq(ms.get_mastery("s04-genuine-praise-standard"), 0, "s04 不受 s01 串扰")


# mastery_for_skill 纯函数：空场景列表返回 0。
func test_mastery_for_skill_empty():
	var ms := MasterySystem.new()
	assert_eq(ms.mastery_for_skill("s01-shake-the-hive", []), 0, "空场景列表 → 0")


# 集成：记录后存档仅含白名单键，无 relationshipSignal；visited 记录场景。
func test_save_stays_whitelist_clean():
	var ms := MasterySystem.new()
	ms.record_scenario("s01_scene_01", true)
	var d := SaveManager.to_dict()
	for key in d.keys():
		assert_true(SaveManager.ALLOWED_KEYS.has(key),
				"存档键 '%s' 须在白名单" % key)
	assert_false(d.has("relationshipSignal"), "存档禁止 relationshipSignal")
	assert_true(d["visited"].has("s01_scene_01"), "visited 应记录场景")
	assert_eq(d["mastery"].get("s01-shake-the-hive", 0), 1, "mastery 应记录技能级别")
