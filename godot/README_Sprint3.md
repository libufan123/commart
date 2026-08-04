# README · Sprint 3（Phase 5）— 导航 S8 + 掌握度 S7 + SaveManager + E6 集成

> **Owner**：engineering-lead（程基岩）
> **引擎**：Godot 4.3 · iOS/Android 竖屏 · Lean
> **本 Sprint 范围**：E4-S2/S3（导航）/ E4-S4（SaveManager）/ E4-S5（主菜单）/ E4-S3（掌握度）/ E6 集成（六屏烟雾 + 双重解析修复）+ Sprint2 QA §7 强制条目收口。

---

## 1. 新增 / 修改文件清单

### 新增
| 路径 | 职责 |
|---|---|
| `scripts/autoload/SaveManager.gd` | E4-S4 轻量存档（白名单写入，关 E2/E4 红项） |
| `scripts/core/MasterySystem.gd` | E4-S3 轻量掌握度 0–3（replay 递增 / skilled 保底 / 不串扰 / 单调不降级） |
| `scripts/ui/SkillMap.gd` | E4-S2/S3 技能地图导航（读 skills_index、visited 标记、启动 PlaySession） |
| `scenes/play/SkillMap.tscn` | 技能地图场景（根 Control + RootMargin + VBox + SkillList） |
| `scripts/ui/MainMenu.gd` | E4-S5 主菜单入口（开始学习 / 继续 → SkillMap） |
| `scenes/play/MainMenu.tscn` | 主菜单场景（新 boot 入口） |
| `tests/test_save_manager.gd` | 【E2/E4 红项·主理人点名】白名单断言 |
| `tests/test_play_session.gd` | 【QA §7-4 六屏烟雾 / §7-3 D8 安全失败 / §7-5 A7 降级】 |
| `tests/test_mastery.gd` | 掌握度钳制 / replay / 不串扰 / 存档干净 |
| `tests/save_whitelist_equiv.py` | 纯逻辑 Python 等价校验（非 Godot 运行） |

### 修改
| 路径 | 修改点 |
|---|---|
| `scripts/systems/PlaySession.gd` | ① 新增 `external_boot` 旗标（防导航冲突）；② 修复 §E 双重解析（移除 `_on_choice_chosen` 内 `resolve_consequence()`，仅 `choose()` 单次显式调用，加 `@警示`）；③ 新增 `get_last_chosen_type()` 只读 getter。**六屏状态机逻辑未动。** |
| `project.godot` | 启用 `SaveManager` autoload（取消注释）；`run/main_scene` 改为 `MainMenu.tscn`（E6 集成入口）。 |

### 复用（未重写契约）
`DataLoader.gd` / `ScenarioValidator.gd` / `scenario_types.gd` / `ui_adapter.gd` / `TriggerSystem.gd` / `ChoiceSystem.gd` / `ConsequenceEngine.gd` / `ScenarioEngine.gd` 全部复用，核心契约不变。

---

## 2. SaveManager 白名单如何保证 relationshipSignal / consequence 永不写入

**核心手段：白名单写入（非黑名单）+ 双重 `sanitize` 保险。**

1. **常量白名单**：`const ALLOWED_KEYS := ["saveVersion", "mastery", "visited", "settings"]`。存档结构只允许这四个顶层键。
2. **`_sanitize(d)` 统一收口**：所有进入 `_data` 的路径（载入 `load_save` 与落盘 `_write`）都先经 `_sanitize` —— 它只把白名单键拷贝出来，`mastery` 值钳制 0–3，`visited` 强制字符串数组，`settings` 原样搬（但顶层仅此一个键）；**任何非白名单键（relationshipSignal / S9 / consequence 等）一律不进入返回值**。
3. **落盘前再 sanitize 一次**：`_write()` 在 `JSON.stringify` 之前调用 `_sanitize(_data)`，确保磁盘文件零禁出盘字段。
4. **API 只暴露白名单操作**：`mark_visited` 只动 `visited`；`set_mastery` 只动 `mastery`；`save_state` 只接收 mastery/visited/settings 三参。没有任何 API 接受或写入 relationshipSignal / consequence。

```gdscript
# 关键代码思路（SaveManager.gd）
func _sanitize(d):
    var out = _empty()                       # 仅含白名单四键
    if d["mastery"] is Dictionary:
        for k in d["mastery"]: out["mastery"][k] = clamp(int(...),0,3)
    if d["visited"] is Array:
        for v in d["visited"]: out["visited"].append(String(v))
    if d["settings"] is Dictionary: out["settings"] = d["settings"].duplicate()
    return out                               # 其余键（relationshipSignal/S9/consequence）全部丢弃
```

