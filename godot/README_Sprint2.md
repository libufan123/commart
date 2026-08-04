# Sprint 2 验证说明 · 沟通技能学习游戏（Godot 4.3 · 竖屏）

> Owner：engineering-lead（程基岩）
> Sprint 2 = E2 完整（S3 触发识别 + PlaySession 硬闸门 + miss 演出）
>           + E3 完整（S4 抉择 + S5 后果查表 + forceBoundary + 关系信号仅渲染）
>           + E4-S1（S6 复盘面板只读渲染）
> **复用 Sprint 1 文件**：DataLoader / ScenarioValidator / scenario_types / ui_adapter 均未改写。
> 本 Sprint 仅产出真实源码/文本文件；**未运行 Godot/GUT**（沙箱无 Godot 二进制、无字体二进制）。

---

## 1. 新增 / 修改文件清单

### 新增系统脚本（`scripts/systems/`，复用 Sprint 1 封装）
| 文件 | 职责 |
|---|---|
| `TriggerSystem.gd` | S3：渲染 `triggers.candidates` 为 TagButton；`submit(label)` 判定 `trigger_correct`；暴露 `selected` / `trigger_correct` / 信号 `submitted`。同时作为 `TriggerPanel.tscn` 面板脚本（沿用架构 §3）。 |
| `ChoiceSystem.gd` | S4：渲染 `choices[].text` 为 ChoiceCard（不标 type 对错）；`choose(id)` 写入内存 `chosen_choice_id` / `chosen_type`；信号 `chosen`。同时作为 `ChoicePanel.tscn` 面板脚本。 |
| `ConsequenceEngine.gd` | S5：`resolve(scenario, chosen_choice_id, trigger_correct) -> Consequence` 纯查表；方案A miss 优先、forceBoundary 确定性路由、miss 缺省降级。 |
| `PlaySession.gd` | 状态机编排器（挂在 `PlaySession.tscn` 根 Node）：S2→S3→S4→S5→S6 一次一屏；暴露测试 API；持有内存态（§6.2）。 |

### 新增场景（`scenes/`）
| 文件 | 说明 |
|---|---|
| `components/TagButton.tscn` | S3 标签按钮（最小高 56≥48，◌ + 候选文本） |
| `components/ChoiceCard.tscn` | S4 选项卡（最小高 96，⬡ + 选项文本，不标对错） |
| `components/RelationshipGlyph.tscn` | 关系信号符号（符号 + 文字双编码，不靠颜色） |
| `play/TriggerPanel.tscn` | S3 面板（脚本 = TriggerSystem.gd） |
| `play/ChoicePanel.tscn` | S4 面板（脚本 = ChoiceSystem.gd） |
| `play/ConsequenceStage.tscn` | S5 后果演出（npcReaction + judgement + RelationshipGlyph + 双按钮） |
| `play/ReviewPanel.tscn` | S6 复盘（只读渲染 mechanism/case/migration + 三导航按钮） |

### 修改（Sprint 1 文件，非禁用清单）
| 文件 | 改动 |
|---|---|
| `scripts/systems/ScenarioEngine.gd` | 抽出静态 `render_card(card, scenario)` 供 PlaySession 复用；实例 `render` 改为委托（逻辑零重复）。 |
| `scenes/play/ScenarioCard.tscn` | 新增 `ContinueButton`（S2→S3 入口）。 |
| `scenes/play/PlaySession.tscn` | 根脚本由 ScenarioEngine.gd 改为 PlaySession.gd（保留 Sprint 1 的 RootMargin）。 |
| `project.godot` | 新增 `[gui] default_theme` 指向 `portrait_theme.tres`，补全 B1/B2 全局 CJK 默认字体接线。 |

### 新增测试（`tests/`，GUT，对齐 test-scaffolding §2.2/§2.3）
| 文件 | 用例 |
|---|---|
| `test_trigger_system.gd` | `test_cannot_enter_choice_before_identification`（D2）、`test_wrong_identification_plays_miss`（D3/E1）、`test_missing_miss_falls_back_no_crash`（E1 降级） |
| `test_consequence_engine.gd` | `test_force_boundary_routes_to_boundary`（E2/D6）、`test_relationship_signal_exposed_for_render`（E2 仅暴露） |

