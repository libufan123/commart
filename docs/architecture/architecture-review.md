# 架构评审 · 设计约束落地性与风险缺口（Phase 3）

> **Owner**：engineering-lead（程基岩）
> **目的**：对照 design-strategist 转交的 6 条工程约束，逐条核对可落地性；标记风险/缺口；聚焦 Godot 中文 UTF-8、移动端性能、竖屏适配、JSON 解析健壮性。
> **关联**：`docs/architecture/engin-architecture.md`、`docs/architecture/adr.md`、`design/gdd/内容数据schema.md`

---

## 1. 六条设计约束逐条核对

| # | 约束 | 可落地性 | 结论 | 关键条件 |
|---|---|---|---|---|
| 1 | 结构即契约：S2–S8 仅消费 Schema，新增场景只增数据不改代码 | ✅ 可 | **通过** | 需 `ScenarioValidator` 在加载期强制字段契约（ADR-001） |
| 2 | Godot 加载：每技能 `.json` + `FileAccess` + `JSON.parse_string`，中文 UTF-8 | ✅ 可 | **通过（有条件）** | 须导入 CJK 字体 + 剥离 BOM（见 R1/R2） |
| 3 | `relationshipSignal` 不持久化，仅本局演出；S9 延后 | ✅ 可 | **通过** | `RunState` 内存态 + `SaveManager` 白名单（ADR-005）；代码评审卡点 |
| 4 | 加载期校验：`correct∈candidates`、≥1 `skilled`、字段齐全；`review.case` 缺失降级不崩溃 | ✅ 可 | **通过** | 校验器实现 + 降级分支；BOM 剥离（R2） |
| 5 | 无逻辑脚本：MVP 后果静态查表，数据不写分支/随机 | ✅ 可 | **通过** | `ConsequenceEngine` 纯映射；`forceBoundary` 为唯一引擎级确定性规则（ADR-004） |
| 6 | P2 字段缺席：Schema 无 `ethicsGate`；扩展层若要则 `schema_v2` | ✅ 可 | **通过（已增强）** | 已加顶层 `schemaVersion`（缺省 1，G4 已决，见 R-gap-3 已决） |

**总体结论**：6 条约束在 Godot 4.3 + 当前 Schema 下均可落地，无阻塞性设计缺陷。3 个**数据/配置级缺口**（R-gap-1/2/3）已由主理人拍板（G2 方案A / G3 npc.line / G4 schemaVersion），状态改为「已决·非阻塞」；4 个**工程实现风险**（R1–R4）需在实现期排期（R1 仍为最高优先硬阻塞）。

---

## 2. 四个重点风险区

### R1 · Godot 中文 UTF-8（最高优先级 ⚠️）

- **风险**：Godot 默认项目字体**不含 CJK 字形**。若不导入中文字体并设为默认，全部中文（场景文案、复盘、UI）将显示为豆腐块 `□`。
- **落地动作（必做，MVP 阻塞）**：
  1. 导入 CJK 字体（推荐 Noto Sans SC / Source Han Sans，注意字体授权可在商业/分发范围）。
  2. `portrait_theme.tres` 的 `default_font` 指向该字体；所有 `Label`/`Button` 继承主题。
  3. 真机（iOS/Android）验证中文渲染——模拟器可能掩盖字体缺失。
- **责任**：工程主导 + art-director 提供/确认字体资产与授权。

### R2 · JSON 编码 / BOM（高优先级）

- **风险**：Windows 工具链（记事本/部分编辑器）常写出 **UTF-8 with BOM**。`JSON.parse_string` 遇 BOM 可能解析异常或首键损坏。
- **落地动作**：
  1. 加载管线在 `parse_string` 前检测并剥离首 3 字节 `EF BB BF`（engin-architecture §4.2）。
  2. 工程规约：所有 `*.json` 以**无 BOM UTF-8** 入库；建议在 CI/提交钩子加编码校验。
- **责任**：工程。

### R3 · 竖屏适配 / 安全区（中优先级，缺口）

- **风险**：Godot **不自动**把 Control 节点推离刘海/圆角/手势条安全区；不处理则顶部/底部 UI 可能被遮挡。
- **落地动作**：
  1. 锁定竖屏（`orientation="portrait"`），`stretch mode=canvas_items` + `aspect=expand`。
  2. 根 `MarginContainer` 内边距由 `ui_adapter.gd` 读取设备安全区内边距动态设置（Godot 4.3 安全区 API 已复核，见 §4）。
  3. 采用容器布局（VBox/Margin/Scroll），不写死像素坐标。
- **责任**：工程（按 Godot 4.3 复核）。

### R4 · JSON 解析健壮性（中优先级）

- **风险**：坏数据（缺字段/类型错/非法 JSON）若无精确报错，难定位、易静默失败。
- **落地动作**：
  1. 用 `JSON.new().parse_string(text)`（实例方法），失败时读取 `get_error_line()` / `get_error_message()` 打印「文件:行:信息」。
  2. `ScenarioValidator` 在解析后做类型/必填/枚举校验（约束4）。
  3. 开发 strict 模式：校验失败 `push_error` + 跳过；release：日志 + 跳过，不崩溃。
- **责任**：工程。

### R5 · 移动端性能（低优先级，说明）

- **评估**：本作纯 Control UI + 文本，无 3D/重特效，性能压力极低，60fps 易达成。
- **注意点**：动态字体首次缓存有少量开销（CJK 字体大），建议在加载页预热；避免在 `_process` 做分配/字符串拼接；复盘长文用 `ScrollContainer`。
- **导出风险（流程，非技术）**：iOS 需 Mac + Apple 开发者账号签名；Android 需 SDK/密钥。属发布流程，Phase 3 可先 Android 真机验证，iOS 排期到送测前。