> 测试 `test_save_manager.gd` 构造含 `relationshipSignal/-1`、`consequence{...}`、`s9Account/42` 的脏 dict，分别经 `_sanitize` → `to_dict` → 读回磁盘文件三层断言：仅含白名单键、无禁出盘字段。**E2/E4 红项端到端关闭。**

---

## 3. PlaySession choose 双重解析修复方式

**收敛点（单路径）**：原 `choose()` 内 `_choice_panel.choose()` 会 emit `chosen` → 已连的 `_on_choice_chosen` 解析一次；紧接着 `choose()` 又显式 `resolve_consequence()` 解析第二次（幂等但冗余，QA `§7-6` / Sprint2 CONCERNS P2-1）。

**修复**：移除 `_on_choice_chosen` 内的 `resolve_consequence()` 调用，结算统一由 `choose()` 内的显式 `resolve_consequence()` 完成（一次）。`_on_choice_chosen` 保留为 `pass`（保留 `chosen` 信号连接位，供未来埋点，但不再承担结算）。

```gdscript
# @警示 已修复 P2-1（QA §7-6）：resolve 仅由 choose() 内显式调用一次
func _on_choice_chosen(_choice_id, _choice_type):
    pass   # 单路径：结算统一在 choose() 内的 resolve_consequence() 完成
```

**确认 `@警示` 已改**：见 `scripts/systems/PlaySession.gd` 的 `_on_choice_chosen` 上方注释。`can_choose()` 闸门、`chosen` signal、`replay_current` / `next_scenario` 行为均未变；六屏状态机逻辑未动。

---

## 4. 六屏状态机烟雾 / D8 安全失败 / A7 降级的实现结论

- **六屏烟雾（`test_play_session.gd::test_six_stage_state_machine_smoke`）**：用真实 `DataLoader.get_scenario("s01_scene_01")` 驱动 `load_scenario` → 断言 `stage==S2`；`submit_trigger(triggers.correct)` → `S4`；`can_choose()==true`；`choose(skilled_id)` → `S5` 且 `_resolved` 非空；`_show_review()` → `S6`；`replay_current()` → 回 `S2`；`next_scenario()` → 切到 `s01_scene_02`；继续 `next_scenario` 遍历剩余场景末尾触发 `all_done`。choice id 全部取自真实数据（skilled 取 `type=="skilled"`，correct 取 `triggers.correct`）。
- **D8 安全失败（`test_double_trap_safe_failure`，QA §7-3）**：同场景连续两次 `choose(trap_id)` —— 第一次与第二次 `_resolved.npc_reaction` 完全一致（幂等），复盘照常展开（不封锁），`replay_current` 无冷却立即回 `S2`。架构 stateless，无封锁/扣分/冷却机制，已固化为断言。
- **A7 运行时降级（`test_review_case_missing_hides_section`，QA §7-5）**：用 `DataLoader.load_dict` + 手动置空 `review.case` 构造缺 case 的 scenario，驱动到 `S6`，断言 `CaseSection.visible == false`（降级隐藏，不崩溃）。

**Python 等价校验**（非 Godot 运行，开发期核对纯逻辑）：`tests/save_whitelist_equiv.py` 镜像 `_sanitize` 与 `mastery_for_skill` 规则，运行结果：
```
OK  whitelist: 仅留白名单键，relationshipSignal/S9/consequence 全程剔除
OK  mastery: replay递增 / skilled保底 / 不串扰 / 钳制3 / 空列表0
ALL PY EQUIV CHECKS PASSED
```

---

## 5. 导航接线：SkillMap → PlaySession → 地图

**SkillMap 启动 PlaySession**（`scripts/ui/SkillMap.gd::_start_skill`）：
1. 从 `skills_index` 取该技能首场景 id（`scenes[0]`）。
2. 实例化 `PlaySession.tscn`，置 `ps.external_boot = true`（避免其 `_ready` 自动 load 首个场景与导航冲突）。
3. `ps.all_done.connect(_on_session_done.bind(ps))`，`add_child(ps)`，隐藏菜单 `RootMargin`。
4. `ps.load_scenario(DataLoader.get_scenario(first_id))`（复用 PlaySession 现有 API）。

**all_done 回地图**（`_on_session_done`）：
1. `SaveManager.mark_visited(_current_scenario_id)`（标记已玩过）。
2. 若 `ps.get_last_chosen_type() == "skilled"` → `MasterySystem.record_scenario(id, true)`，否则 `record_scenario(id, false)`。
3. `ps.queue_free()`，显示菜单 `RootMargin`，`_refresh_markers()`（更新 visited / 掌握度小标记）。

