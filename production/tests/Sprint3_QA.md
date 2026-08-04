# Sprint 3 QA 收口 · Lean 质量门判定（垂直切片出口）

> **QA Owner**：quality-lead（严守真）
> **阶段**：Phase 5 Sprint 3（E4-S2/S3/S4/S5 + E6 集成）实现完成后
> **引擎/平台**：Godot 4.3 ｜ iOS/Android 竖屏 ｜ Lean
> **审对象**：`godot/scripts/{autoload/SaveManager,core/MasterySystem,ui/SkillMap,ui/MainMenu,systems/PlaySession}.gd` + 对应 `.tscn` + 新增 `godot/tests/{test_save_manager,test_play_session,test_mastery}.gd` + `godot/project.godot`
> **审阅方式**：静态审阅（本沙箱无 Godot 二进制、无 GUT、无真机；正确性依赖契约对照 + 工程说明 + 主理人 Python 等价校验结论）

---

## 0. 方法与声明（先读）

- ✅ **已对照**上游契约：`production/epics/垂直切片_EpicStory.md`（E4-S2/S3/S4/S5、E6、红项关闭条件）、`production/tests/test-scaffolding.md`（§1.3 / §2.2 / §2.3）、`production/Sprint2_收口与门判定.md`（§5 Sprint 3 预览、§3 CONCERNS）、`production/tests/Sprint2_QA.md`（§7 强制 QA 1–7）、`docs/architecture/engin-architecture.md`（§3 / §5 / §6.2 / §6.3 / §6.4）、`docs/architecture/control-list.md`（红项全表）、`design/ux/UX规格_垂直切片.md`（§4 导航/进度、§5 可访问性）。
- ✅ **已核对工程资产**：`godot/data/` 下 5 场景 JSON + `skills_index.json` 均存在且结构正确；`portrait_theme.tres` 已正确引用 `res://assets/fonts/NotoSansSC-Regular.ttf`；`project.godot` 的 `main_scene` 已改 `MainMenu.tscn`、`SaveManager` 已注册 autoload、`default_theme` 已指向主题。
- ⚠️ **本环境硬限制**：无 Godot、无 GUT、无真机。所有 `.tscn` 实例化、节点路径耦合、UI 渲染、真机中文/安全区 **都无法在本沙箱运行验证**。判定用语区分：
  - **已满足（静态）**：代码逻辑/接线对照契约逐条成立（仍受「未运行验证」约束）。
  - **存疑**：依赖运行期才能确认（节点存在性、视觉、真机）。
  - **未覆盖**：契约要求但本 Sprint 既无实现也无测试（设计内延迟或遗漏）。
- ✅ 主理人已做的 **Python 等价校验**（`resolve_check.py`，跑真实 `s01_scene_01.json` / `s04_scene_01.json`）结论已采用：S3→miss 优先、forceBoundary 确定性路由、miss 缺省回退、关系信号取值全部 PASS。本 Sprint 的 `ConsequenceEngine` 逻辑未改动（六屏状态机未动），该结论继续有效。
- ✅ 本环境**未跑 godot**，所有结论为静态审阅 + 契约对照 + 既有校验结论，最终需在用户侧真机/headless GUT 跑证。

---

## 1. 本 Sprint 验收口径（对照 Stories 与 GDD §8）

### 1.1 Sprint 3 实现范围
| 模块 | 交付物 | 对应 Story |
|---|---|---|
| E4-S2/S3 导航 S8 | `SkillMap.gd`/`.tscn`（读 `skills_index` 渲染 s01/s03/s04、visited 标记）+ `MainMenu.gd`/`.tscn`（开始/继续） | E4-S2 / E4-S5 |
| E4-S3 掌握度 S7 | `MasterySystem.gd`（0–3 档、replay 递增、无惩罚、单调不降级） | E4-S3 |
| E4-S4 轻量存档 | `SaveManager.gd`（白名单写入 + 双层 sanitize，关 E2/E4 红项） | E4-S4 |
| E6 集成测试 | `test_save_manager.gd` / `test_play_session.gd` / `test_mastery.gd` | E6 |
| PlaySession 修复 | `_on_choice_chosen` 置 `pass`，resolve 仅在 `choose()` 内单次显式调用（修 Sprint2 QA §7-6 双重解析） | E4-S1 收尾 |

