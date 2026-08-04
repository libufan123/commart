# 主架构文档 · 沟通技能游戏（Godot · 移动端竖屏 · Lean）

> **Owner**：engineering-lead（程基岩）
> **阶段**：Phase 3 技术搭建（架构与约束，不含完整游戏实现代码）
> **引擎基线**：Godot 4.3（已锁定版本；安全区/JSON 错误 API 均按 4.3 复核，见 §8 与 adr.md ADR-002）
> **平台**：iOS / Android 移动端，竖屏优先
> **评审强度**：Lean
> **关联文档**：`design/gdd/系统设计_系统拆解.md`（S1–S9）、`design/gdd/内容数据schema.md`、`design/gdd/垂直切片GDD_s01_s03.md`、`design/concept/沟通技能游戏_概念文档.md`

---

## 1. 架构总览

### 1.1 分层

```
┌─ 跨切面 ────────────────────────────────────────────────┐
│ DataLoader(Autoload) · RunState(Autoload) · SaveManager  │
│ UI 适配层（竖屏 / 安全区 / 触控）· CJK 字体              │
└──────────────────────────────────────────────────────────┘
        │
L4  ── S6 复盘系统 ──┐        S7 掌握度（轻量本地） ──┐
        │             │                              │
L3  ── S5 后果引擎 ──┘                              S8 技能地图/导航
        │
L2  ── S3 触发识别（S4 硬闸门）── S4 抉择系统
        │
L1  ── S2 场景引擎
        │
L0  ── S1 内容数据层 + 加载/校验管线 + 类型封装
```

### 1.2 设计原则（与 6 条设计约束对齐）

1. **结构即契约**：S2–S8 仅消费 `内容数据schema.md` 字段；新增场景只增数据、不改代码（约束1）。
2. **数据驱动加载**：场景 = 一条数据记录；Godot 用 `FileAccess` + `JSON.parse_string()` 读取，中文 UTF-8（约束2）。
3. **relationshipSignal 不持久化**：仅本局演出（-1/0/+1）；S9 账户延后，勿做跨场景累积存储（约束3）。
4. **加载期校验**：`triggers.correct ∈ candidates`、`choices` 含 ≥1 个 `skilled`、必填字段齐全；缺失 `review.case` 允许降级而非崩溃（约束4）。
5. **无逻辑脚本**：MVP 后果为静态查表，数据里不写条件分支/随机（约束5）。
6. **P2 字段缺席**：Schema 无 `ethicsGate`；扩展层若加则单开 `schema_v2`，勿污染 MVP 数据（约束6）。

### 1.3 关键技术姿态

- **不写完整游戏代码**（Phase 4/5 实现期职责），本阶段只产出：目录/节点划分、加载管线、适配层、存档方案、ADR、评审、控制清单。
- 竖屏单屏对话卡 = 线性结构 `Scenario(节点) → Trigger-Tag → Choice(边) → Consequence → Review`；MVP 不做分支叙事树（choices 级联留扩展层）。
- 表现层与数据层解耦：DataLoader 是 S2–S8 唯一数据入口，S2–S8 不直接读文件。

---

## 2. Godot 项目目录结构

