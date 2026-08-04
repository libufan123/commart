# ADR 记录 · 基础层技术决策（Phase 3）

> **Owner**：engineering-lead（程基岩）
> **范围**：基础层（L0）与跨切面决策，供 S2–S8 实现期遵循
> **状态约定**：Proposed（待主理人确认）/ Accepted（工程已定，与设计约束一致）/ Superseded
> **关联**：`docs/architecture/engin-architecture.md`、`design/gdd/内容数据schema.md`

---

## ADR-001 · 数据驱动 vs 硬编码

- **状态**：Accepted
- **上下文**
  - 设计约束1「结构即契约」：S2–S8 仅消费 Schema 字段，新增场景只增数据、不改代码（禁止写死文案）。
  - 34 技能 / 6 篇，未来内容靠数据扩充，不能每场景改代码。
- **决策**
  - 全部可玩文案（背景、对方、冲动、候选标签、选项、后果、复盘）一律来自 `内容数据schema.md` 结构，经 `DataLoader` 加载。
  - 表现层 S2–S8 只读取 `Scenario` 类型对象的字段；任何硬编码字符串（除 UI 框架文案如「再练一次」按钮）均禁止出现在 systems 脚本。
  - `DataLoader` 是 S2–S8 唯一数据入口；systems 不直接 `FileAccess` 读盘。
- **后果**
  - ✅ 新增场景 = 加一个 `.json`，零代码改动，满足 Lean 可评审。
  - ✅ 文案评审与代码评审解耦，design-strategist 可独立迭代内容。
  - ⚠️ 需要在加载期建立字段校验器（见 ADR-002 / 约束4），否则坏数据难定位。
  - ⚠️ UI 框架级文案（按钮、空态）仍属代码侧，需在主题/常量集中管理，不混入场景数据。

---

## ADR-002 · JSON 文件加载方式

- **状态**：Accepted
- **上下文**
  - 设计约束2：每技能一个 `.json`（如 `s01.json`）或统一 `scenarios.json` 数组；用 `FileAccess` + `JSON.parse_string()`；中文务必 UTF-8。
  - 需保证移动端（iOS/Android）可读、可校验、可降级。
- **决策**
  - **存储形态**：每技能一个 `res://data/scenarios/sNN.json` 文件（一个文件 = 一个 `Scenario` 对象），便于 diff/评审/独立增删；加载时枚举目录汇总为内存索引。统一数组形式亦可，但每技能文件更契合「新增场景只增数据」。
  - **读取 API**：`FileAccess.get_file_as_string(path)` 取 UTF-8 字符串 → `JSON.new().parse_string(text)`（实例方法；弃用 `parse_json()`）。
  - **编码**：解析前剥离 UTF-8 BOM（`EF BB BF`）；工程规约所有 JSON 以「无 BOM UTF-8」入库（在 `SKILL`/CI 或提交钩子里校验）。
  - **错误处理**：解析失败读取 `get_error_line()` / `get_error_message()` 打印精确位置；strict（开发）模式 `push_error` 并跳过该文件，release 记录日志跳过（不崩溃）。
  - **校验时机**：加载期即校验（见约束4 / ADR 关联 `ScenarioValidator`）。
  - **版本分支（G4 已决）**：数据顶层可选 `"schemaVersion"`（缺省 1）。Loader 按版本分支决定校验严格度；`schema_v2`（如扩展层 ethicsGate）平滑接入，不回溯改 MVP 文件。
- **后果**
  - ✅ Godot 原生支持，无需第三方库；`.json` 不触发特殊导入，走普通文件读取。
  - ✅ 逐文件加载 + 内存索引，单局切换零读盘。
  - ⚠️ **BOM 风险**（R2）：Windows 工具链易写出带 BOM 文件，必须在解析前剥离，否则首字段解析异常。
  - ⚠️ **版本已锁定 4.3**：`get_error_line()` / `get_error_message()` 在 Godot 4.3 下为 `JSON.new().parse_string()` 实例方法返回后的实例属性，确切签名已按 4.3 复核（见 engin-architecture §8）。
  - ⚠️ 大批量（扩展层 34 技能）时目录枚举 + 逐文件读仍足够（K 级数据）；若未来达万级再考虑预编译二进制。

---

## ADR-003 · 竖屏单屏卡对话树

- **状态**：Accepted
- **上下文**
  - 概念文档 P4「低门槛、高频、可重玩」+ 竖屏 3 分钟一局；切片 GDD §6 列出 6 个关键屏幕，均竖屏单屏。
  - 设计约束3（竖屏对话树）= 线性单屏卡：`Scenario(节点) → Trigger-Tag → Choice(边) → Consequence → Review`；MVP 不做分支叙事树（choices 级联留扩展层）。
