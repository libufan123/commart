# test_validator.gd  (GUT)
# E1-S3 / 约束4 / A6 / A7 / G2 方案A
# 对照 test-scaffolding.md §2.1（C）骨架。
extends GutTest

func _load_dict(path: String) -> Dictionary:
    return DataLoader.load_dict(path)


# A6：correct ∉ candidates → 不通过
func test_validator_correct_must_be_in_candidates():
    var d := _load_dict("res://tests/fixtures/s01_bad_correct.json")
    assert_false(ScenarioValidator.validate(d).ok, "correct∉candidates 应不通过")


# A6：无 skilled 选项 → 不通过
func test_validator_requires_one_skilled():
    var d := _load_dict("res://tests/fixtures/s01_no_skilled.json")
    assert_false(ScenarioValidator.validate(d).ok, "无 skilled 选项应不通过")


# A7 / E5：review.case 缺失 → 放行但标记 has_review_case=false（降级不崩溃）
func test_validator_missing_review_case_degrades():
    var d := _load_dict("res://tests/fixtures/s01_no_review_case.json")
    var r := ScenarioValidator.validate(d)
    assert_true(r.ok, "review.case 缺失应放行")
    assert_false(r.has_review_case, "应标记 case 缺失，供 ReviewPanel 降级渲染")


# 约束4 / G2：triggers.miss 须与 consequence 同构
func test_validator_miss_is_consequence_shaped():
    var d := _load_dict("res://tests/fixtures/s01_ok.json")
    var r := ScenarioValidator.validate(d)
    assert_true(r.miss_isomorphic, "triggers.miss 须与 consequence 同构")


# 正向：合法场景 ok 且含 review.case
func test_validator_valid_scenario_ok():
    var d := _load_dict("res://tests/fixtures/s01_ok.json")
    var r := ScenarioValidator.validate(d)
    assert_true(r.ok, "合法场景应 ok")
    assert_true(r.has_review_case, "合法场景应含 review.case")
