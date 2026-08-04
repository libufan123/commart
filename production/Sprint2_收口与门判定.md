# Sprint 2 收口与质量门判定 · 沟通技能游戏（Godot 4.3 · 竖屏 · Lean）

> **Owner**：主理人（游承峰）汇编 · Sprint 2 = E2 完整 + E3 完整 + E4-S1
> **阶段**：Phase 5 制作 · 第二个实现脉冲
> **日期**：2026-08-04

---

## 1. Sprint 2 范围与交付

### 1.1 实现范围
- **E2 完整（S3 触发识别 + 硬闸门 + miss 演出）**
- **E3 完整（S4 抉择 + S5 后果查表 + forceBoundary + 关系信号仅渲染）**
- **E4-S1（S6 复盘面板只读渲染）** —— 让单场景闭环 S2→S3→S4→S5→S6 可达
- 存档（SaveManager）/ 导航（SkillMap）/ 掌握度（Mastery）**不在本 Sprint**，留 Sprint 3（E4-S2~S5）

### 1.2 落盘文件（全部在 `godot/` 工程根）
**新增系统脚本** `scripts/systems/`
- `TriggerSystem.gd`（S3：渲染候选标签、判定 `trigger_correct`、派生解锁集）
- `ChoiceSystem.gd`（S4：捕获 chosen_choice_id/chosen_type 入 RunState）
- `ConsequenceEngine.gd`（S5：纯静态查表；① miss 优先 ② forceBoundary ③ 所选 choice ④ 降级首个）
- `PlaySession.gd`（状态机编排器：S2→S3→S4→S5→S6 一次一屏互斥；对齐测试 API）

**新增场景** `scenes/`
- `components/TagButton.tscn` · `components/ChoiceCard.tscn` · `components/RelationshipGlyph.tscn`
- `play/TriggerPanel.tscn` · `play/ChoicePanel.tscn` · `play/ConsequenceStage.tscn` · `play/ReviewPanel.tscn`

**修改（Sprint 1 复用，未重写契约文件）**
- `ScenarioEngine.gd`（抽出静态 `render_card`，零重复复用 S2）
- `ScenarioCard.tscn`（加 ContinueButton 做 S2→S3 入口）
- `PlaySession.tscn`（根脚本改挂 `PlaySession.gd`，保留 RootMargin）
- `project.godot`（补 `[gui] default_theme` 指向 `portrait_theme.tres`，B1/B2 全局 CJK 接线）
- 测试：`tests/test_trigger_system.gd`（3 用例）+ `tests/test_consequence_engine.gd`（2 用例）
- `README_Sprint2.md`（验证指引）

**未改动**：`DataLoader.gd` / `ScenarioValidator.gd` / `scenario_types.gd` / `ui_adapter.gd`（契约层复用）。

---

## 2. 独立校验结论（主理人 Python 等价复刻 + 静态审阅）

| 验收点 | 结论 |
|---|---|
| **S3→S4 硬闸门（D2）** | `can_choose()` 仅 `trigger_correct` 为真放行，`choose()` 前置拦截 —— 识别错不可抉择 ✅ |
| **识别错优先 miss（D3 / 方案A / G2）** | s01 识别错 → 命中 `triggers.miss` 演出，无红叉、靠后果自学 ✅ |
| **miss 缺省回退（E1 降级）** | 无 miss 且识别错 → 回退首个 choice consequence，非 null 不崩 ✅ |
| **forceBoundary 确定性路由（D6 / ADR-004）** | s04 `forceBoundary:true` 即便选 skilled 也路由 boundary 后果 ✅ |
| **关系信号仅渲染（E2 起点）** | 5 场景 `relationshipSignal` 仅在 consequence 数据层（-1/0/+1），无存档结构 ✅ |
| **S6 复盘文案来自数据（P2 已移除）** | mechanism/case/migration 全取自数据；case 缺则整段隐藏（A7）；无「你必须」口吻、无伦理批注 ✅ |

> 注：Python 测试桩曾用占位 id（`c_skilled`）触发 fallback 分支，仅为复刻规则③；真实数据 choice id 为 c1/c2/c3，引擎用真实 id 命中规则③，不影响结论。

---