### 1.2 控制清单红项归属（本 Sprint 关闭责任）
- **E2 / E4**：由 `SaveManager` 白名单 + 双层 sanitize 端到端关闭（渲染侧 Sprint 2 已就位，本 Sprint 补出盘侧 + 断言）。
- **B1 / B2 / C4**：实现期在更早 Sprint 落地（字体主题引用、安全区适配器已就位），本 Sprint 仅做继承与接线复核；真机验证 carry-over。
- **A4 / A6–A10**：数据层在 Sprint 1/2 落地，本 Sprint 继承，无改动。

### 1.3 GDD §8 八条验收在本 Sprint 的可判定性
| GDD §8 条 | 本 Sprint 结论 | 备注 |
|---|---|---|
| (1) 可玩闭环 | 已满足（静态） | 导航→场景→六屏→返回链路代码齐全；运行期待 GUT/编辑器确认 |
| (2) P3 闸门有效 | 已满足（测试覆盖，继承 Sprint 2） | S3 未识别不可抉择 |
| (3) 陷阱真实（文案） | 不在本 QA 静态范围 | 内容评审项，待 design 评审 |
| (4) P1 不说教（语气） | 不在本 QA 静态范围 | 内容评审项 |
| (5) 边缘覆盖 E1/E2/E3 | 已满足（测试覆盖） | D8 安全失败、A7 降级、miss 缺省均补测试 |
| (6) 数据驱动 | 已满足 | SkillMap 技能名取自数据；无硬编码场景文案 |
| (7) 轻量反馈 / 关系信号仅展示不持久化 | 已满足（端到端） | E2/E4 白名单断言落地 |
| (8) 竖屏可达 | 存疑 | Container 布局；未运行/真机 |

---

## 2. 静态审阅结论（逐条：已满足 / 存疑 / 未覆盖）

> 判定基准：代码对照 Epic Story 验收 + 控制清单（F1/F2/F3、E2/E4、A7）+ GDD §8。

### 2.1 E4-S2/S3 · 导航 S8 + 进度标记（F1/F3）
| Story 验收 | 工程落点 | 结论 |
|---|---|---|
| `SkillMap` 读 `skills_index.json` 渲染 s01/s03/s04 入口 | `SkillMap._build_entries()`（L36-48）遍历 `DataLoader.get_skills_index()["skills"]`，按 section/order 排序；`skills_index.json` 实测含三技能 ✅ | ✅ 已满足（静态） |
| 技能名强制取自数据（硬约束） | `_add_entry` 取 `skill.get("title")`，缺省占位「技能入口」仅兜底（L65） | ✅ 已满足 |
| visited 标记在地图小标记显示 | `_refresh_markers()`（L81-105）读 `SaveManager.get_visited()` + `_mastery.get_mastery`，hex 标记 ◈/◷ | ⚠️ 已满足（静态接线）/ **见 §6 P1（记录侧漏记）** |
| 元数据走独立索引不污染场景 Schema（F3） | 仅消费 `skills_index`，不碰场景 Schema 字段 | ✅ 已满足 |
| 点入口启动该技能首场景 | `_start_skill()`（L120-144）：`external_boot=true` → `load_scenario(first_id)` | ✅ 已满足（静态） |
| `all_done` 回地图 + mark_visited + record_mastery | `_on_session_done()`（L148-161） | ⚠️ 接线存在但**仅记录入口场景（P1）** |
| `MainMenu` 开始/继续 + 无存档禁用继续 | `MainMenu._ready`：`ContinueButton.disabled = not SaveManager.has_save()`（L20） | ✅ 已满足（静态） |
| `MainMenu` 进地图（开始=继续均进地图，Lean） | `_enter_map()`（L27-36） | ✅ 已满足 |

