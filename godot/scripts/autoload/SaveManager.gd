# SaveManager.gd  (autoload / E4-S4 · 轻量存档 + 禁持久化红项 E2/E4)
#
# 白名单写入（非黑名单）：存档仅允许 { saveVersion, mastery, visited, settings }。
# 永远不写 relationshipSignal / 任何 S9 字段 / 任何 consequence 字段（E2/E4 红项端到端关闭）。
#
# 设计要点（对照 engin-architecture.md §6.3 / ADR-005 / Epic E4-S4）：
#   - _sanitize() 在「载入」与「落盘」两处都执行，构成双重保险：即便将来有代码误写
#     禁出盘字段，落盘前也会被剔除，磁盘文件永远不含 relationshipSignal/S9/consequence。
#   - 路径 user://save_v1.json（各平台沙盒，iOS/Android 均可用，无需网络/账号）。
#   - 读写失败静默降级：首次无存档 / 文件损坏 / 无写权限 → 返回空结构，不崩溃。

extends Node

const SAVE_PATH := "user://save_v1.json"
const SAVE_VERSION := 1
const MAX_MASTERY := 3

# 白名单：存档仅允许这些顶层键。任何其它键（relationshipSignal / S9 / consequence 等）
# 一律丢弃。测试据此断言「无禁出盘字段」。
const ALLOWED_KEYS := ["saveVersion", "mastery", "visited", "settings"]

var _data: Dictionary = {}

signal save_loaded

func _ready() -> void:
	load_save()


func _empty() -> Dictionary:
	return {"saveVersion": SAVE_VERSION, "mastery": {}, "visited": [], "settings": {}}


# 仅保留白名单键（双重保险）。mastery 值钳制 0–3；visited 强制字符串数组；
# settings 内容自由（但顶层只允许这一个键）。saveVersion 固定为本版（与数据
# schemaVersion 解耦，见 E4-S4）。任何非白名单键一律不进入返回值。
func _sanitize(d: Dictionary) -> Dictionary:
	var out := _empty()
	if d.has("mastery") and d["mastery"] is Dictionary:
		for k in d["mastery"].keys():
			out["mastery"][String(k)] = clamp(int(d["mastery"][k]), 0, MAX_MASTERY)
	if d.has("visited") and d["visited"] is Array:
		for v in d["visited"]:
			out["visited"].append(String(v))
	if d.has("settings") and d["settings"] is Dictionary:
		out["settings"] = (d["settings"] as Dictionary).duplicate()
	return out


# 读盘恢复；无文件/损坏 → 返回空结构（不崩溃）。
func load_save() -> void:
	_data = _empty()
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return
	var text := f.get_as_text()
	f.close()
	var json := JSON.new()
	var parsed = json.parse_string(text)
	if parsed == null or not (parsed is Dictionary):
		return
	_data = _sanitize(parsed)
	save_loaded.emit()


# 是否存在存档文件（MainMenu「继续」可用性判断）。
func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


# 返回白名单快照（供测试断言「仅含白名单键」）。
func to_dict() -> Dictionary:
	return _sanitize(_data)


# 整体覆盖写入（mastery:dict / visited:array / settings:dict）。仅触碰白名单键。
func save_state(mastery_dict: Dictionary, visited_arr: Array, settings_dict: Dictionary) -> void:
	_data = _empty()
	if mastery_dict is Dictionary:
		for k in mastery_dict.keys():
			_data["mastery"][String(k)] = clamp(int(mastery_dict[k]), 0, MAX_MASTERY)
	if visited_arr is Array:
		for v in visited_arr:
			_data["visited"].append(String(v))
	if settings_dict is Dictionary:
		_data["settings"] = (settings_dict as Dictionary).duplicate()
	_write()


# 标记某场景已玩过（去重追加到 visited）。
func mark_visited(id: String) -> void:
	if id == "":
		return
	id = String(id)
	if not _data["visited"].has(id):
		_data["visited"].append(id)
	_write()


# 设置某技能掌握度（钳制 0–3）。
func set_mastery(id: String, level: int) -> void:
	if id == "":
		return
	_data["mastery"][String(id)] = clamp(int(level), 0, MAX_MASTERY)
	_write()


# 读取某技能掌握度（缺省 0）。
func get_mastery(id: String) -> int:
	if _data["mastery"].has(String(id)):
		return int(_data["mastery"][String(id)])
	return 0


# 返回 visited 的副本（避免外部篡改内部数组）。
func get_visited() -> Array:
	return (_data["visited"] as Array).duplicate()


# 落盘；写字前再 sanitize 一次，确保零禁出盘字段。失败静默降级。
func _write() -> void:
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		# 读写失败静默降级（无权限/沙盒问题不崩溃）
		return
	var out := _sanitize(_data)   # 落盘前再 sanitize，确保零禁出盘字段
	f.store_string(JSON.stringify(out))
	f.close()
