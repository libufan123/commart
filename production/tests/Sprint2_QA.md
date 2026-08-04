# Sprint 2 QA 计划 · 烟雾测试评估 · Lean 质量门判定

> **QA Owner**：quality-lead（严守真）
> **阶段**：Phase 5 Sprint 2（E2/E3/E4-S1 实现完成后）
> **引擎/平台**：Godot 4.3 ｜ iOS/Android 竖屏 ｜ Lean
> **审对象**：`godot/scripts/systems/{TriggerSystem,ChoiceSystem,ConsequenceEngine,PlaySession}.gd` + 相关 `.tscn` + 新增 `godot/tests/{test_trigger_system,test_consequence_engine}.gd`
> **审阅方式**：静态审阅（本沙箱无 Godot 二进制，不能跑 GUT/真机；正确性依赖契约对照 + 工程说明 + 主理人 Python 等价校验结论）

---

## 0. 方法与声明（先读）

- ✅ **已对照**的上游契约：`production/tests/test-scaffolding.md`、`production/epics/垂直切片_EpicStory.md`、`design/ux/UX规格_垂直切片.md`、`docs/architecture/engin-architecture.md`、`design/gdd/垂直切片GDD_s01_s03_s04.md`、`godot/data/scenarios/s04_scene_01.json`、`godot/data/scenarios/s01_scene_01.json`。
- ⚠️ **本环境硬限制**：无 Godot、无 GUT、无真机。所有 `.tscn` 实例化、节点路径耦合、UI 渲染、真机中文/安全区 **都无法在本沙箱运行验证**。判定用语区分：
  - **已满足（静态）**：代码逻辑/接线对照契约逐条成立（仍受 P1-1 「未运行验证」约束）。
  - **存疑**：依赖运行期才能确认（节点存在性、视觉、真机）。
  - **未覆盖**：契约要求但本 Sprint 既无实现也无测试（设计内延迟或遗漏）。
- ✅ 主理人已做的 **Python 等价校验**：`ConsequenceEngine.resolve` 纯静态查表 / `forceBoundary` 确定性 / `miss` 优先与缺省回退逻辑，经 Python 等价实现独立复算结论一致 —— 下方「逻辑层」结论以该结论为可信佐证，「渲染/运行层」结论仍以静态审阅为本。

---

## 1. 本 Sprint 验收口径（对照 Stories 与 GDD §8）

### 1.1 Sprint 2 实现范围（来自工程简报）
| 模块 | 交付物 | 对应 Story |
|---|---|---|
| E2（S3 识别 + 闸门 + miss） | `TriggerSystem.gd` / `TriggerPanel.tscn` / `TagButton.tscn` / `PlaySession.gd` 硬闸门 / 识别错优先演出 `triggers.miss`（方案A） | E2-S2 / E2-S3 / E2-S4 |
| E3（S4 抉择 + S5 后果 + forceBoundary + 关系信号） | `ChoiceSystem.gd` / `ChoicePanel.tscn` / `ChoiceCard.tscn`（样式不标对错）/ `ConsequenceEngine.gd` / `ConsequenceStage.tscn` / `RelationshipGlyph.tscn`（纯静态查表）/ `forceBoundary` 确定性路由（仅 s04）/ `relationshipSignal` 仅渲染不持久化 | E3-S1 / E3-S2 / E3-S3 / E3-S4 |
| E4-S1（S6 复盘只读渲染） | `ReviewPanel.tscn`（mechanism/case/migration 来自数据，case 缺失降级；再练/下一/返回按钮） | E4-S1 |
| 新增测试 | `test_trigger_system.gd`(3) / `test_consequence_engine.gd`(2) | — |

### 1.2 GDD §8 八条验收在本 Sprint 的归属
| GDD §8 条 | 本 Sprint 是否可判定 | 备注 |
|---|---|---|
| (1) 可玩闭环 | 存疑 | 代码路径齐全，但无端到端测试 + 未运行 |
| (2) P3 闸门有效 | 已满足（测试覆盖） | 硬闸门 + miss 优先 |
| (3) 陷阱真实（文案） | 不在本 QA 静态范围 | 内容评审项，标注待 design 评审 |
| (4) P1 不说教（语气） | 不在本 QA 静态范围 | 内容/文案评审项 |
| (5) 边缘覆盖 E1/E2/E3 | 部分 | E1/E2 已覆盖；E3 安全失败未显式覆盖 |
| (6) 数据驱动 | 已满足 | 无硬编码文案 |
| (7) 轻量反馈 / 关系信号仅展示不持久化 | 部分 | 渲染侧满足；持久化端到端未验证 |
| (8) 竖屏可达 | 存疑 | 布局用 Container；未运行/真机 |