### 2.2 E4-S3 · 轻量掌握度 S7（F2，GDD §4.2）
| Story 验收 | 工程落点 | 结论 |
|---|---|---|
| 仅 0–3 档，无 meter/数值压力 | `MasterySystem.mastery_for_skill` clamp(0,3)；地图仅 hex 标记 | ✅ 已满足（静态） |
| replay 累加、无惩罚、单调不降级 | `record_scenario`：`new_lvl = clamp(max(computed, persisted),0,3)`（L52），含 skilled 保底 | ✅ 已满足（静态）+ 测试覆盖 |
| 跨技能不串扰 | `_records` 按 scenario_id 隔离；`mastery` 按 skill_id 隔离 | ✅ 已满足 + 测试覆盖 |
| 结果入 `SaveManager.mastery`（白名单键） | `SaveManager.set_mastery` → `_data["mastery"]` | ✅ 已满足（静态） |

### 2.3 E4-S4 · SaveManager 轻量存档 + 禁持久化（E2/E4 红项）
| Story 验收 | 工程落点 | 结论 |
|---|---|---|
| 存档 = `{saveVersion, mastery, visited, settings}` → `user://save_v1.json` | `SaveManager._empty()` / `_write()`（L30-31, L123-130） | ✅ 已满足（静态）+ 测试覆盖 |
| 不含 `relationshipSignal` / 任何 S9 字段（白名单，非黑名单） | `ALLOWED_KEYS`（L20）+ `_sanitize` 双重保险（载入 L64、落盘 L128 各一次） | ✅ 已满足（静态）+ 测试覆盖 |
| `saveVersion` 带版本号，与 `schemaVersion` 解耦 | `SAVE_VERSION := 1`（L15），独立于数据 schema | ✅ 已满足 |
| 读写失败静默降级（不崩溃） | `load_save`/`_write` 全 null 守卫（L53-64, L124-127） | ✅ 已满足（静态） |
| 已注册 autoload + main_scene 改 MainMenu | `project.godot` `[autoload] SaveManager=...`（L31）、`main_scene=MainMenu.tscn`（L9） | ✅ 已满足（静态已核对） |

### 2.4 PlaySession §E 修复（Sprint 2 QA §7-6 双重解析）
| 验收 | 工程落点 | 结论 |
|---|---|---|
| `choose()` 内单次显式 `resolve_consequence()` | `choose()`（L201-207）调用 `resolve_consequence()` 一次 | ✅ 已满足（静态） |
| `_on_choice_chosen` 不再二次解析 | `func _on_choice_chosen(...) -> void: pass`（L283-284），signal 仅保留埋点扩展位 | ✅ 已满足（静态） |
| 测试/UI 路径行为一致（幂等单次） | resolve 仅此一处触发，漏接测试路径不再双触发 | ✅ 已满足（静态） |

### 2.5 小结
- **已满足（静态）**：导航接线、技能名取自数据、visited 标记渲染、掌握度 0–3 / replay / 无串扰、白名单存档 + 双层 sanitize、双重解析修复、main_scene/autoload 接线。
- **存疑**：visited/mastery **实际落盘值正确性**（受 §6 P1 影响）、`.tscn↔.gd` 节点耦合运行期、真机中文/安全区/竖屏。
- **未覆盖**：藤蔓三态（Lean 延后，见 §5）。

---

## 3. Sprint 2 QA §7 七条强制项关闭确认

> 对照 `production/tests/Sprint2_QA.md` §7 主理人点名的三项 + 其余四项。

