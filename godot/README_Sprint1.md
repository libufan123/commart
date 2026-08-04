# Sprint 1 验证说明 · 沟通技能学习游戏（Godot 4.3 · 竖屏）

> Owner：engineering-lead（程基岩）
> Sprint 1 = E0（工程地基）+ E1-S1（数据层 S1）+ E2-S1（场景卡渲染）
> 落地的红项：**A4（BOM 剥离）/ B1·B2（CJK 字体）/ C4（安全区适配器）**
> 本 Sprint 仅产出真实源码/文本文件；**未运行 Godot/GUT**（沙箱无 Godot 二进制、无字体二进制）。

---

## 1. 环境准备（一次性）

1. **Godot 4.3**：从 <https://godotengine.org/> 下载并安装 Godot 4.3（标准版，非 .NET 亦可）。
2. **CJK 字体（B1/B2 红项）**：把 `NotoSansSC-Regular.ttf`（OFL，Google Fonts 获取）放到
   `godot/assets/fonts/NotoSansSC-Regular.ttf`。详见 `assets/fonts/README_字体.md`。
   **未放字体前 `test_cjk_font.gd` 会失败——预期，放好即绿。**
3. **GUT 9.3+**：把 GUT 仓库的 `addons/gut/` 整体放入 `godot/addons/gut/`（用户自行 vendor）。
   编辑器内 `Project → Project Settings → Plugins` 找到 **Gut** 启用（会写入 `project.godot` 的
   `[editor_plugins]`）。未 vendor 前工程也能打开，只是跑不了 GUT。

---

## 2. 打开工程

用 Godot 4.3 打开 `godot/project.godot`。工程已锁定竖屏（§5.1）：

- `viewport 1080×1920`、`handheld/orientation="portrait"`、`stretch mode=canvas_items`、`aspect=expand`。

---

## 3. 跑 GUT（预期全绿）

编辑器内 `Project → Tools → GUT`（或 `Ctrl+Shift+G`）→ 选 `res://tests` → Run。
或 headless（CI 质量门，退出码 0 为通过）：

```bash
godot --headless --path . --rendering-driver opengl3 \
      --scene res://addons/gut/gut.tscn \
      -gdir=res://tests -gexit
```

Sprint 1 覆盖用例（`extends GutTest`）：

| 文件 | 用例 | 守护项 |
|---|---|---|
| `tests/test_data_loader.gd` | `test_parse_error_reports_line_and_message` | A8 解析错误定位 |
| | `test_loader_strips_utf8_bom` | **A4** BOM 剥离（代码内拼 EF BB BF + 写临时文件再加载） |
| | `test_get_scenario_returns_loaded_scenario` | A10 单一入口 |
| `tests/test_validator.gd` | `test_validator_correct_must_be_in_candidates` | A6 |
| | `test_validator_requires_one_skilled` | A6 |
| | `test_validator_missing_review_case_degrades` | A7 / E5 降级 |
| | `test_validator_miss_is_consequence_shaped` | 约束4 / G2 同构 |
| | `test_validator_valid_scenario_ok` | 正向 |
| `tests/test_cjk_font.gd` | `test_default_font_points_to_cjk` | **B1/B2** 默认字体指向 CJK |

> `test_cjk_font` 依赖字体文件存在；其余用例不依赖字体，可立即全绿。

---

## 4. 渲染一个场景（最小可玩证据）

1. 打开 `scenes/play/PlaySession.tscn`（当前 `main_scene`）。
2. 运行（F5）：`ScenarioEngine._ready` 经 `DataLoader.get_scenario("s01_scene_01")` 取数据，
   SceneCard 显示中文 **情境 + 对方末句（`npc.line`）+ 冲动气泡**，文本全部来自数据，无硬编码。
3. 安全区适配器 `UIAdapter.apply_safe_area` 在 `_ready` 对根 `RootMargin` 施加内边距（C4 适配器落地；
   真机遮挡验证见 E6-S3）。

> 若 `data/scenarios/` 下暂无设计侧交付的 `s01_scene_01.json`，Sprint 1 已放入一份**代位副本**
> （内容等同 `tests/fixtures/s01_ok.json`），保证引擎开箱即有场景可加载；设计侧交付后以真文件覆盖即可。

---

## 5. 本 Sprint 未实现（边界已留）

- `RunState` / `SaveManager`：Autoload 暂未注册（project.godot 已留注释）。
- **relationshipSignal 绝不写盘**（E2/E4 红项）：`scenario_types.gd` 的 `Consequence.relationship_signal`
  为只读展示字段；后续 `SaveManager` 只允许写 `mastery/visited/settings`（白名单），不得读取/写入该字段。
- S3 硬闸门 / S4 抉择 / S5 后果 / S6 复盘 / S8 导航：属 E2–E4，后续 Sprint。

---

## 6. 真机验证（非沙箱可跑，须用户执行）

- **B3 真机中文**：至少一台 iOS 或 Android 真机启动场景卡，确认中文非豆腐块（模拟器不作为唯一验证）。
- **C4 真机安全区**：异形屏真机确认顶部/底部/侧边不被裁切，且横屏不可触发。
- **E2/E4 代码评审卡点**：后续 SaveManager 落地时，评审确认 `relationshipSignal` 未进存档。