```
res://
├─ project.godot                      # 竖屏/拉伸/导出配置（见 §5、§8）
├─ assets/
│   ├─ fonts/
│   │   └─ NotoSansSC-Regular.ttf      # ★ 必须：CJK 字体（默认字体不含中文，见架构评审 R1）
│   ├─ ui/                            # 图标/气泡/分隔等（由 art-director 提供）
│   └─ audio/                         # 可选：轻量音效（MVP 可空）
├─ data/
│   ├─ scenarios/                     # 每技能一个 .json（推荐，见 ADR-002）
│   │   ├─ s01.json
│   │   ├─ s03.json
│   │   └─ ...（s01–s06，每技能 3–4 场景或拆为多文件）
│   ├─ skills_index.json             # ★ S8 导航元数据（skillId→标题/篇/顺序），见 §6.4
│   └─ schema_note.md                # 指向 内容数据schema.md 的索引（非代码依赖）
├─ scenes/
│   ├─ Main.tscn                     # 启动根 + Autoload 接线
│   ├─ menus/
│   │   ├─ MainMenu.tscn              # 主页/入口（兼 S8 入口）
│   │   └─ SkillMap.tscn              # S8 技能地图（切片 s01/s03/s04，G5 已决含 s04）
│   ├─ play/
│   │   ├─ PlaySession.tscn           # 单局编排器：S2→S3→S4→S5→S6 状态机
│   │   ├─ ScenarioCard.tscn          # S2 场景卡
│   │   ├─ TriggerPanel.tscn          # S3 触发识别面板
│   │   ├─ ChoicePanel.tscn           # S4 选项卡
│   │   ├─ ConsequenceStage.tscn      # S5 后果演出
│   │   └─ ReviewPanel.tscn           # S6 复盘面板
│   └─ components/                    # 复用 UI
│       ├─ Bubble.tscn                # 冲动气泡 / NPC 台词气泡
│       ├─ TagButton.tscn             # 触发标签按钮
│       ├─ ChoiceCard.tscn            # 选项卡
│       └─ RelationshipGlyph.tscn     # relationshipSignal 符号（-/0/+）
├─ scripts/
│   ├─ autoload/
│   │   ├─ DataLoader.gd              # L0：加载+校验+缓存（S1 入口）
│   │   ├─ RunState.gd                # 内存态：当前局/当前选择/选中触发
│   │   └─ SaveManager.gd             # 本地存档：掌握度/进度/设置
│   ├─ core/
│   │   ├─ scenario_types.gd          # 类型封装（Scenario/Trigger/Choice/Consequence/Review）
│   │   └─ ScenarioValidator.gd       # 加载期校验（约束4）
│   ├─ systems/
│   │   ├─ ScenarioEngine.gd          # S2
│   │   ├─ TriggerSystem.gd           # S3（派生解锁选项集，S4 硬闸门）
│   │   ├─ ChoiceSystem.gd            # S4
│   │   ├─ ConsequenceEngine.gd       # S5（静态查表，约束5）
│   │   ├─ ReviewSystem.gd            # S6
│   │   ├─ MasterySystem.gd           # S7（轻量本地）
│   │   └─ SkillMap.gd                # S8
│   ├─ ui/                            # UI 控制器（绑定 components 与 systems）
│   │   └─ ui_adapter.gd              # 竖屏适配辅助（安全区/触控尺寸）
│   └─ theme/
│       └─ portrait_theme.tres        # 竖屏主题（引用 CJK 字体为默认）
└─ tests/                             # 单元/加载校验测试（Phase 4 落实现，本阶段先定义清单）
    ├─ test_data_loader.gd
    └─ test_validator.gd
```

> 说明：`.json` 在 Godot 中**不**被特殊导入，作为普通文件经 `FileAccess` 读取（见 ADR-002）。所有场景文件位于 `res://data/scenarios/`，导出时随包打入。

---

## 3. 场景 / 节点划分（S1–S9 映射）

| 场景文件 | 系统 | 职责 | 关键节点（Control 树示例） |
|---|---|---|---|
| `MainMenu.tscn` | S8（入口） | 主页 + 进入技能地图 | `VBoxContainer > TitleLabel, Button(开始/继续)` |
| `SkillMap.tscn` | S8 | 按篇浏览技能/场景，进入单局 | `ScrollContainer > SkillEntryButton[]` |
| `PlaySession.tscn` | 编排 | 单局状态机 S2→S3→S4→S5→S6 | 根 `Node` + 子面板容器（一次只显示一个） |
| `ScenarioCard.tscn` | S2 | 背景+NPC末句(`npc.line`)+冲动气泡 | `Margin > ContextLabel, NpcLineBubble, ImpulseBubble` |
| `TriggerPanel.tscn` | S3 | 2–4 候选标签、校验、硬闸门 | `VBox > TagButton[]`（点选即交 TriggerSystem） |
| `ChoicePanel.tscn` | S4 | 2–4 回应选项、捕获选择 | `VBox > ChoiceCard[]`（样式不标对错） |
| `ConsequenceStage.tscn` | S5 | NPC 反应+判词+关系信号符号 | `Margin > NpcReactionLabel, JudgementLabel, RelationshipGlyph` |
| `ReviewPanel.tscn` | S6 | 机制+案例+迁移+再练/下一 | `ScrollContainer > MechanismLabel, CaseLabel, MigrationLabel, Buttons` |

**S3→S4 硬闸门（P3 支柱承载）**：`PlaySession` 在 S3 未完成前不显示 `ChoicePanel` 的可操作项。`TriggerSystem` 依据玩家所选标签派生「解锁选项集」并传给 `ChoiceSystem`；识别错误（`selected_trigger != triggers.correct`）时，`ConsequenceEngine` 按【方案A】演出可选 `triggers.miss` 后果（缺省回退所选 choice 的 consequence，不崩溃），实现 E1 错位自学（规则见 §6.2 与架构评审 R-gap-1 已决）。