| # | Sprint 2 强制项 | 本 Sprint 处置 | 状态 |
|---|---|---|---|
| 1 | **E2/E4 持久化断言**（主理人点名） | `test_save_manager.gd`：`test_sanitize_strips_forbidden_keys` + `test_save_state_no_forbidden_on_disk` + `test_mastery_clamped` + `test_mark_visited_dedup`，断言存档仅白名单键、磁盘无 `relationshipSignal`/无 S9 字段 | ✅ **已关闭**（代码+测试；端到端运行待 GUT） |
| 2 | **真机/编辑器 smoke**（主理人点名） | 代码层面全部就位；运行期验证须用户侧 `godot --headless` GUT 全绿 + 编辑器开六屏确认节点耦合 | ⏭ **延后 / carry-over**（环境限制） |
| 3 | **E3-S5 安全失败断言**（主理人点名） | `test_play_session.gd::test_double_trap_safe_failure`：连续两次选 trap → 后果一致、复盘照常、不封锁不扣分、重练无冷却 | ✅ **已关闭**（测试覆盖） |
| 4 | 六屏状态机烟雾 | `test_play_session.gd::test_six_stage_state_machine_smoke`：S2→S4→S5→S6→再练→下一→all_done 全流转 | ✅ **已关闭**（测试覆盖） |
| 5 | A7 运行时降级 | `test_play_session.gd::test_review_case_missing_hides_section`：`review.case` 缺失 → `CaseSection.visible=false` | ✅ **已关闭**（测试覆盖） |
| 6 | 修 `choose()` 双重解析 | `_on_choice_chosen` 置 `pass`，resolve 仅 `choose()` 内单次 | ✅ **已关闭**（静态确认） |
| 7 | 藤蔓三态：补 or 显式延后 | 仅符号+文字双编码（达色盲下限）；藤蔓形态（光秃/抽芽/开花）未实现 | ⏭ **延后 / Lean 延后（carry-over）** |

**结论**：§7 七条强制项中，4 条已关闭（含主理人点名 1、3），2 条测试化关闭（1 的断言、6 的修复），1 条 Lean 延后（藤蔓），1 条环境性 carry-over（真机 smoke）。**无遗留未处置项**；真机 smoke 与藤蔓属预期 carry-over。

---

## 4. 测试用例覆盖评估（对齐 test-scaffolding §1.3 / §2.2 / §2.3）

### 4.1 三个新测试 vs 红项 / 边缘覆盖
| 控制清单项 | 测试 | 覆盖 |
|---|---|---|
| E2/E4 禁出盘（白名单） | `test_save_manager` ×4 | ✅ 覆盖（sanitize / 落盘 / 钳制 / 去重） |
| E2/E4 存档干净集成 | `test_mastery::test_save_stays_whitelist_clean` | ✅ 覆盖（record 后存档仅白名单键 + visited 记录） |
| S7 掌握度（0–3 / replay / skilled / 不串扰） | `test_mastery` ×5 | ✅ 覆盖 |
| D8 安全失败（E3-S5） | `test_play_session::test_double_trap_safe_failure` | ✅ 覆盖 |
| A7 运行时降级 | `test_play_session::test_review_case_missing_hides_section` | ✅ 覆盖 |
| 六屏状态机（E6） | `test_play_session::test_six_stage_state_machine_smoke` | ✅ 覆盖（S2→S6 + 再练/下一/all_done） |

### 4.2 关键依赖核对（防「测试绿但假设错」）
- `test_play_session` 用真实数据 id：`_skilled_id`/`_trap_id` 取自 `scen.choices[].type`，`triggers.correct` 取自 `scen.triggers.correct` → 与 `s01_scene_01.json` 实测一致 ✅。
- `test_review_case_missing_hides_section` 用 `DataLoader.load_dict("res://data/scenarios/s01_scene_01.json")` 改 `review.case=""` → `Scenario.new(d)` 构造 → 断言 `StageRoot/ReviewPanel/CaseSection.visible==false`。`DataLoader.load_dict` 实测存在（L49）✅；`Scenario.new(d)` 与 `DataLoader._load_and_cache` 同构 ✅。
- `test_mastery` 依赖 `skills_index.json` 存在且含 `s01-shake-the-hive` 的 `scenes[]`：实测 `skills_index.json` 包含且结构正确 ✅ → `_scenarios_of` 能返回正确场景列表，测试前提成立。