## 3. 质量门判定（quality-lead）

### 判定：**CONCERNS（带条件可进入 Sprint 3）**

- **无 P0、无逻辑矛盾**；全部逻辑契约达成且 GUT 测试对齐。
- 不能宣告 PASS 的原因：本环境无 Godot 二进制、无真机，且 **E2/E4 持久化白名单断言被设计性推迟到 Sprint 3（SaveManager 未实现）**。

### 关键 CONCERNS / carry-over
1. **E2/E4 持久化端到端未验证（红项不能清零）**：本 Sprint 仅断言「渲染可见 ≠0」，禁出盘白名单断言留 Sprint 3。
2. **`.tscn ↔ .gd` 节点耦合未经运行验证（P1）**：节点缺失会「静默不渲染不崩」，需编辑器/真机/headless GUT 发现。
3. **关系信号「藤蔓三态」UX 意图部分未满足（P2）**：`RelationshipGlyph` 仅有符号+文字（达标色盲下限），缺藤蔓形态（光秃/抽芽/开花）——需 art/主理人拍板补实现或显式 Lean 延后。
4. **P2 代码异味**：`PlaySession.choose()` 经 signal 解析一次又显式再解析一次（幂等但冗余）——建议合并单路径。
5. **carry-over（本环境一律不可验证）**：B3 真机中文、C4 真机安全区、CJK 字体继承、六屏视觉/竖屏可达。

### Sprint 3 必补 QA 条目（quality-lead 提）
| # | 条目 | 说明 |
|---|---|---|
| 1 | **E2/E4 持久化白名单断言** | `test_save_manager.gd`：存档仅 `{saveVersion,mastery,visited,settings}`，断言无 `relationshipSignal`/无 S9 字段 |
| 2 | **真机/编辑器 smoke** | `godot --headless` GUT 全绿 + 编辑器开六屏确认节点耦合（关 P1） |
| 3 | **E3-S5 安全失败断言** | 连续两次选 trap 后果照常、不封锁不扣分、重练无冷却（当前架构性真空满足但无测试，需固化 D8） |
| 4 | 六屏状态机烟雾 `test_play_session.gd` | S2→S6 流转 + 再练/下一/返回 跳转断言 |
| 5 | A7 运行时降级断言 | `ReviewPanel` case 缺失 `CaseSection.visible=false` |
| 6 | 修 `choose()` 双重解析（P2-4） | 合并为单路径 |
| 7 | 藤蔓形态：补 or 显式延后（P2-3） | 需 art/主理人拍板 |

---

## 4. 已知风险与缓解（carry-forward）

- **声誉风险（P2 已移除）**：复盘无说教口吻已实现；仍建议 onboarding 加一句免责声明（扩展层）。
- **1930s 案例本地化**：场景文案已现代语境重写；书中原案例仅在 `review.case` 引用，需逐条核对现代适配。
- **真机/iOS 发布前置（G7）**：需 Mac + 开发者账号，排期到 E6。
- **字体授权（G8）**：Noto Sans SC（OFL）已选，落地前 closing。

---

## 5. 下一步 · Sprint 3

**Sprint 3 = E4-S2/S3/S4/S5（导航 S8 + 掌握度 S7 + SaveManager 轻量存档）+ E6 集成与竖屏真机验收**，目标是把垂直切片拼成「可从地图进入、可持久进度、可真机跑通」的完整可玩原型，并清零全部红项（A4/B1/B2/B3/C4/E2/E4）达成 Phase 4 实现就绪。

- `MainMenu.tscn` + `SkillMap.tscn`（读 skills_index 渲染 s01/s03/s04 入口 + visited 标记）
- `MasterySystem.gd`（0–3 档，GDD §4.2 判定）/ `SaveManager.gd`（白名单写入，关 E2/E4）
- `test_save_manager.gd`（关系信号禁出盘断言，关红项）
- E6：六屏真机 smoke（B3/C4）、Lean 预制作门全八条 + 全红项清零

> 进 Sprint 3 前需你侧决策：**P2-3 藤蔓三态**（补实现 or Lean 延后）、以及是否在 Sprint 3 末安排一次真机 smoke（B3/C4 早验证成本最低）。