- **决策**
  - 采用**线性单屏卡**结构：每个 Scenario 是一张可单屏呈现的卡，玩家在单屏内完成「读情境→识别→抉择→看后果→复盘」。
  - `PlaySession` 用状态机在六个面板间切换（一次显一个），不堆叠多屏；超长文本（复盘）用 `ScrollContainer` 在单屏内滚动。
  - MVP **不做**选项级联/分支叙事树；`choices[]` 为平铺 2–4 项，后果为所选选项的静态 `consequence`。
  - 工程配置锁定竖屏（`orientation="portrait"`），禁用横屏；`display/window/stretch` 设为 `canvas_items` + `expand`，布局用容器而非硬编码坐标。
- **后果**
  - ✅ 完全匹配 P4 与切片 GDD 的竖屏可达 / ≤3 分钟验收。
  - ✅ 实现简单、可评审、移动端性能压力极低（纯 Control UI）。
  - ⚠️ 牺牲叙事分支深度——此为有意 Lean 取舍，扩展层（分支场景树）再补，且不回溯改 MVP 数据（约束3）。
  - ⚠️ 安全区（刘海/手势条）需 `ui_adapter` 额外处理（R3 缺口）。

---

## ADR-004 · 无脚本静态查表后果

- **状态**：Accepted
- **决策依据**：设计约束5「无逻辑脚本：MVP 后果为静态查表，不在数据里写条件分支/随机，保持 Lean 可评审」。
- **上下文**
  - S5 后果引擎：按玩家所选 `choice` 的 `consequence` 字段直接映射为演出，无随机、无 AI、无条件分支。
  - 与「主导策略」红线解耦：本作为非对抗性单人学习游戏，后果由体验而非评分给出（一致性自检 §3.1）。
- **决策**
  - 后果完全由 `consequence{ npcReaction, relationshipSignal, judgement }` 静态呈现；数据层**禁止**出现 `if`/条件键/随机种子/表达式。
  - `ConsequenceEngine` 仅做「取所选 choice.consequence → 渲染」，不含任何业务分支（边界强制 `forceBoundary` 除外，见下）。
  - 唯一例外：`forceBoundary: true` 时（E2 边缘情况）引擎**强制**路由到 `boundary` 选项后果——这是引擎级安全规则，非数据脚本，且为固定确定性行为。
  - 识别错误（E1）的「错位后果」由 `ConsequenceEngine` 演出 `triggers.miss`（可选 consequence 结构，G2 方案A 已决）实现；`miss` 缺省时回退所选 choice 的 consequence，仍属确定性查表，不引入随机（数据/规则见 architecture-review R-gap-1 已决）。
- **后果**
  - ✅ 满足 Lean 与可评审：任意场景后果可纯靠读数据推演，无隐藏逻辑。
  - ✅ 与「不说教 / 后果自己说话」一致（P1）。
  - ⚠️ 若未来扩展层要「NPC 对前后选择连贯反应（对手反应 AI）」，需新开架构决策，不回溯污染 MVP（见概念文档 Layer 3）。

---

## ADR-005 · 存档范围（MVP 最小化）

- **状态**：Accepted
- **上下文**
  - 设计约束3：`relationshipSignal` 不持久化，仅本局演出；S9 关系账户延后。
  - 设计约束6：P2 `ethicsGate` 不在 MVP；扩展层若加则 `schema_v2`。
  - S7 掌握度属 MVP（可最简），需轻量跨会话留存；S8 导航需「完成标记」。
- **决策**
  - **内存态 `RunState`**：当前单局的技能/场景/所选触发/所选选项；`relationshipSignal` 仅在 `ConsequenceStage` 渲染时取出、用后即弃，**不写** `RunState` 持久字段。
  - **本地存档 `SaveManager`（出盘，轻量）**：仅 `mastery`（S7 0–3 档）、`visited`（场景完成标记，供 S8）、`settings`。写入 `user://save_v1.json`。
  - **明确禁止出盘**：`relationshipSignal`、任何 S9 关系账户数值（MVP 本无）。
  - **版本化**：存档带 `saveVersion`，Loader 按版本迁移；与数据 `schemaVersion`（顶层可选，缺省 1，G4 已决）解耦，为 `schema_v2` 预留。
- **后果**
  - ✅ 严格满足「relationshipSignal 不持久化 / S9 延后」，无跨场景累积泄漏。
  - ✅ S7/S8 所需轻量进度可跨会话保留，且不制造数值压力（无 meter）。
  - ⚠️ 跨设备/云同步不在 MVP（无账号/网络）；如需，扩展层另立决策。
  - ⚠️ `save_v1` 与未来 S9 账户设计需隔离，避免 MVP 轻量存档被扩展层数值模型绑架（命名 `save_v1` 即预留演进空间）。