### 4.3 覆盖缺口（须 Phase 6/7 补）
1. **导航接线 + visited/mastery 记录路径未测**：3 个新测试均直接 `PlaySession.new()` 或 `MasterySystem.new()`，**未经过 `SkillMap._on_session_done` 的真实链路**（external_boot → all_done → mark_visited/record_scenario）。本 Sprint 最关键的 P1 缺陷（§6）恰好潜伏在此未被测试覆盖的路径。→ 须补 `test_skillmap_navigation.gd`：模拟从地图进技能、play 完多场景、断言 `SaveManager.visited` 含全部已玩场景、`mastery` 正确累加。
2. **`external_boot` 防冲突无断言**：仅静态确认，无测试验证「`external_boot=true` 时 `_ready` 不自动 load」。→ 补一个 `assert`：实例化后 `_stage` 仍为初始、未自动进入 S2。
3. **B1/B2 字体存在性断言 `test_cjk_font.gd`**：脚手架 §2.4 已定义，但**字体二进制当前缺失**（`assets/fonts/` 仅 README），该测试**当前会被预期失败**。放置字体后即绿。→ 用户侧资产动作（非代码缺陷）。
4. **真机/竖屏/安全区**：无自动化测试可在此环境跑，依赖 E6-S2/S3 真机证据。
5. **藤蔓三态**：无测试（Lean 延后）。

---

## 5. 红项全表最终清零复核（核心判定依据）

> 来源：`docs/architecture/control-list.md` 红项全表 A4/B1/B2/B3/C4/E2/E4 + 绿项 A6–A10。
> 状态语义：**实现期已关闭** = 代码/资产就位，待真机/CI 复核；**carry-over** = 须用户侧真机或 headless GUT 跑证（Lean 下不阻塞交付）；**延后** = 显式 Lean 延后。

### 5.1 工程实现期已关闭（代码具备，待真机/CI 复核）
| 红项 | 含义 | 工程落点 | 状态 |
|---|---|---|---|
| **A4** | UTF-8 BOM 剥离 | `DataLoader._parse_bytes`（L111-113）字节级 `EF BB BF` 检测 + `slice(3)` | ✅ 实现期已关闭 |
| **B2** | `default_font` 指向 CJK | `project.godot` `default_theme=portrait_theme.tres`；`portrait_theme.tres` `default_font=ExtResource(NotoSansSC-Regular.ttf)`（引用就位） | ✅ 实现期已关闭（**引用**；依赖 B1 资产生效） |
| **C4** | 安全区适配器 | `ui_adapter.gd::UIAdapter.apply_safe_area`（static）已实现，并在 `MainMenu`/`SkillMap`/`PlaySession` `_ready` 单点接入 | ✅ 实现期已关闭（适配器） |
| **E2** | 关系信号仅渲染不持久化 | 渲染侧 Sprint 2 就位 + 出盘侧 `SaveManager` 白名单 + 双层 sanitize | ✅ 实现期已关闭 |
| **E4** | 代码评审确认禁出盘 | `SaveManager` 白名单 + `_sanitize`（载入 L64、落盘 L128）+ `test_save_manager` 断言 | ✅ 实现期已关闭（评审卡点经测试固化） |
| **A6/A7/A8/A9/A10** | 数据层校验/降级/单一入口 | `ScenarioValidator`/`DataLoader`（Sprint 1/2 落地，本 Sprint 继承） | ✅ 实现期已关闭 |

### 5.2 必须真机/CI 验证（carry-over，Lean 下不阻塞交付但须列出）
| 红项 / 项 | 类型 | 现状 | 后续归属 |
|---|---|---|---|
| **B1** CJK 字体导入（二进制） | 红·资产 | ❗ **`.ttf` 二进制缺失**（`assets/fonts/` 仅 README_字体.md）；`portrait_theme.tres` 已正确引用路径，但文件未放置 → 放置前 `default_font` 为 null，中文真机将豆腐块 | **用户侧放置 `NotoSansSC-Regular.ttf` 后即生效**（非代码缺陷，属资产动作） |
| **B3** 真机中文渲染 | 红·真机 | 适配器/主题引用就位，但**依赖 B1 字体放置** | E6-S2 真机 smoke（须先放字体） |
| **C4** 真机安全区遮挡 | 红·真机 | 适配器已就位（读 `DisplayServer.get_safe_area`，4.3 API 已复核） | E6-S3 真机验证 |
| **.tscn ↔ .gd 节点耦合** | 运行期隐患（P1-1 继承） | 所有 `get_node_or_null` 有 null 守卫，节点缺失**静默不渲染不崩** | 工程环境跑一次 GUT 全绿 + 编辑器开六屏 |
| **六屏视觉 / 竖屏可达** | GDD §8(8) | Container 布局就位 | E6-S1 |