---

## 2. 静态审阅结论（逐条：已满足 / 存疑 / 未覆盖）

> 判定基准：代码对照 Epic Story 验收 + 控制清单（D2/D3/D4/D5/D6/D7/D8、E1/E2/E4、A7）+ GDD §8。

### 2.1 E2 · S3 识别 + 硬闸门 + miss 演出
| Story 验收 | 工程落点 | 结论 |
|---|---|---|
| E2-S2：渲染 `triggers.candidates` 为 `TagButton[]` | `TriggerSystem._rebuild()`（L33-44）遍历候选实例化 TagButton | ✅ 已满足（静态） |
| E2-S2：点选判定 `selected == correct` | `TriggerSystem.submit()`（L52-56） | ✅ 已满足 |
| E2-S2：派生「解锁选项集」 | `TriggerSystem.unlocked_choice_ids()`（L60-68）返回全部 choice id；闸门语义保留 | ✅ 已满足（本切片全解锁，符合架构注释） |
| E2-S3：S2→S3→S4→S5→S6 顺序、一次一屏 | `PlaySession._enter_stage()` visible_map（L247-258） | ✅ 已满足 |
| E2-S3：**未识别前 ChoicePanel 不可交互（D2 硬闸门）** | `PlaySession.can_choose()` 返回 `trigger_correct`（L183-186）；`choose()` 前置 `if not can_choose(): return false`（L191） | ✅ 已满足 + 测试覆盖 |
| E2-S4：识别错**优先**演出 `triggers.miss`（方案A） | `ConsequenceEngine.resolve` 第 1 步（L24-26）；`PlaySession._on_trigger_submitted` 错误分支直接 `resolve_consequence()`（L261-266） | ✅ 已满足 + 测试覆盖 |
| E2-S4：`miss` 缺省回退所选 consequence（E1 降级） | `resolve` 兜底（L40-45）；识别错路径 chosen_id 恒空→回退首 choice | ✅ 已满足 + 测试覆盖 |
| E2-S4：识别正确不受影响（正常查表） | `resolve` 顺序：正确→跳 miss→（s01 无 forceBoundary）→取所选 consequence（L34-38） | ✅ 已满足 |

### 2.2 E3 · S4 抉择 + S5 后果 + forceBoundary + 关系信号
| Story 验收 | 工程落点 | 结论 |
|---|---|---|
| E3-S1：选项文本来自 `choices[].text` | `ChoiceSystem._rebuild()`（L31-45） | ✅ 已满足 |
| E3-S1：**样式不标 type**（无主导策略） | `ChoiceCard` 文本 `"⬡  "+c.text`，不渲染 type 名；`type` 仅引擎透传 | ✅ 已满足（静态；视觉需真机确认无暗示） |
| E3-S1：捕获 `chosen_choice_id/type` 仅内存 | `ChoiceSystem.choose()`（L53-63）写本地字段；`PlaySession` 注释「RunState Autoload 未注册，状态本地持有，不跨场景/不出盘」（L8-11） | ✅ 已满足 |
| E3-S2：纯静态查表、无分支/随机（D5/ADR-004） | `ConsequenceEngine.resolve` 纯查表（L20-45） | ✅ 已满足 |
| E3-S3：**forceBoundary==true 确定性路由 boundary（D6）** | `resolve` 第 2 步（L28-32），先于所选 consequence；数据 `s04_scene_01.json` `"forceBoundary": true` + `c3(type=boundary)` 存在 | ✅ 已满足 + 测试覆盖 |
| E3-S4：取 `relationshipSignal` 仅供 `RelationshipGlyph` 渲染（-/0/+） | `PlaySession._apply_relationship_glyph()`（L301-320）设 SymbolLabel/TextLabel | ✅ 已满足（渲染侧） |
| E3-S4：渲染后**不写 RunState 持久字段、不出盘** | `_resolved` 为 `PlaySession` 本地 var；`current_relationship_signal()` 只读（L216-219）；无处写盘 | ⚠️ 已满足（渲染侧）/ **未覆盖（出盘端到端，见 2.4）** |
| E3-S5：**连续两次选 trap 安全失败（D8）** | 无封锁/扣分/冷却机制存在（stateless）→ **架构性隐含满足**；但无显式特性实现、无测试 | ⚠️ 隐含满足（架构）/ **未覆盖（缺 D8 测试）** |