---

## 3. 数据/配置级缺口（需主理人拍板是否补字段）

### R-gap-1 · 触发识别 → 选项解锁 & 识别错误后果（重要）— **已决·非阻塞（G2 采纳方案A）**

- **现象**：Schema 有 `triggers.correct` 与 `choices[]{type}`，但**未显式编码「所选触发标签」与「选项集/哪条是熟练路径」的映射**，也未定义「识别错误时后果」。切片 GDD §2 与 E1 明确要求：识别正确才解锁熟练选项；识别错误则「选项错位、选任何选项都导向反噬/无效后果」。
- **已决（G2 采纳方案A）**：Schema 增**可选**字段 `triggers.miss`（一个 `consequence` 结构：npcReaction/relationshipSignal/judgement），表示「你误读了处境」。引擎规则：
  - 当 `selected_trigger != triggers.correct`，无论选哪个 choice，一律演出 `triggers.miss`（数据驱动、可控、不写死文案）。
  - 当 `triggers.miss` 缺省时，`ConsequenceEngine` 回退到所选 choice 的现有 `consequence` 逻辑，**不得崩溃**（降级而非失败）。
  - 识别正确时按所选 choice 的正常 `consequence` 演出，不受影响。
- **实现落点**：`ScenarioValidator` 须将 `triggers.miss` 视为可选、结构同 `consequence`；`ConsequenceEngine` 须支持「识别错→演出 miss、miss 缺省→回退」分支（确定性查表，非随机/脚本，符合 ADR-004）。
- **状态**：已决·非阻塞；方案 B 不再采用。Schema 仅需增 1 个可选字段，不破坏现有 `s01_scene_01` 示例；架构层支持已写入 engin-architecture §4.2 / §6.2。

### R-gap-2 · S2 需要 NPC「最后一句/动作」字段（中等）— **已决·非阻塞（G3 增 `npc.line`）**

- **现象**：切片 GDD §6 的「场景卡」明确要求渲染「对方最后一句（或动作）」，但 Schema 仅有 `context`（情境背景）与 `npc{mood}`，**无 NPC 触发台词/动作字段**。S2 渲染会缺关键元素。
- **已决（G3）**：在 Schema 增加**可选**字段 `npc.line`（对方最后一句/动作，字符串）。不破坏现有字段；缺失时 S2 仅显示 `context`。渲染层（`ScenarioCard` / S2）在场景卡显示 `npc.line` 作为 NPC 末句气泡。
- **状态**：已决·非阻塞；Schema 仅需增 1 个可选字段，不破坏现有示例；架构层映射已写入 engin-architecture §3（ScenarioCard 节点含 `NpcLineBubble`）。

### R-gap-3 · 增加 `schemaVersion` 顶层字段（轻量，前瞻）— **已决·非阻塞（G4）**

- **现象**：约束6 要求扩展层加 `ethicsGate` 时单开 `schema_v2`，勿污染 MVP 数据。但若 MVP 数据无版本标识，未来 loader 难以区分 v1/v2。
- **已决（G4）**：MVP 数据可选加顶层 `"schemaVersion": "1"`（缺省按 1 处理）。Loader 按版本分支决定校验严格度，未来 `schema_v2` 平滑接入，不回溯改 MVP 文件。
- **状态**：已决·非阻塞；Loader 版本分支已写入 engin-architecture §4.2 与 adr.md ADR-002。

> 以上三处均为**可选/轻量**增补，不破坏现有 `s01_scene_01` 示例结构（示例可继续用，仅新增字段留空/缺省）。S8 导航元数据走独立 `skills_index.json`，**不要求改场景 Schema**（见 engin-architecture §6.4）。

---

## 4. 与跨 GDD 一致性自检的衔接

- 设计侧已确认四份文档无矛盾、去 P2 后三保险（后果驱动/陷阱即教学/案例作证）自洽。本架构**完全承接**该结论：
  - S5/S6 纯数据驱动，无说教口吻（P1）——由数据文案 + 无评分弹窗保证。
  - S3 硬闸门（P3）——由 `PlaySession` 状态机 + `TriggerSystem` 派生选项集保证。
  - S2 单屏 + S6 再练 + S7/S8 轻导航（P4）——由竖屏适配层 + 控制清单保证。
- 设计自检标注的两项 Phase 3 盯紧项（陷阱真实性、复盘文本克制）属**文案/内容**范畴，工程侧以「文本长度/段落约束」在 UI 层兜底（如 `ScrollContainer` + 字数预警），不替设计下结论。

---

## 5. 评审结论

- ✅ 6 条设计约束均可落地，无设计层面阻塞（已按 Godot 4.3 复核）。
- ✅ 3 个数据缺口 R-gap-1/2/3 已决（G2 方案A / G3 npc.line / G4 schemaVersion），状态「已决·非阻塞」，Schema 仅需增 3 个可选字段，不破坏现有示例。
- ⚠️ 4 个工程风险 R1–R4 需在实现期排期，**R1（CJK 字体）仍为 MVP 最高优先硬阻塞**，须 Phase 4/5 第一步落地；R2 BOM 剥离、R3 安全区、R4 JSON 健壮性照常排期。
- 下一步：工程进入 Phase 4 实现期，按 `control-list.md` 验收推进。