### 5.3 显式 Lean 延后（不阻塞 MVP）
| 项 | 说明 | 不阻塞依据 |
|---|---|---|
| **藤蔓三态**（UX §5 C） | `RelationshipGlyph` 仅符号+文字双编码（达色盲下限），藤蔓形态（光秃/抽芽/开花）未实现 | Sprint 2 QA §7-7 主理人点名「补 or 显式延后」→ Lean 延后；属 UX 额外意图，非红项 |

### 5.4 关键澄清
- **本环境无法验的项 ≠ 未实现**：A4/B2/C4/E2/E4/A6–A10 的代码层面全部就位；B3/C4 真机项与节点耦合项仅是「待跑证」，非「待写」。
- **唯一阻断性资产缺口是 B1 字体二进制**：它不是代码缺陷，而是用户侧资产放置动作；放置前 B3 无法 pass，但不影响逻辑门判定（Lean 下 PASS，B3 列 carry-over）。
- 控制清单全部【红】项已达「实现期关闭 / carry-over 待验 / Lean 延后」三态之一，**无红项处于「未实现」状态**。

---

## 6. Bug / 风险分级（静态发现）

> 未发现「契约逻辑矛盾 / 崩溃」级 P0。以下为 P1/P2。

### P0（封锁）—— 无

### P1（高）
- **P1 · visited/mastery 多场景漏记（Sprint 3 自身缺陷，影响 E4-S2/S3 验收）**
  - **现象**：`SkillMap._start_skill` 仅设一次 `_current_scenario_id = first_id`（L132）；`PlaySession.next_scenario` 在场景间推进时**不 emit `all_done`**（仅 run 末尾 emit，L248），`_on_return_map` 立即 emit（L297）。`all_done` 最终只触发一次 `_on_session_done`，且**永远以入口场景 id 记录** `mark_visited` + `record_scenario`（L150/155）。
  - **后果**：一次跨多场景的单局（如 s01 含 2 场景、或「下一场景」跨越技能边界走到 s03/s04）结束时，**仅入口场景 s01_scene_01 被标记 visited**；`mastery` 仅按该场景的 `_records` 重算，**后续场景进度全部丢失**。地图「已玩过」标记与掌握度均不完整。
  - **辅助症状**：`get_last_chosen_type()` 取的是**最后一屏**的 choice type（`ChoiceSystem.load_scenario` 每次重置 `chosen_type`，L26-27），而它被误用归因到入口场景，skilled 标记也会错配。
  - **定位**：潜伏在 `SkillMap._on_session_done` 链路 —— 该路径**未被 3 个新测试覆盖**（§4.3 缺口 1）。
  - **建议修复**（Lean 最小改动，推荐 Phase 6 修）：让进度按「每次场景完成」记录，而非仅在 run 末记一次：
    1. 给 `PlaySession` 增加信号 `scenario_completed(scenario_id: String, chosen_type: String)`，在「进入 S6 复盘」或「`next_scenario` 推进前 / `all_done`」时发出**当前** `_scenario.id` 与 `chosen_type`；
    2. `SkillMap` 监听该信号，逐场景 `SaveManager.mark_visited(id)` + `_mastery.record_scenario(id, skilled)`；
    3. 同时建议 `next_scenario` 尊重技能边界（不跨技能自动串），或在跨技能时亦逐场景记录。
  - **严重性**：功能正确性缺陷（非崩溃），直接削弱 Sprint 3 头条特性「进度持久化」。Lean 出口可判 PASS，但**须在 Phase 7 发布前关闭**；强烈建议 Phase 6 即修并补 `test_skillmap_navigation.gd`。