### 2.3 E4-S1 · S6 复盘只读渲染
| Story 验收 | 工程落点 | 结论 |
|---|---|---|
| 渲染 `review.mechanism` + `review.migration` | `PlaySession._render_review()`（L324-342）MechanismLabel/MigrationLabel | ✅ 已满足（静态接线） |
| `review.case` 存在则渲染、缺失则跳过（A7 降级） | `CaseSection.visible = not review.case.is_empty()`（L341-342） | ✅ 已满足（静态；需测试/烟雾固化） |
| 再练/下一按钮触发状态机跳转 | `ReplayButton→replay_current`、`NextButton→next_scenario`、`MapButton→_on_return_map`（L143-154） | ✅ 已满足 |
| `ReviewPanel.tscn` 节点与 `.gd` 引用一致 | 核对 `.tscn`：SkillLabel/MechanismLabel/CaseSection/CaseLabel/MigrationLabel/ReplayButton/NextButton/MapButton 全部命中 | ✅ 已满足（静态） |

### 2.4 关系信号「仅渲染不持久化」端到端（E2/E4 红项）
- **渲染侧**：`relationshipSignal` 仅从 `_resolved` 取出供 `RelationshipGlyph` 渲染，渲染后即弃，无落盘路径 —— 静态审阅成立。
- **出盘侧（白名单）**：`SaveManager` 本 Sprint **未实现**；`test-scaffolding.md` §2.3 B 要求的「`relationshipSignal` 禁出盘」断言在本 Sprint 的 `test_consequence_engine.gd` 中**被显式推迟到 Sprint 3 SaveManager**（测试文件头注释 L2-3）。
- **结论**：E2/E4 红项**本 Sprint 不能宣告清零**。属设计内延迟（SaveManager 在 Sprint 3），但必须在 Sprint 3 以「白名单写入断言」端到端关闭 —— 列为 **CONCERN-1 / 关键**。

---

## 3. 测试用例覆盖评估（对齐 test-scaffolding §2.2/§2.3）

### 3.1 已交付测试 vs 契约条目
| 控制清单项 | 对应契约测试 | 实际测试 | 覆盖 |
|---|---|---|---|
| D2 硬闸门 | §2.2 A | `test_cannot_enter_choice_before_identification` | ✅ |
| D3 miss 演出（方案A/E1） | §2.2 B | `test_wrong_identification_plays_miss` | ✅ |
| E1 miss 缺省回退 | §2.2 C | `test_missing_miss_falls_back_no_crash` | ✅ |
| E2/D6 forceBoundary 确定性路由 | §2.3 A | `test_force_boundary_routes_to_boundary` | ✅ |
| E2 关系信号仅渲染 | §2.3 B（部分） | `test_relationship_signal_exposed_for_render` | ⚠️ 仅渲染可见（≠0），**持久化断言未做** |

### 3.2 测试用例假设核对（防止「测试绿但假设错」）
- `test_trigger_system` 用 `s01_scene_01`：`triggers.correct == "我正想批评 / 对方在防御"`、`triggers.miss` 存在 —— ✅ 数据核对一致。
- `test_consequence_engine` 用 `s04_scene_01`：`forceBoundary:true`、含 `c3(type=boundary)`、`resolve(scen,"c1",true)` 应路由到 `c3.consequence` —— ✅ 数据核对一致（脚手架 §2.3 A 原假设的 `c_skilled` 实际为 `c1`，已对齐真实数据）。
- `test_relationship_signal_exposed_for_render` 选 `c1`（s01 `c1` type=trap，`relationshipSignal:-1`）→ 断言 `≠0` —— ✅ 数据核对一致（-1）。