**S9 不在 MVP**：`relationshipSignal` 只读、只在本局 `ConsequenceStage` 展示，绝不进 `SaveManager`。

---

## 4. 数据层加载管线（S1）

### 4.1 流程

```
启动 → DataLoader._ready()（Autoload）
  1. 枚举 res://data/scenarios/ 下全部 *.json
  2. 逐文件：FileAccess.get_file_as_string(path)
        → 去 BOM（若首字节为 EF BB BF）
        → JSON.new().parse_string(text)   // 失败则取 get_error_line/message
  3. ScenarioValidator.validate(dict)     // 必填字段 + triggers.correct∈candidates + ≥1 skilled
        → 通过：封装为 Scenario 类型对象，按 id 入内存索引
        → 失败：strict 模式(开发)=push_error 并跳过；release=记录日志跳过（不崩溃）
  4. 加载 skills_index.json（S8 元数据）
  5. 全部就绪 → 发 signal data_ready，MainMenu 可进入
```

### 4.2 关键实现点

- **UTF-8**：`FileAccess.get_file_as_string()` 返回已是 UTF-8 解码的 `String`；但 Windows 编辑器可能写出 **带 BOM** 的 UTF-8，需在解析前剥离首 3 字节（见 ADR-002 / 架构评审 R2）。
- **健壮性**：用 `JSON.new().parse_string()`（实例方法）而非已弃用的 `parse_json()`；解析失败读取 `get_error_line()` / `get_error_message()` 打印精确位置（见架构评审 R4）。
- **降级而非崩溃**：`review.case` 缺失属「允许降级」项——校验器放行，运行时 `ReviewPanel` 仅在存在 `case` 时渲染该段（约束4）。
- **缓存**：加载后即常驻内存；单局切换场景不再读盘（MVP 体量极小，约 20–24 个文件，总 K 级）。
- **单一入口**：S2–S8 一律通过 `DataLoader.get_scenario(id)` 取数据，禁止直接 `FileAccess` 读盘。
- **schemaVersion（前瞻·G4 已决）**：数据顶层可选 `"schemaVersion"`（缺省 1）。Loader 按版本分支决定校验严格度；未来 `schema_v2`（如 ethicsGate）平滑接入，不回溯改 MVP 文件（见 ADR-002 / architecture-review R-gap-3 已决）。

---

## 5. 竖屏 UI 适配层

### 5.1 工程配置（project.godot）

```
display/window/size/viewport_width=1080
display/window/size/viewport_height=1920
display/window/handheld/orientation="portrait"      # ★ 仅竖屏
display/window/stretch/mode="canvas_items"          # 拉伸缩放
display/window/stretch/aspect="expand"              # 填满并允许留边
```

### 5.2 布局原则

- **基准分辨率 1080×1920（9:16）**；用 `MarginContainer` / `VBoxContainer` / `ScrollContainer` 而非写死像素坐标，使内容随真实设备高度自适应。
- **一次一屏**：六个屏幕（场景卡/识别/选择/后果/复盘/地图）在 `PlaySession` 中互斥显示，符合「单屏单局、≤3 分钟」（切片 GDD §6、§8）。
- **触控尺寸**：可点击元素 ≥ 44×44pt（iOS HIG）/ 48dp（Android）；`ChoiceCard`/`TagButton` 设最小高度。
- **安全区（刘海/手势条）**：Godot 4.3 不会自动把 UI 推离安全区。需在 `ui_adapter.gd` 中读取设备安全区内边距并施加到根 `MarginContainer`（Godot 4.3 下安全区 API 已复核，见架构评审 R3）。**这是 MVP 必须补的实现项，非阻塞设计，但需排期。**
- **默认字体 = CJK 字体**：`portrait_theme.tres` 的 `default_font` 指向 `NotoSansSC-Regular.ttf`，否则中文显示为豆腐块（见架构评审 R1，最高优先级）。

---

## 6. 状态与进度存档方案

### 6.1 两类状态

| 状态 | 载体 | 生命周期 | 是否落盘 |
|---|---|---|---|
| **RunState（内存态）** | `RunState.gd`（Autoload，`Dictionary`） | 当前单局 | 否 |
| **SaveData（本地存档）** | `SaveManager.gd` → `user://save_v1.json` | 跨会话 | 是（仅轻量） |