### P2（中）
- **P2-1 · `SaveManager` 每次标记双写盘**：`record_scenario` 调 `mark_visited` 与 `set_mastery` 各触发一次 `_write()`（L99/L107），单场景完成落盘 2 次。切片体量极小（K 级），性能可忽略；仅作效率提示，非阻塞。
- **P2-2 · `external_boot` 无测试断言**：防冲突逻辑仅靠静态确认（§4.3 缺口 2），建议补一个「`external_boot=true` 实例化后不自动进入 S2」的 GUT 断言。
- **P2-3 · 音频空白**：`assets/audio/` 当前无资产，audio-director 尚未介入。架构 §2 已标注 MVP 音频可空，故不阻塞；但 Phase 7 发布前须补（见 §9）。
- **P2-4 · 跨技能「下一场景」语义未定**：`_build_order` 扁平化全部技能场景，`next_scenario` 会从 s01 末尾直接跳到 s03（跨技能）。若产品意图是「单技能内推进、技能末返回地图」，需明确并在 `next_scenario` 加技能边界判断（与 P1 修复一并考虑）。

### 继承风险（P1-1，来自 Sprint 2）
- **`.tscn ↔ .gd` 节点耦合未运行验证**：全部 `get_node_or_null` 有 null 守卫，缺失节点**静默不渲染不崩**。须工程环境跑一次 GUT 全绿 + 编辑器开六屏确认 `StageRoot/ReviewPanel/CaseSection`、`RelationshipGlyph/SymbolLabel`/`TextLabel`、`RootMargin/VBox/StartButton` 等节点路径与 `.gd` 引用一致。

---

## 7. 最终 Lean 质量门判定

# 🚦 判定：**PASS（carry-over 真机验证清单）**

**判定理由**
- ✅ **无 P0、无契约逻辑矛盾**。Sprint 3 全部逻辑契约（导航接线、visited 标记渲染、掌握度 0–3、白名单存档、双重解析修复）静态满足；E2/E4 红项经「白名单 + 双层 sanitize + GUT 断言」端到端关闭；主理人 Python 等价校验结论继续有效。
- ✅ **控制清单全部【红】项**已达「实现期关闭 / carry-over 待验 / Lean 延后」三态之一，**无红项处于「未实现」状态**。
- ✅ **Sprint 2 QA §7 七条强制项全部有处置**（4 关闭 + 2 测试化关闭 + 1 Lean 延后 + 1 环境 carry-over），无遗留。
- ⚠️ **唯一阻断性资产缺口 B1 字体二进制缺失**：属用户侧资产放置动作（非代码缺陷）；放置前 B3 真机中文无法 pass，但 Lean 逻辑门不受影响。
- ⚠️ **P1（visited/mastery 多场景漏记）**：功能正确性缺陷，Lean 出口可判 PASS，但**须 Phase 7 发布前关闭**（强烈建议 Phase 6 修）。

**结论措辞**：垂直切片可玩原型的**逻辑契约与红项代码层面全部就位**，剩余仅为真机/运行期验证项与一处进度记录逻辑缺陷。Lean 下判定 **PASS**，附 carry-over 验证清单（§8）与 Phase 6/7 必补 QA 条目（§9）。

---

## 8. 用户侧必须执行的验证清单（carry-over，须在主环境跑）

> 本沙箱无法执行；以下为**主理人/工程在主环境（有 Godot + 真机）**须逐项跑证后回填结论。

### 8.1 编辑器 / Headless GUT 全绿（关 P1-1 + 验证 P1 是否触发）
```bash
# 1) 放置字体（先决）：把 NotoSansSC-Regular.ttf 放到
#    godot/assets/fonts/NotoSansSC-Regular.ttf
#    （OFL 授权；关联控制清单 G8，真机分发前 closing）

# 2) 启用 GUT 插件：编辑器 Project → Project Settings → Plugins → Gut → Enable
#    （或把兼容 Godot 4.3 的 addons/gut/ 提交进 res://addons/gut/）

# 3) Headless 跑 res://tests 全绿（退出码 0 = 通过）
godot --headless --path . --rendering-driver opengl3 \
      --scene res://addons/gut/gut.tscn \
      -gdir=res://tests -gexit
```
- 预期：3 个新测试（save_manager / play_session / mastery）+ 既有 trigger/consequence 测试全绿；`test_cjk_font.gd` 在字体放置后绿。
- 重点验证：① 节点耦合无静默缺失（P1-1）；② 跑后**手动复核 P1**：从地图进 s01，连续玩完 s01_scene_01 + s01_scene_02 返回地图，确认 `user://save_v1.json` 的 `visited` 含**两个**场景、`mastery["s01-shake-the-hive"]` 正确；若仅含 s01_scene_01 → 触发 P1，须先修再发布。