### 3.3 覆盖缺口（需 Sprint 3 补）
1. **D8 / E3-S5 安全失败**：无 GUT 断言。「连续两次选 trap 后果照常、不封锁不扣分、重练无冷却」目前仅靠 stateless 架构隐含满足，无显式固化。→ **用户提问的「连续两次选 trap 安全失败」本 Sprint 已实现吗？答：作为独立特性未专门实现，也无测试；但因本切片无任何封锁/扣分/冷却机制，该条被架构性「真空满足」，需补断言固化。**
2. **E2/E4 持久化白名单断言**：`test_save_manager.gd` 未交付（SaveManager 在 Sprint 3）。§2.3 B 的出盘断言整体缺失。
3. **A7 运行时降级断言**：`ReviewPanel` 的 case 缺失降级（`CaseSection.visible`）已有代码，但无 `PlaySession`/`ReviewPanel` 级 GUT 断言（脚手架 §2.1 C 的 `test_validator_missing_review_case_degrades` 是 Validator 层，非运行时渲染层）。
4. **test_play_session.gd（六屏状态机烟雾）**：脚手架 §1.3 列为 E6 测试，本 Sprint **未交付**。S2→S6 流转、`next_scenario` 推进、`replay_current` 重置均无条件自动断言。
5. **relationshipSignal 双编码完整性**：§5 C 还要求 「藤蔓形态（光秃/抽芽/开花）」，仅符号+文字已满足下限，但藤蔓形态未实现（见风险 P2-2）。

---

## 4. 真机 / CI 无法在本环境验证的声明（carry-over）

以下条目**本沙箱无法验证**，列为 Sprint 2 之后的 carry-over，最终须在 E6 清零：

| 项 | 类型 | 为何本 Sprint 无法验证 | 后续归属 |
|---|---|---|---|
| **B3 真机中文渲染** | 红·真机（E6-S2） | 无真机/iOS-Android 构建 | E6-S2 真机 smoke |
| **C4 真机安全区** | 红·真机（E6-S3） | 无真机；`UIAdapter.apply_safe_area` 仅适配器就位 | E6-S3 真机验证 |
| **E2/E4 存档白名单（禁出盘）** | 红·评审卡点 | `SaveManager` 在 Sprint 3 | Sprint 3 + E4-S4 |
| **.tscn ↔ .gd 节点路径耦合** | 运行期隐患（P1-1） | 无 Godot 运行；所有 `get_node_or_null` 有 null 守卫，**缺失节点会静默不渲染而不崩溃** | 工程环境跑一次 GUT 全绿 + 编辑器开六屏 |
| **CJK 字体 / 主题继承** | 红·B1/B2（E0-S2） | 无运行；`portrait_theme.tres` 指向需编辑器确认 | E6（已 Sprint 1 落地，待真机） |
| **六屏视觉 / 竖屏单屏可达** | GDD §8(8) | 无运行/真机 | E6-S1 |

---

## 5. Bug / 风险分级（静态发现）

> 未发现「契约逻辑矛盾」级 P0。以下为 P1/P2。

### P0（封锁）—— 无

### P1（高）
- **P1-1 · `.tscn` ↔ `.gd` 节点路径耦合未运行验证**：`PlaySession` 引用 `$TagList`/`$ChoiceList`/`NpcReactionLabel`/`JudgementLabel`/`RelationshipGlyph/SymbolLabel`/`RelationshipGlyph/TextLabel` 等。全部经 `get_node_or_null` 且 null 守卫，故节点缺失**不会崩溃，只会静默不渲染**。此类问题只能靠 Godot 编辑器/headless GUT/真机发现。**必须在工程环境跑一次 GUT 全绿 + 打开六屏确认节点存在。**
- **P1-2 · E2/E4 持久化端到端未验证**：本 Sprint 仅断言「渲染可见 ≠0」，完全未做任何「禁出盘白名单」断言（`SaveManager` 在 Sprint 3）。E2/E4 红项不能在本 Sprint 清零。

