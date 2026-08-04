# MasterySystem.gd  (core / S7 轻量掌握度 · E4-S3)
#
# 0–3 档轻量掌握度，无分数压力（UX §4.2 / 控制清单 F2）。
# 规则（可测试、无惩罚语义、单调不降级）：
#   - 每场景 replay 一次累加 plays（上限 3）；
#   - 至少一次选 skilled 保底 1 档；
#   - 技能级别 = clamp( max(本技能 plays 合计, skilled?1:0), 0, 3 )，并与存档级别取 max（不降级）。
# 存档仅经 SaveManager（mastery / visited 白名单键），本类不触碰任何禁出盘字段。
# 关系信号在三态之后仍仅由 PlaySession 渲染、绝不由此持久化（见 SaveManager 白名单）。

class_name MasterySystem
extends RefCounted

const MAX_LEVEL := 3

# 会话内记录：scenario_id -> {"plays": int, "skilled": bool}。
# NOTE：本切片不跨会话持久 plays 细节（白名单只允许 mastery/visited/settings），
# 仅把「派生出的技能级别」经 SaveManager 持久化；跨会话以 SaveManager.mastery 为权威。
var _records: Dictionary = {}


func _init() -> void:
	_rebuild_from_save()


# 从 SaveManager.visited 重建会话内记录（已玩过的场景记 plays=1）。
func _rebuild_from_save() -> void:
	_records.clear()
	for sid in SaveManager.get_visited():
		_records[String(sid)] = {"plays": 1, "skilled": false}


# 记录一次场景完成。skilled_chosen 表示本次是否选了 skilled 选项。
# 同时：① 经 SaveManager.mark_visited 记录 visited；② 重算并持久该技能掌握度级别。
func record_scenario(id: String, skilled_chosen: bool = false) -> void:
	if id == "":
		return
	id = String(id)
	if not _records.has(id):
		_records[id] = {"plays": 0, "skilled": false}
	_records[id]["plays"] = int(_records[id]["plays"]) + 1
	if skilled_chosen:
		_records[id]["skilled"] = true

	SaveManager.mark_visited(id)

	var skill_id := _skill_of(id)
	if skill_id != "":
		var computed := mastery_for_skill(skill_id, _scenarios_of(skill_id))
		var persisted := SaveManager.get_mastery(skill_id)
		# 单调不降级：新级别取「计算值」与「已存级别」的较大者（无惩罚语义）。
		var new_lvl := clamp(max(computed, persisted), 0, MAX_LEVEL)
		SaveManager.set_mastery(skill_id, new_lvl)


# 纯函数：给定技能 id 与其场景列表，按 _records 计算 0–3 档（不读写存档）。
func mastery_for_skill(skill_id: String, scenarios: Array) -> int:
	if scenarios.is_empty():
		return 0
	var plays := 0
	var has_skilled := false
	for sid in scenarios:
		var rec = _records.get(String(sid), null)
		if rec != null:
			plays += int(rec["plays"])
			if bool(rec["skilled"]):
				has_skilled = true
	var lvl := clamp(plays, 0, MAX_LEVEL)
	if has_skilled:
		lvl = max(lvl, 1)
	return clamp(lvl, 0, MAX_LEVEL)


# 读取某技能掌握度（委派 SaveManager，跨会话权威）。
func get_mastery(skill_id: String) -> int:
	return SaveManager.get_mastery(String(skill_id))


func _skill_of(scenario_id: String) -> String:
	var scen := DataLoader.get_scenario(scenario_id)
	if scen != null:
		return scen.skill
	return ""


func _scenarios_of(skill_id: String) -> Array:
	var idx: Dictionary = DataLoader.get_skills_index()
	for skill in idx.get("skills", []):
		if skill is Dictionary and String(skill.get("id", "")) == skill_id:
			return skill.get("scenes", [])
	return []
