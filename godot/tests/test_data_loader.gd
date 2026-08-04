# test_data_loader.gd  (GUT)
# E1-S1 / E1-S2 / A4 / A8 / A10
# 对照 test-scaffolding.md §2.1（A / B）骨架。
extends GutTest

# A. JSON 解析失败精确定位（A8 / R4）
func test_parse_error_reports_line_and_message():
    var bad := '{"id": "x", "triggers": }'   # 故意坏 JSON
    var json := JSON.new()
    var err = json.parse_string(bad)
    assert_true(err == null, "坏数据应解析失败")
    # A8：取 get_error_line()/get_error_message() 用于定位
    assert_true(json.get_error_line() > 0, "应给出错误行号")
    assert_ne(json.get_error_message(), "", "应给出错误信息")


# B. BOM 剥离（A4，红项）
# 用 PackedByteArray 拼 EF BB BF + 合法场景 JSON 字节，写临时文件再经 DataLoader 加载
# （任务要求：无需单独的 bom 文件，BOM 在测试代码内组装）。
func test_loader_strips_utf8_bom():
    var json_text := '{"schemaVersion":"1","id":"s01_scene_01","skill":"s01-shake-the-hive","title":"BOM 测试","context":"情境背景","npc":{"name":"小陈","role":"下属","mood":"defensive","line":"末句"},"impulse":"冲动","triggers":{"candidates":["A","B"],"correct":"A"},"choices":[{"id":"c1","type":"skilled","text":"熟练选项","consequence":{"npcReaction":"r","relationshipSignal":1,"judgement":"j"}}],"review":{"mechanism":"m","case":"c","migration":"g"}}'
    var bytes := PackedByteArray()
    bytes.append_array(PackedByteArray([0xEF, 0xBB, 0xBF]))   # UTF-8 BOM
    bytes.append_array(json_text.to_utf8_buffer())
    var tmp := "user://_bom_test.json"
    var f := FileAccess.open(tmp, FileAccess.WRITE)
    assert_not_null(f, "应能创建临时文件")
    f.store_buffer(bytes)
    f.close()
    var scen := DataLoader.load_one(tmp)
    assert_not_null(scen, "带 BOM 文件应被成功解析为 Scenario")
    assert_eq(scen.id, "s01_scene_01", "带 BOM 文件应被正确解析为首个场景")


# C. 单一入口：经 DataLoader.get_scenario 取到已缓存场景（A10）
func test_get_scenario_returns_loaded_scenario():
    # DataLoader._ready 已枚举 res://data/scenarios/（含 Sprint 1 代位 s01_scene_01.json）
    var scen := DataLoader.get_scenario("s01_scene_01")
    assert_not_null(scen, "应能经 DataLoader 取到 s01_scene_01")
    if scen != null:
        assert_eq(scen.id, "s01_scene_01")
        assert_eq(scen.skill, "s01-shake-the-hive")
        # 文本来自数据（ADR-001）：断言 Scenario 携带 context/impulse/npc.line，无硬编码
        assert_false(scen.context.is_empty(), "context 应来自数据")
        assert_false(scen.impulse.is_empty(), "impulse 应来自数据")
        assert_false(scen.npc.line.is_empty(), "npc.line 应来自数据（G3）")