### P2（中）
- **P2-1 · `PlaySession.choose()` 双重解析**：`choose()`（L190-196）先调 `_choice_panel.choose()`（该调用 emit `chosen` → 已连 `_on_choice_chosen` → `resolve_consequence()` #1），随后又显式 `resolve_consequence()` #2。功能上幂等无害，但冗余且**测试路径解析两次 / UI 路径解析一次**，行为不一致；后续若 `resolve` 加副作用会双触发。建议合并为单路径（仅 signal 触发或仅显式调用其一）。
- **P2-2 · `RelationshipGlyph` 仅符号+文字，缺藤蔓形态**：`RelationshipGlyph.tscn` 仅有 `SymbolLabel`+`TextLabel`；UX §3.2「可感知错位」与 §5 C「关系温度用藤蔓形态（光秃/抽芽/开花）而非红绿」的**形态承重**未实现。Standard 色盲兜底下限（符号+文字双编码）已达；藤蔓形态属 UX 额外意图。**建议 Sprint 3/art 补实现，或在主理人处显式记为 Lean 延后。**
- **P2-3 · 缺 `test_play_session.gd` 六屏状态机烟雾**：S2→S6 流转、再练/下一/返回地图均无自动断言。
- **P2-4 · 缺 D8 安全失败 + A7 运行时降级断言**：见 §3.3。

---

## 6. Lean 质量门判定

# 🚦 判定：**CONCERNS（带条件可进入 Sprint 3）**

**理由**：
- 无 P0；Sprint 2 核心逻辑（D2 硬闸门、D3 miss 优先、E1 miss 缺省回退、D6 forceBoundary 确定性、E3-S1/S4 渲染接线、E4-S1 复盘降级）**全部静态满足且被 GUT 测试覆盖**，并经主理人 Python 等价校验佐证。
- 但存在**设计内延迟 + 环境限制**导致无法在本 Sprint 宣告「完成」：
  1. E2/E4 持久化端到端未验证（SaveManager 在 Sprint 3）——红项不能清零；
  2. 真机/编辑器运行项（B3/C4/节点耦合/字体/竖屏）本环境一律不可验证；
  3. 关系信号「藤蔓形态」UX 意图部分未满足（P2-2）。

**Lean 下允许 CONCERNS 带条件进入下一 Sprint**，条件如下（见 §7）。

---

## 7. Sprint 3 必须补的 QA 条目（强制条件）

> 以下为把本 Sprint CONCERNS 闭环、并支撑 E4-S4/E6 红项清零的硬性待办；其中 E2/E4 持久化断言、E3-S5 安全失败、真机 smoke 为主理人点名的三项。

1. **【E2/E4 持久化断言 · 主理人点名】** 落地 `SaveManager` + `test_save_manager.gd`：断言存档结构仅含 `{saveVersion, mastery, visited, settings}`；读取 `user://save_v1.json` 断言**不含 `relationshipSignal`、不含任何 S9 字段**（白名单写入，非黑名单）。关闭 E2/E4 红项端到端。
2. **【真机/编辑器 smoke · 主理人点名】** 在工程环境（非本沙箱）跑一次 `godot --headless` GUT 全绿，并在编辑器打开六屏确认所有 `.tscn` 节点路径与 `.gd` 引用一致（关闭 P1-1 静默不渲染风险）。B3 真机中文 + C4 真机安全区仍须 E6-S2/S3 真机证据。
3. **【E3-S5 安全失败 · 主理人点名】** 补 D8 GUT 断言：同场景连续两次选 trap → 后果一致、复盘照常、不封锁不扣分、重练无冷却（固化架构性隐含满足）。
4. **【六屏状态机烟雾】** 补 `test_play_session.gd`：S2→S3→S4→S5→S6 全流程 + `replay_current`/`next_scenario`/`_on_return_map` 跳转断言。
5. **【A7 运行时降级】** 补 `ReviewPanel` case 缺失降级（`CaseSection.visible=false`）的 `PlaySession` 级断言。
6. **【代码异味】** 修 `PlaySession.choose()` 双重解析（P2-1），合并为单路径。
7. **【UX 决策】** `RelationshipGlyph` 藤蔓形态：补实现 or 主理人显式记为 Lean 延后（P2-2）。

---

## 附录 A · 一句话汇总给主理人
Sprint 2 的**逻辑契约全部达成且测试对齐**，可带条件进入 Sprint 3；阻断项为**环境不可验证（真机/运行）**与**设计内延迟（SaveManager 在 Sprint 3）**，无 P0、无逻辑矛盾。CONCERNS 的三大强制条件是：**E2/E4 持久化白名单断言**、**真机/编辑器 smoke**、**E3-S5 安全失败断言**。
