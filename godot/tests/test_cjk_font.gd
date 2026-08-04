# test_cjk_font.gd  (GUT)
# E0 / B1 / B2 —— 默认字体指向 CJK 字体
# 对照 test-scaffolding.md §2.4 骨架。
extends GutTest

func test_default_font_points_to_cjk():
    # 需先把 NotoSansSC-Regular.ttf 放入 res://assets/fonts/（见 assets/fonts/README_字体.md）。
    # 未放字体时本用例会因 default_font 为 null 而失败——此为预期，放好字体后即绿（B3 真机为准）。
    var theme: Theme = load("res://scripts/theme/portrait_theme.tres")
    assert_not_null(theme, "portrait_theme.tres 应可加载（需先放入 NotoSansSC-Regular.ttf）")
    if theme == null:
        return
    assert_not_null(theme.default_font, "主题必须有 default_font")
    # 断言默认字体资源路径指向 CJK 字体（如 NotoSansSC），否则中文豆腐块
    assert_true(theme.default_font.resource_path.contains("NotoSansSC"),
        "default_font 应指向 CJK 字体，否则中文豆腐块")