---

## 2. 跑测试（预期全绿）

环境与 Sprint 1 一致（Godot 4.3 + 字体二进制 + GUT 9.3+，见 `README_Sprint1.md`）：

编辑器内 `Project → Tools → GUT`（或 `Ctrl+Shift+G`）→ 选 `res://tests` → Run。
或 headless（CI 质量门，退出码 0 为通过）：

```bash
godot --headless --path . --rendering-driver opengl3 \
      --scene res://addons/gut/gut.tscn \
      -gdir=res://tests -gexit
```

本 Sprint **新增 2 个测试文件**（共 5 个用例），全部基于 `DataLoader.get_scenario("s01_scene_01"/"s04_scene_01")` 真实数据；不依赖字体二进制，可立即全绿。

> 注：`test_cjk_font`（Sprint 1）仍依赖字体文件存在；其余用例（含本 Sprint 全部）不依赖字体。

---

## 3. 状态机如何保证「S3 未完成不可抉择」与「识别错优先 miss」

- **S3 未完成不可抉择（D2/D3）**：`can_choose()` 直接返回 `TriggerSystem.trigger_correct`。`trigger_correct` 仅在 `submit(label)` 且 `label == triggers.correct` 时为真。`PlaySession` 仅在识别正确时才 `_enter_stage(S4_CHOICE)` 显示 ChoicePanel；识别错误则跳过 S4，直接 `_enter_stage(S5)` 播放 miss。`choose()` 也以 `can_choose()` 为前提守卫，API 层再兜底。
- **识别错优先 miss（方案A / G2）**：`ConsequenceEngine.resolve` 第一条规则——`not trigger_correct 且 triggers.miss != null` 时直接返回 `triggers.miss`（结构与 consequence 同构），由 S5 后果卡自行呈现「错位」质感（符号翻转 + 藤蔓退化 + 判词点明诊断顺序），**绝不给红叉 / 直接对错提示**（UX §3.2）。

---

## 4. forceBoundary 路由与 miss 回退实现要点

`ConsequenceEngine.resolve(scenario, chosen_choice_id, trigger_correct)` 顺序：

1. **方案A**：`not trigger_correct` 且 `triggers.miss` 存在 → 返回 `miss`（识别错优先）。
2. **forceBoundary**：`scenario.force_boundary == true` → 确定性返回 `boundary` 选项的 `consequence`（无论所选 type）。这是唯一引擎级确定性规则（ADR-004 / D6）。
3. **正常**：`chosen_choice_id != ""` → 返回所选 choice 的 consequence。
4. **降级兜底**：无 miss / 未选 → 返回首个 choice 的 consequence，保证非 null、不崩溃（E1 降级）。

**纯逻辑 Python 等价校验结论**（`/tmp/resolve_check.py`，跑真实 `s01_scene_01.json` / `s04_scene_01.json`）：
- s01 识别错（无选）→ 命中规则 1，返回 `triggers.miss.npc_reaction`（与 GUT 断言一致）。
- s04 `forceBoundary:true`，即便传入 `chosen="c1"`（skilled）且 `trigger_correct=true` → 命中规则 2，返回 `boundary`（c3）consequence，而非 c1。
- s01 识别错且移除 miss（降级路径）→ 命中规则 4，返回首个 choice（c1）consequence，非 null、不崩溃。
- s01 识别正确 + 选 c2（skilled）→ 命中规则 3，返回 c2 consequence（无 forceBoundary）。
校验全部通过，与 GDScript 实现逻辑一致。

---

## 5. 关系信号（relationshipSignal）处理（E2/E4 红项）

- `ConsequenceEngine` 不写任何存档；`relationship_signal` 仅作为返回 `Consequence` 的只读字段供 `ConsequenceStage` 渲染（符号 + 文字双编码）。
- `PlaySession` 仅在 `_resolved`（当次 consequence）中临时持有该信号，经 `current_relationship_signal()` 暴露给渲染层；**每次 `resolve_consequence` 重新计算，不跨场景累积，更不出盘**。
- 本 Sprint 无 `RunState` / `SaveManager`（`project.godot` 仍注释掉）。持久化断言（`SaveManager` 白名单禁写 relationshipSignal）留 Sprint 3。

