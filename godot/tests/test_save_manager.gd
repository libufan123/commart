# test_save_manager.gd  (GUT)
# E4-S4 / E2 / E4 红项端到端关闭（QA §7-1 · 主理人点名）
# 断言：存档仅含白名单键 {saveVersion, mastery, visited, settings}；
#       无论误写还是落盘，都绝不出现 relationshipSignal / 任何 S9 字段 / 任何 consequence 字段。

extends GutTest

func before_each() -> void:
	_reset_save()


func _reset_save() -> void:
	var da := DirAccess.open("user://")
	if da != null and da.file_exists("save_v1.json"):
		da.remove("save_v1.json")
	SaveManager.load_save()


# 即便构造含禁出盘字段的 dict，_sanitize 也剔除（白名单，非黑名单）。
func test_sanitize_strips_forbidden_keys():
	var dirty := {
		"saveVersion": 1,
		"mastery": {"s01-shake-the-hive": 3},
		"visited": ["s01_scene_01"],
		"settings": {},
		"relationshipSignal": -1,       # 禁出盘
		"consequence": {"npcReaction": "x", "relationshipSignal": 0},
		"s9Account": 42,                # 任何 S9 字段
	}
	var clean := SaveManager._sanitize(dirty)
	for key in clean.keys():
		assert_true(SaveManager.ALLOWED_KEYS.has(key),
				"存档键 '%s' 必须在白名单内" % key)
	assert_false(clean.has("relationshipSignal"), "禁止 relationshipSignal 出盘")
	assert_false(clean.has("consequence"), "禁止 consequence 出盘")
	assert_false(clean.has("s9Account"), "禁止任何 S9 字段出盘")
	assert_true(clean.has("mastery"), "mastery 应保留")
	assert_eq(clean["mastery"]["s01-shake-the-hive"], 3, "mastery 值应保留")


# 经 save_state → to_dict → 磁盘文件，全程无禁出盘字段（E2/E4 端到端）。
func test_save_state_no_forbidden_on_disk():
	var mastery := {"s01-shake-the-hive": 2}
	var visited := ["s01_scene_01"]
	SaveManager.save_state(mastery, visited, {})

	var d := SaveManager.to_dict()
	for key in d.keys():
		assert_true(SaveManager.ALLOWED_KEYS.has(key),
				"to_dict 键 '%s' 须在白名单" % key)

	var raw := _read_disk()
	for key in raw.keys():
		assert_true(SaveManager.ALLOWED_KEYS.has(key),
				"磁盘键 '%s' 须在白名单" % key)
	assert_false(raw.has("relationshipSignal"), "磁盘存档禁止含 relationshipSignal")
	assert_false(raw.has("consequence"), "磁盘存档禁止含 consequence")
	assert_false(raw.has("s9Account"), "磁盘存档禁止含 S9 字段")


# set_mastery 钳制 0–3。
func test_mastery_clamped():
	SaveManager.set_mastery("s01-shake-the-hive", 99)
	assert_eq(SaveManager.get_mastery("s01-shake-the-hive"), 3, "上限钳制 3")
	SaveManager.set_mastery("s01-shake-the-hive", -5)
	assert_eq(SaveManager.get_mastery("s01-shake-the-hive"), 0, "下限钳制 0")


# mark_visited 去重。
func test_mark_visited_dedup():
	SaveManager.mark_visited("s01_scene_01")
	SaveManager.mark_visited("s01_scene_01")
	assert_eq(SaveManager.get_visited().count("s01_scene_01"), 1, "visited 应去重")


func _read_disk() -> Dictionary:
	if not FileAccess.file_exists(SaveManager.SAVE_PATH):
		return {}
	var f := FileAccess.open(SaveManager.SAVE_PATH, FileAccess.READ)
	if f == null:
		return {}
	var text := f.get_as_text()
	f.close()
	var json := JSON.new()
	var parsed = json.parse_string(text)
	if parsed is Dictionary:
		return parsed
	return {}
