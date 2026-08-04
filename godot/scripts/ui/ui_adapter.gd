# ui_adapter.gd  (ui)
# E0-S3 安全区适配（控制清单 C4 / R3 缺口）
#
# 唯一读取设备安全区（刘海/圆角/手势条）的内边距并施加到根 MarginContainer 的
# 上下左右内边距的「单点」。其他系统一律经本适配器，不得直接调用 DisplayServer。
#
# Godot 4.3 API：DisplayServer.get_safe_area() 返回 Rect2（物理窗口坐标，position=左上内缩，
# size=安全区尺寸）。需换算到视口坐标（基准 1080×1920，canvas_items 拉伸）再写入 MarginContainer
# 的 theme override 边距。无安全区信息的平台返回零 Rect2 → 仅用 BASE_MARGIN。
class_name UIAdapter
extends RefCounted

const BASE_MARGIN := 24.0


# 把设备安全区内边距应用到根 MarginContainer（竖屏六屏共用的安全区容器）。
static func apply_safe_area(root_margin: MarginContainer) -> void:
    if root_margin == null:
        return

    var safe := DisplayServer.get_safe_area()   # Rect2，物理窗口坐标
    var win_size := DisplayServer.window_get_size()  # Vector2i，物理窗口尺寸
    var vp_size := root_margin.get_viewport_rect().size  # Vector2，视口尺寸

    var left: float = BASE_MARGIN
    var top: float = BASE_MARGIN
    var right: float = BASE_MARGIN
    var bottom: float = BASE_MARGIN

    if safe != Rect2() and win_size.x > 0 and win_size.y > 0:
        # 物理像素 → 视口像素 的缩放（canvas_items 拉伸下视口为基准分辨率）
        var scale_x := vp_size.x / float(win_size.x)
        var scale_y := vp_size.y / float(win_size.y)
        left = BASE_MARGIN + safe.position.x * scale_x
        top = BASE_MARGIN + safe.position.y * scale_y
        right = BASE_MARGIN + (float(win_size.x) - (safe.position.x + safe.size.x)) * scale_x
        bottom = BASE_MARGIN + (float(win_size.y) - (safe.position.y + safe.size.y)) * scale_y

    root_margin.add_theme_constant_override("margin_left", int(left))
    root_margin.add_theme_constant_override("margin_top", int(top))
    root_margin.add_theme_constant_override("margin_right", int(right))
    root_margin.add_theme_constant_override("margin_bottom", int(bottom))
