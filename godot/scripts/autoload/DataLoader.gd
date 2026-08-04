# DataLoader.gd  (autoload)
# E1-S1 数据层：枚举 res://data/scenarios/*.json → 字节级去 BOM → JSON 解析 → 校验 → 类型封装 → 缓存
#
# 单一数据入口（ADR-001 / 控制清单 A10）：S2–S8 一律经 get_scenario(id)，禁止直接 FileAccess 读盘。
# 仅用 JSON.new().parse_string()（Godot 4.3，禁用已弃用 parse_json）。
# 严格对照 engin-architecture.md §4、adr.md ADR-002、Epic E1-S1。
extends Node

signal data_ready

var _scenarios: Dictionary = {}      # id -> Scenario
var _skills_index: Dictionary = {}   # 解析后的 skills_index.json


func _ready() -> void:
    _load_all_scenarios()
    _load_skills_index()
    data_ready.emit()


# ---- 对外查询 ----
func get_scenario(id: String) -> Scenario:
    if _scenarios.has(id):
        return _scenarios[id]
    return null


func get_skills_index() -> Dictionary:
    return _skills_index


# ---- 测试 / E1 用：加载单个文件，走完整管线（读字节→去 BOM→解析→校验→封装）----
func load_one(path: String) -> Scenario:
    var bytes := _read_bytes(path)
    if bytes.is_empty():
        _report(path, "读取为空或失败")
        return null
    var d := _parse_bytes(bytes, path)
    if d.is_empty():
        return null   # 解析错误已在 _parse_bytes 内上报
    var res := ScenarioValidator.validate(d)
    if not res.ok:
        _report(path, "校验失败: " + str(res.errors))
        return null
    return Scenario.new(d)


# ---- 测试用：返回原始 dict（供 ScenarioValidator 单测；不缓存、不校验）----
func load_dict(path: String) -> Dictionary:
    var bytes := _read_bytes(path)
    if bytes.is_empty():
        _report(path, "读取为空或失败")
        return {}
    return _parse_bytes(bytes, path)


# ---- 内部：枚举并缓存全部场景 ----
func _load_all_scenarios() -> void:
    var dir := DirAccess.open("res://data/scenarios/")
    if dir == null:
        _report("res://data/scenarios/", "目录不存在，跳过场景加载")
        return
    dir.list_dir_begin()
    var fname := dir.get_next()
    while fname != "":
        if fname.ends_with(".json"):
            _load_and_cache("res://data/scenarios/" + fname)
        fname = dir.get_next()
    dir.list_dir_end()


func _load_and_cache(path: String) -> void:
    var bytes := _read_bytes(path)
    if bytes.is_empty():
        _report(path, "读取为空或失败")
        return
    var d := _parse_bytes(bytes, path)
    if d.is_empty():
        return
    var res := ScenarioValidator.validate(d)
    if not res.ok:
        _report(path, "校验失败: " + str(res.errors))
        return
    var scen := Scenario.new(d)
    _scenarios[scen.id] = scen


# ---- 内部：加载 S8 导航元数据（E1-S5 / 架构 §6.4）----
# 切片期含 s01/s03/s04（G5）。E5 数据交付前文件可缺失，不阻塞（降级日志）。
func _load_skills_index() -> void:
    var path := "res://data/skills_index.json"
    if not FileAccess.file_exists(path):
        print("[DataLoader] skills_index.json 缺失，跳过（E5 交付后自动加载）。")
        return
    var d := _parse_bytes(_read_bytes(path), path)
    if d.is_empty():
        return
    _skills_index = d


# ---- 内部：读字节（res:// 在导出包中可读）----
func _read_bytes(path: String) -> PackedByteArray:
    if not FileAccess.file_exists(path):
        return PackedByteArray()
    return FileAccess.get_file_as_bytes(path)


# ---- 内部：字节级去 BOM + JSON.parse_string（Godot 4.3）----
func _parse_bytes(bytes: PackedByteArray, path: String) -> Dictionary:
    var stripped := bytes
    # UTF-8 BOM 检测并剥离（R2 / A4）：首 3 字节 EF BB BF
    if bytes.size() >= 3 and bytes[0] == 0xEF and bytes[1] == 0xBB and bytes[2] == 0xBF:
        stripped = bytes.slice(3)
    var text := stripped.get_string_from_utf8()
    var json := JSON.new()
    var result = json.parse_string(text)
    if result == null or not (result is Dictionary):
        # A8：解析失败取 get_error_line()/get_error_message() 精确定位（R4）
        var line := json.get_error_line()
        var msg := json.get_error_message()
        _report(path, "JSON 解析失败 @行 " + str(line) + ": " + msg)
        return {}
    return result


# ---- 内部：strict/release 分流（A9）----
# 开发（debug）构建：push_error + 跳过；发布（release）构建：日志 + 跳过（不崩溃）。
func _report(path: String, msg: String) -> void:
    if OS.is_debug_build():
        push_error("[DataLoader] " + path + " -> " + msg)
    else:
        print("[DataLoader][WARN] " + path + " -> " + msg)