**MainMenu → SkillMap**：`MainMenu` 标题 +〔开始学习〕/〔继续〕→ 实例化 `SkillMap`（作为 MainMenu 子节点）并仅隐藏菜单 UI（`RootMargin`）；〔继续〕按 `SaveManager.has_save()` 启用。（可见性沿父子链继承，故隐藏的是菜单 UI 容器而非 MainMenu 自身，否则会连子节点 SkillMap 一起隐藏。）

**数据流**：UI 文本——技能名强制取自 `skills_index.title`，菜单 chrome（标题/篇章）为导航外壳；场景文案全部来自 `Scenario` 数据，无硬编码。关系信号在三态之后仍**仅由 PlaySession 渲染、绝不持久化**。

---

## 6. 如何跑（Godot 4.3 + CJK 字体 + GUT）

1. **字体**：将 `NotoSansSC-Regular.ttf`（OFL 授权）放入 `res://assets/fonts/`，确保 `scripts/theme/portrait_theme.tres` 的 `default_font` 指向它（`test_cjk_font.gd` 会校验）。缺失字体时中文为豆腐块（B1/B2 红项，需字体二进制）。
2. **GUT**：把 GUT 9.x（兼容 4.3）vendor 到 `res://addons/gut/`，编辑器 `Project → Plugins` 启用 Gut。
3. **跑测试**：编辑器 `Ctrl+Shift+G` 打开 GUT 面板 → 选 `res://tests/` → Run；或 headless：
   ```bash
   godot --headless --path . --rendering-driver opengl3 \
         --scene res://addons/gut/gut.tscn -gdir=res://tests -gexit
   ```
   预期：本 Sprint 新增 `test_save_manager` / `test_play_session` / `test_mastery` 全绿；既有 `test_data_loader` / `test_validator` / `test_cjk_font` / `test_trigger_system` / `test_consequence_engine` 不受影响。
4. **Python 等价校验**（可选，非 Godot）：`python3 godot/tests/save_whitelist_equiv.py`。

---

## 7. `.tscn` 序列化无法本地验证的假设与提醒

- 本沙箱**无 Godot 二进制**，所有 `.tscn`/`.gd` 仅做静态审阅与契约对照，**未运行实例化验证**。
- `.tscn` 节点树 / 节点名 / 路径耦合（如 `SkillMap.tscn` 的 `RootMargin/VBox/SkillList`、`PlaySession` 内部 `StageRoot/ReviewPanel/CaseSection`）按既有文件（`PlaySession.tscn` / `ReviewPanel.tscn`）同名镜像，但**节点存在性仅能在编辑器/真机/GUT headless 确认**（Sprint2 QA P1-1）。
- `anchors_preset = 15` 沿用既有 `PlaySession.tscn` 的写法（与显式 anchor 值 0/0/1/1 配合决定实际布局），保持一致；若编辑器报未知 preset，可改为 `13`（FULL_RECT）或仅保留显式 anchor 值。
- `main_scene` 已切到 `MainMenu.tscn`；若需单独调试六屏，可在编辑器临时切回 `PlaySession.tscn`。
- **E6 真机 smoke 仍需用户侧执行**（B3 真机中文 / C4 真机安全区 / 节点耦合 / `.tscn↔.gd` 运行期验证）——本环境一律不可验证，列为 Lean 预制作门待办。

---

## 8. 藤蔓三态（RelationshipGlyph 光秃/抽芽/开花）Lean 延后声明

**已按 Lean 显式延后。** 本 Sprint 不实现藤蔓形态（`sym_vine_bare/_sprout/_bloom`），保留「符号 + 文字双编码」（`RelationshipGlyph` 的 `SymbolLabel` + `TextLabel`，如 ＋/–、「关系升温/出现摩擦」），已达 UX §5 色盲下限（Standard 基线）。

- 关系温度仍以「符号 + 文字」承载，不依赖颜色（满足可访问性）。
- 藤蔓形态（光秃/抽芽/开花）属 UX 额外意图（美术圣经 §4.4），非 MVP 出货硬约束；**留作扩展层**，待 art/主理人拍板补实现或正式确认延后。
- 此延后**不影响** E2/E4 红项：关系信号自始至终仅当次渲染、绝不持久化，与藤蔓形态无关。

---

## 9. 已知 carry-over（需 E6 真机/运行验证）
- B3 真机中文渲染、C4 真机安全区、`.tscn↔.gd` 节点耦合、CJK 字体继承、六屏视觉/竖屏单屏可达——均需在工程环境跑一次 GUT 全绿 + 编辑器/真机打开六屏确认。
- GUT 插件需用户侧 vendor 与启用（本仓库未内置 addons/gut）。