### 8.2 真机 smoke（B3 / C4 / 竖屏，E6-S2/S3）
- **B3 真机中文**：iOS 真机 + Android 真机各启一处场景卡/复盘/UI，确认中文非豆腐块（**模拟器不可作为唯一验证**，须至少一台真机证据）。先决：§8.1 字体已放置。
- **C4 真机安全区**：异形屏（刘海/手势条）真机确认顶部/底部/侧边 UI 在安全区内无裁切；横屏不可触发（仅竖屏）。
- **竖屏可达**：六屏单屏可达、单局 ≤3 分钟（GDD §8(8)）。

### 8.3 资产审计（B1 / G8）
- 确认 `NotoSansSC-Regular.ttf` 已落位且 `portrait_theme.tres` 引用命中；字体授权（OFL-1.1）范围确认，真机分发前 closing（G8）。

---

## 9. Phase 6 打磨 / Phase 7 发布前必补 QA 条目

> 由 quality-lead 提，按优先级排列。

| # | 条目 | 归属 | 说明 |
|---|---|---|---|
| 1 | **修 P1 visited/mastery 多场景漏记** | Phase 6（强烈建议）/ 最迟 Phase 7 前 | 见 §6 P1；补 `test_skillmap_navigation.gd` 固化逐场景记录；顺带明确「下一场景」跨技能语义（P2-4） |
| 2 | **真机 smoke（B3/C4）** | Phase 6（建议提前，成本最低）或 E6 | iOS+Android 真机中文 + 安全区证据；主理人 Sprint 2 已建议 Sprint 1 末做，现仍 carry-over |
| 3 | **性能剖析** | Phase 6/7 | 单局 ≤3 分钟、六屏单屏可达的实测；`SaveManager` 双写盘（P2-1）在体量放大后是否需批量写 |
| 4 | **资产审计** | Phase 7 前 | 字体授权 G8 closing；图标/气泡/分隔等 `assets/ui` 资产（现多为占位）到位；美术圣经符号 ◌⬡⑂ / 六边形资产接入 |
| 5 | **音频** | Phase 7 | `assets/audio/` 当前空白，audio-director 尚未介入；MVP 可空但发布前须补轻量音效或显式「静音」决策 |
| 6 | **藤蔓三态** | Phase 7（UX 决策） | 若产品要求色盲形态承重（UX §5 C），须补 `RelationshipGlyph` 藤蔓光秃/抽芽/开花；否则维持符号+文字双编码并显式归档为 Lean 延后 |
| 7 | **可访问性走查** | Phase 7 | UX §5 A–G（对比度/字号/色盲/触控/深色/Reduce Motion/屏幕阅读器）在真机逐项过；当前仅代码基线，未走查 |
| 8 | **内容评审** | Phase 6/7 | GDD §8(3) 陷阱真实文案、(4) P1 不说教语气，属 design 评审项，本 QA 静态范围外，须 design-strategist 走查 |

---

## 附录 A · 一句话汇总给主理人

Sprint 3 **逻辑契约与红项代码层面全部就位**：导航接线、0–3 掌握度、白名单存档（E2/E4 端到端关闭）、双重解析修复均静态满足且被 3 个新 GUT 测试覆盖；控制清单全红项进入「实现期关闭 / carry-over 待验 / Lean 延后」三态，**无红项未实现**。Lean 出口门判定 **PASS**，附 carry-over 真机验证清单（§8）。**两处须你侧动作**：① 放置 `NotoSansSC-Regular.ttf`（B1 资产，非代码缺陷，放好即解 B3 前置）；② 在主环境跑 GUT 全绿 + 真机 smoke。一处**须 Phase 7 前关闭的功能缺陷 P1**：`SkillMap` 多场景进度漏记（仅记录入口场景），建议 Phase 6 即修并补导航测试。