### 6.2 RunState 内容（仅内存，不出盘）

```gdscript
RunState := {
  current_skill:   String,        # 当前技能 id
  current_scenario: String,       # 当前场景 id
  selected_trigger: String,       # S3 玩家所选标签
  trigger_correct: bool,          # 是否 == triggers.correct
  chosen_choice_id: String,       # S4 所选选项
  chosen_type:      String,       # skilled/trap/boundary
  # relationshipSignal：仅在本局 ConsequenceStage 展示完即丢弃，不存于此、更不出盘
}
```

- S3→S4 硬闸门数据即来自 `selected_trigger` / `trigger_correct`：识别错误（`selected_trigger != triggers.correct`）时，`ConsequenceEngine` 按【方案A】演出 `triggers.miss`（可选 consequence 结构：npcReaction/relationshipSignal/judgement）；`miss` 缺省则回退现有「所选 choice 的 consequence」逻辑，不得崩溃（G2 已决；详见 adr.md ADR-002、ADR-004 与 architecture-review R-gap-1 已决）。
- `relationshipSignal` 在 `ConsequenceEngine` 从所选 `consequence.relationshipSignal` 取出，**仅用于 `ConsequenceStage` 渲染符号**，渲染后即弃，绝不写入 `RunState` 持久字段或 `SaveManager`。

### 6.3 SaveManager 内容（出盘，MVP 轻量）

```json
{
  "saveVersion": 1,
  "mastery": { "s01-shake-the-hive": 3, "s03-...": 2 },   // S7 轻量掌握度 0–3
  "visited": { "s01_scene_01": true },                     // 场景完成标记（S8 显示）
  "settings": { "fontScale": 1.0 }
}
```

- **明确不出盘**：`relationshipSignal`、任何 S9 关系账户数值（MVP 本就无 S9）。
- 用 `user://`（各平台沙盒路径）写入；iOS/Android 均可用，无需网络/账号。

### 6.4 S8 导航元数据（独立索引，不污染场景 Schema）

`skills_index.json`（架构新增建议，非场景 Schema 字段）：

```json
{
  "skills": [
    { "id": "s01-shake-the-hive", "title": "不批评 / 打翻蜂巢",
      "section": 1, "order": 1, "scenes": ["s01_scene_01","s01_scene_02"] },
    { "id": "s03-...", "title": "显要感 / 自重感", "section": 1, "order": 3, ... }
  ]
}
```

- S8 只读此索引渲染地图；切片期含 s01/s03/s04（G5 已决）。**不要求修改 `内容数据schema.md`**。

---

## 7. 关键技术决策索引（详见 adr.md）

| ADR | 主题 | 结论（状态） |
|---|---|---|
| ADR-001 | 数据驱动 vs 硬编码 | 全面数据驱动，Schema 即契约（Accepted） |
| ADR-002 | JSON 文件加载方式 | 每技能 `.json` + `FileAccess` + `JSON.parse_string`，UTF-8 去 BOM（Accepted） |
| ADR-003 | 竖屏单屏卡对话树 | 线性单屏卡，MVP 不做分支叙事树（Accepted） |
| ADR-004 | 无脚本静态查表 | 后果纯数据查表，无分支/随机（Accepted） |
| ADR-005 | 存档范围 | 内存本局态 + 轻量本地掌握度；relationshipSignal 不持久化（Accepted） |

---

## 8. 引擎风险 / 待拍板（详见 architecture-review.md 与回传摘要）

- **R1（最高优先）**：Godot 默认字体无 CJK 字形，必须导入并设为默认（否则中文全为豆腐块）。
- **R2**：Windows 下 JSON 可能带 BOM，需在解析前剥离。
- **R3（缺口）**：Godot 4.3 不自动处理刘海安全区，需 `ui_adapter` 读取安全区内边距（已按 4.3 确认，见 architecture-review R3）。
- **R4**：JSON 解析错误需取 `get_error_line()/get_error_message()` 定位（Godot 4.3：`JSON.new().parse_string` 实例方法后读取）。
- **版本已锁定**：本架构按 **Godot 4.3** 复核。安全区 API 与 JSON 错误读取接口（`JSON.new().parse_string` 后取 `get_error_line()`/`get_error_message()`）均按 4.3 实现，无未决版本缺口。
- 剩余待拍板项（G6–G8）见 `control-list.md` §G；G1–G5 已决（Godot 4.3 / 方案A / npc.line / schemaVersion / 含 s04）。