---

## 6. 文本来源与硬编码自查

- **全部场景文案来自数据**：`context` / `npc.line` / `impulse` / `triggers.candidates` / `choices[].text` / `consequence.*` / `review.*` 均直接取自 `Scenario` 对象，无任何场景文案硬编码。
- **S6 复盘面板只读渲染**：`mechanism` / `case` / `migration` 全部来自 `scenario.review.*`；`review.case` 缺失时整段隐藏（A7 降级），从未补写任何案例文本。复盘语气用「X 身上发生过」式数据原文，无「你必须」口吻、无伦理批注（P2 已移除）。
- **UI 结构性文案（非场景内容，来自 UX 规格 §2 线框，非数据驱动字段）**：面板标题（「你看出这是什么处境？」/「你会怎么回应？」）、区段标题（机制/真实发生过/下次怎么做）、按钮文案（继续/再试一次/看看沟通洞察/下一场景/返回地图）、关系信号文字标签（关系升温/平稳/出现摩擦）。这些是本游戏 UI 固定 chrome，不在「场景文本」范畴；如需彻底数据化可后续由 `skills_index` / 本地化表驱动，但不影响本 Sprint 验收。我**未擅自补写任何场景级 / 复盘级文案**。

---

## 7. 本 Sprint 未实现（边界已留）

- **存档 / 导航 / 掌握度**：`SaveManager`（白名单禁写 relationshipSignal）、`RunState` Autoload、`SkillMap`、`MasterySystem` 属 E3/E4，后续 Sprint。
- **S8 地图**：`next_scenario()` 到末尾发 `all_done` 信号；真实地图 Sprint 3 接。
- **长文 ScrollContainer / 动态字号 / Reduce Motion / 深色模式**：复盘长文当前用 VBoxContainer 单列（C3 的 ScrollContainer 包裹留 E6 打磨）；其余可访问性基线见 UX §5，逐项落地留后续。
- **真机验证**：B3 真机中文 / C4 真机安全区（E6）。

---

## 8. `.tscn` 序列化无法本地验证的假设与提醒

沙箱无 Godot，无法 `godot --headless` 加载校验 `.tscn`/`.tres`。以下为**已知假设**，请用户在 Godot 4.3 打开工程后复核：

1. **`.tscn` 格式**：均按 Godot 4.3 `format=3` 手写，节点/属性名对照官方文档（Button `alignment` / `autowrap_mode`、VBoxContainer `layout_mode`、子场景 `instance=ExtResource(...)`、`anchors_preset=15`=FULL_RECT）。若某个属性名在 4.3 有出入，Godot 会忽略未知属性或报错——**首次打开请留意编辑器告警**。
2. **面板布局**：`PlaySession` 运行时把五个面板挂到 `StageRoot`（Control，full-rect），面板之间互斥 `visible`。`.tscn` 本身不含 StageRoot（由代码生成），故 `.tscn` 仅描述面板内部；布局正确性依赖 `_ensure_panels()` 的锚点设置。
3. **CJK 字体**：`portrait_theme.tres` 已通过 `project.godot` 设为默认主题，但字体二进制（`NotoSansSC-Regular.ttf`）缺失时 Godot 回退默认字体（中文暂为豆腐块），放入即生效（B1/B2）。
4. **RelationshipGlyph 实例**：`ConsequenceStage.tscn` 以 `[ext_resource type="PackedScene"]` + `instance=ExtResource(...)` 内嵌 `RelationshipGlyph.tscn`；其 `SymbolLabel`/`TextLabel` 子节点路径在 `PlaySession._apply_relationship_glyph` 中按名访问，命名需与 `.tscn` 一致（已对齐）。
5. **TagButton / ChoiceCard**：作为 `Button` 子类，文本经 `TriggerSystem`/`ChoiceSystem` 在 `load_scenario` 时动态写入（`"◌  " + candidate` / `"⬡  " + choice.text`）；`.tscn` 中的占位 `text` 仅为编辑器预览。
