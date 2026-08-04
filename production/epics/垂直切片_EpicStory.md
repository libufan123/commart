# 垂直切片 Epic / Story 拆分 · 沟通技能游戏（Godot 4.3 · 竖屏 · Lean）

> **Owner**：engineering-lead（程基岩）
> **阶段**：Phase 4 预制作（pre-production）实现拆分
> **引擎基线**：Godot 4.3（已锁定；安全区 / JSON 错误 API 按 4.3 复核）
> **平台**：iOS / Android 移动端，竖屏优先（基准 1080×1920，9:16，仅竖屏）
> **评审强度**：Lean
> **切片范围**：s01 不批评（×2）+ s03 显要感（×2）+ s04 真诚赞赏（×1），共 5 场景
> **上游依据**：`docs/architecture/engin-architecture.md` · `docs/architecture/adr.md` · `docs/architecture/control-list.md` · `docs/architecture/architecture-review.md` · `design/gdd/系统设计_系统拆解.md` · `design/gdd/垂直切片GDD_s01_s03_s04.md` · `design/gdd/内容数据schema.md`

---

## 0. 排期与红项总览

### 0.1 红项（阻塞）编排表
> 控制清单中标注【红·阻塞】或【红·代码评审卡点】的项，**必须**在对应 Epic 中落地并通过验收，否则下游不可进入 Phase 4 实现就绪。

| 红项 | 含义 | 落地 Epic / Story | 类型 |
|---|---|---|---|
| **A4** | UTF-8 BOM 剥离（`EF BB BF`） | E1-S1 | 阻塞 |
| **B1** | CJK 字体导入（Noto Sans SC / Source Han Sans，授权确认） | E0-S2 | 阻塞·最高优先 |
| **B2** | `portrait_theme.tres` `default_font` 指向 CJK，全 Label/Button 继承 | E0-S2 | 阻塞·最高优先 |
| **B3** | iOS/Android 真机中文渲染验证（非豆腐块） | E6-S2（建议 Sprint 1 内做真机 smoke） | 阻塞 |
| **C4** | `ui_adapter` 读取设备安全区内边距并施加根 Margin | E0-S3（适配器）+ E6-S3（真机验证） | 阻塞·缺口 R3 |
| **E2** | `relationshipSignal` 仅渲染不持久化 | E3-S4（渲染）+ E4-S4（存档白名单） | 代码评审卡点 |
| **E4** | 代码评审确认 `relationshipSignal` / 任何 S9 数值未写入存档 | E4-S4 | 代码评审卡点 |

> **一致性说明**：任务简报把 A6/A7/A8/A9/A10 一并列为 E1 红项，但 `control-list.md` 中 A6–A10 实为【绿】。本文以控制清单为权威，按真实色标标注：A4=红，A6/A7/A8/A9/A10=绿。E1 仍**包含**全部 A6–A10 工作，只是不阻塞。

### 0.2 估点说明
- 采用 Lean 粗略斐波那契：**1 / 2 / 3 / 5 / 8**（8≈跨多系统或真机依赖）。
- 估点为**相对工作量**，非人日；用于排 Sprint 池，不用于精确承诺。

### 0.3 Epic 估点汇总

| Epic | 一句话目标 | 估点合计 | 含红项 |
|---|---|---:|---|
| **E0 工程地基** | Godot 4.3 竖屏工程 + CJK 默认字体 + 安全区适配 + 容器骨架 | 16 | B1/B2、C4 |
| **E1 数据层 S1** | DataLoader + ScenarioValidator + 类型封装 + skills_index | 19 | A4 |
| **E2 场景引擎 S2 + 触发识别 S3** | 场景卡渲染 + 触发硬闸门 + miss 演出接线 | 16 | — |
| **E3 抉择 S4 + 后果 S5** | 选项面板 + 静态查表 + forceBoundary + 关系信号仅渲染 | 13 | E2 |
| **E4 复盘 S6 + 导航 S8 + 掌握度 S7 + SaveManager** | 复盘/地图/掌握度/轻量存档（禁持久化关系信号） | 15 | E4 |
| **E5 切片内容数据** | 5 场景 JSON + skills_index 字段核对交付清单 | 8 | — |
| **E6 集成与竖屏真机验收** | 六屏跑通 + 真机中文/安全区 + Lean 预制作门 | 14 | B3、C4 |
| **合计** | | **≈101** | |

> **数据文件粒度约定（需主理人/设计侧确认，非阻塞）**：ADR-002 文字为「每技能一个 `.json`」，但其同条又写「一个文件 = 一个 Scenario 对象」，且 `内容数据schema.md` 示例为**单个 Scenario 对象**。本拆分默认采用**按场景单文件**（`res://data/scenarios/s01_scene_01.json` … `s04_scene_01.json` 共 5 个），理由：① 与 Schema 示例一致；② 「新增场景只增数据、独立 diff/review」最契合；③ DataLoader 枚举目录天然支持。若设计侧坚持按技能聚合（每文件含场景数组），`DataLoader` 需在枚举后增加「数组展开」一步（E1-S1 内标注为可选分支），不破坏其他系统。

---

## E0 · 工程地基

**目标**：在 Godot 4.3 上搭好可运行、可竖屏、中文可读、安全区不遮挡的空工程骨架，使 E1+ 能在其上加载数据并渲染。

**依赖**：无（Phase 4 起点）。

### E0-S1 · Godot 4.3 竖屏工程初始化
- **用户故事**：作为工程，我希望初始化一个锁定 Godot 4.3 的项目并按竖屏配置 `project.godot`，以便下游系统继承统一的竖屏单屏基线。
- **对应系统·文档条款**：`engin-architecture` §5（project.godot）、ADR-003、控制清单 C1/C2。
- **验收标准**
  - [ ] `project.godot` 含 `display/window/size/viewport_width=1080` 与 `viewport_height=1920`
  - [ ] `display/window/handheld/orientation="portrait"`，横屏被禁用（C1）
  - [ ] `stretch/mode="canvas_items"` + `aspect="expand"`（C2）
  - [ ] 新建空 `Main.tscn` 能在该配置下启动
- **估点**：3
- **红项**：无（C1/C2 为绿）

### E0-S2 · CJK 字体导入并设为默认字体 ★红项 B1/B2
- **用户故事**：作为工程，我希望将 Noto Sans SC（或 Source Han Sans）导入工程并设为 `portrait_theme.tres` 的 `default_font`，以便所有中文文案在 Label/Button 正常渲染、不出现豆腐块。
- **对应系统·文档条款**：`assets/fonts/NotoSansSC-Regular.ttf`、`scripts/theme/portrait_theme.tres`、`engin-architecture` §5.2、架构评审 R1（最高优先）、控制清单 **B1/B2（红）**。
- **验收标准**
  - [ ] 字体文件落位 `res://assets/fonts/NotoSansSC-Regular.ttf`（或经授权的等价 CJK 字体）
  - [ ] 字体授权范围确认（关联 G8 资产阻塞，由 art/eng 协同；未确认前不阻塞工程导入，但真机分发前须 closing）
  - [ ] `portrait_theme.tres` 的 `default_font` 指向该字体资源
  - [ ] 所有 `Label`/`Button` 通过主题继承默认字体（无单独覆盖到无 CJK 字体的情形）
  - [ ] 编辑器内放置含中文的 Label，渲染为非豆腐块（为 B3 真机验证的前置）
- **估点**：5
- **红项**：**B1、B2（红·最高优先）** — 必须最早落地

### E0-S3 · 安全区适配 ★红项 C4
- **用户故事**：作为工程，我希望 `ui_adapter.gd` 在运行时读取设备安全区（刘海/圆角/手势条）内边距并施加到根 `MarginContainer`，以便真机 UI 不被遮挡。
- **对应系统·文档条款**：`scripts/ui/ui_adapter.gd`、`engin-architecture` §5.2（R3 缺口）、控制清单 **C4（红·缺口 R3）**。
- **验收标准**
  - [ ] `ui_adapter.gd` 经 `DisplayServer.get_safe_area()`（4.3 已复核的 API）取得安全区，换算为根 Margin 的上下左右内边距
  - [ ] 根 `MarginContainer`（六屏共用）的 custom margins 由该适配器动态设置，不写死像素
  - [ ] 编辑器内以「带安全区」布局验证顶部/底部不被裁切（真机验证见 E6-S3）
  - [ ] 安全区读取集中在该单点，其他系统不直接调用 `DisplayServer`
- **估点**：5
- **红项**：**C4（红·缺口 R3）**

### E0-S4 · 容器化布局骨架
- **用户故事**：作为工程，我希望用容器（Margin/VBox/Scroll）搭出六屏互斥布局骨架，以便后续面板只填内容、不处理坐标。
- **对应系统·文档条款**：`scenes/play/PlaySession.tscn` + `scenes/components/*`、`engin-architecture` §2/§5.2、控制清单 C3/C5/C6。
- **验收标准**
  - [ ] `PlaySession.tscn` 根节点为 `Node`，含六个子面板容器槽位（场景卡/识别/选择/后果/复盘/地图），一次只显一个
  - [ ] `TagButton.tscn` / `ChoiceCard.tscn` / `Bubble.tscn` / `RelationshipGlyph.tscn` 占位场景建立，最小可点高度 ≥ 44pt/48dp（C5）
  - [ ] 复盘 `ReviewPanel.tscn` 长文用 `ScrollContainer`（C3）
  - [ ] 单局六屏在 1080×1920 基准下均单屏可达（C6，性能留待 E6）
- **估点**：3
- **红项**：无（C3/C5/C6 为绿）

**E0 验收汇总**：空工程可在编辑器按竖屏启动；中文非豆腐块；安全区适配器就位；六屏骨架互斥显示。→ 解锁 E1。

---

## E1 · 数据层 S1

**目标**：实现数据驱动加载/校验/类型封装管线，使「场景 = 一条数据记录」成为 S2–S8 唯一事实源，满足约束 1/2/4 与 ADR-001/002。

**依赖**：E0（主题与目录存在）。

### E1-S1 · DataLoader Autoload：枚举 + 读取 + 去 BOM ★红项 A4
- **用户故事**：作为系统，我希望 `DataLoader`（Autoload）在 `_ready` 枚举 `res://data/scenarios/*.json`、读文件并剥离 BOM 后解析，以便 S2–S8 拿到干净数据。
- **对应系统·文档条款**：`scripts/autoload/DataLoader.gd`、`engin-architecture` §4、`adr.md` ADR-002、控制清单 **A4（红）** / A3（绿）。
- **验收标准**
  - [ ] 枚举 `res://data/scenarios/` 下全部 `.json`（支持按场景单文件；若为每技能数组则含展开分支）
  - [ ] 读取采用字节级剥 BOM：首 3 字节为 `EF BB BF` 则 `slice(3)` 后 `get_string_from_utf8()`（优先此路径；若用 `get_file_as_string` 则检测首字符 `\uFEFF` 并剔除）
  - [ ] 解析用 `JSON.new().parse_string(text)`（禁用已弃用 `parse_json`）
  - [ ] 通过 `DataLoader.get_scenario(id)` 供 S2–S8 取数，禁止直接 `FileAccess` 读盘（A10，绿）
  - [ ] `skills_index.json` 一并加载（见 E1-S5）
- **估点**：5
- **红项**：**A4（红·BOM 剥离）**

### E1-S2 · JSON 解析错误精确定位（A8，绿）
- **用户故事**：作为工程，我希望解析失败时拿到「文件:行:信息」，以便坏数据可快速定位。
- **对应系统·文档条款**：`JSON.new().parse_string` 后取 `get_error_line()` / `get_error_message()`、架构评审 R4、控制清单 A8（绿）。
- **验收标准**
  - [ ] 解析失败调用 `json.get_error_line()` / `json.get_error_message()` 并 `push_error("文件:行:信息")`
  - [ ] 错误位置与真实 JSON 行号一致（可用一行带语法错误的 fixture 验证）
- **估点**：3
- **红项**：无（A8 绿）

### E1-S3 · ScenarioValidator：约束4 校验（A6/A7，绿）
- **用户故事**：作为系统，我希望 `ScenarioValidator` 在加载期校验字段契约，以便坏数据在运行时前被发现或安全降级。
- **对应系统·文档条款**：`scripts/core/ScenarioValidator.gd`、`内容数据schema.md` §5 校验规则、约束4、控制清单 A6/A7（绿）。
- **验收标准**
  - [ ] `triggers.correct ∈ triggers.candidates`（A6）
  - [ ] `choices` 含 ≥1 个 `type=="skilled"`（A6）
  - [ ] 必填字段齐全（`id/skill/title/context/npc{name,role,mood}/impulse/triggers{candidates,correct}/choices[]/review{mechanism,migration}`）（A6）
  - [ ] `review.case` 缺失 → **放行并标记**（运行时 `ReviewPanel` 仅渲染 mechanism+migration），不崩溃（A7 / 约束4 / E5）
  - [ ] `triggers.miss` 若存在，须与 `consequence` 同构（`npcReaction`/`relationshipSignal`/`judgement`）——同构校验（约束4 / G2 方案A）
- **估点**：5
- **红项**：无（A6/A7 绿）

### E1-S4 · scenario_types 类型封装
- **用户故事**：作为系统，我希望用 `scenario_types.gd` 把原始 `dict` 封装为 `Scenario/Trigger/Choice/Consequence/Review` 类型对象，以便 S2–S8 消费强类型字段而非裸字典。
- **对应系统·文档条款**：`scripts/core/scenario_types.gd`、`engin-architecture` §2 core/。
- **验收标准**
  - [ ] 提供 `Scenario`、`Trigger`、`Choice`、`Consequence`、`Review` 类型（或一致的 Dictionary 契约封装）
  - [ ] 所有字段访问经封装对象，避免散落 `dict["key"]`
  - [ ] `consequence.relationshipSignal` 暴露为只读展示字段
- **估点**：2
- **红项**：无

### E1-S5 · 加载 skills_index.json（S8 元数据）
- **用户故事**：作为系统，我希望 `DataLoader` 加载 `res://data/skills_index.json`，以便 S8 按篇浏览技能/场景而不污染场景 Schema。
- **对应系统·文档条款**：`data/skills_index.json`、`engin-architecture` §6.4、控制清单 F3（绿）。
- **验收标准**
  - [ ] `skills_index.json` 解析后存入内存索引
  - [ ] 结构为 `{ skills:[{id,title,section,order,scenes[]}] }`，与场景 Schema 解耦
  - [ ] 切片期含 `s01-shake-the-hive` / `s03-sense-of-importance` / `s04-genuine-praise-standard`（G5 含 s04）
- **估点**：2
- **红项**：无

### E1-S6 · strict/release 分流 + 单一入口（A9/A10，绿）
- **用户故事**：作为工程，我希望开发期校验失败 `push_error`+跳过、发布期日志+跳过（不崩溃），以便不同环境有不同严格度。
- **对应系统·文档条款**：`engin-architecture` §4.1、控制清单 A9/A10（绿）。
- **验收标准**
  - [ ] 开发（strict）模式：校验/解析失败 `push_error` 并跳过该文件
  - [ ] 发布（release）模式：记录日志并跳过，游戏继续运行不崩溃
  - [ ] S2–S8 全部经 `DataLoader.get_scenario(id)`，无 `FileAccess` 直读（A10）
- **估点**：2
- **红项**：无（A9/A10 绿）

**E1 验收汇总**：向 `DataLoader` 投一个带 BOM 的合法 JSON 能正确加载；一个 `correct∉candidates` 的 JSON 在 strict 下被 `push_error`；`review.case` 缺失的 JSON 不崩溃。→ 解锁 E2。

---

## E2 · 场景引擎 S2 + 触发识别 S3

**目标**：渲染场景卡（含 NPC 末句），并以触发识别作为抉择的硬闸门，识别错按方案A演出 `triggers.miss`。

**依赖**：E1（数据可加载）。

### E2-S1 · 场景卡渲染 S2（D1，G3 npc.line）
- **用户故事**：作为玩家，我希望在场景卡看到情境背景、对方最后一句（`npc.line`）与我的冲动气泡，以便进入识别前先读懂处境。
- **对应系统·文档条款**：`scenes/play/ScenarioCard.tscn` + `scripts/systems/ScenarioEngine.gd`、`engin-architecture` §3、控制清单 D1、G3（npc.line 已决）。
- **验收标准**
  - [ ] 渲染 `context` + `impulse` 气泡
  - [ ] 若 `npc.line` 存在则渲染 NPC 末句气泡；缺失则仅 `context`+`impulse`（G3 降级）
  - [ ] 文案全部来自 `Scenario` 数据，无硬编码场景文案（A1，绿）
  - [ ] 单屏竖屏呈现，3 分钟内可进入识别（S2 验收）
- **估点**：5
- **红项**：无

### E2-S2 · 触发识别面板 S3（D2/D3）
- **用户故事**：作为玩家，我希望看到 2–4 个候选标签并可点选，以便表达我对处境的诊断。
- **对应系统·文档条款**：`scenes/play/TriggerPanel.tscn` + `scripts/systems/TriggerSystem.gd`、`engin-architecture` §3、控制清单 D2/D3。
- **验收标准**
  - [ ] 渲染 `triggers.candidates` 为 `TagButton[]`
  - [ ] 点选后 `TriggerSystem` 校验并判定 `selected_trigger == triggers.correct`
  - [ ] 由识别结果派生「解锁选项集」交给 `ChoiceSystem`（S3→S4 硬闸门数据来源）
- **估点**：5
- **红项**：无

### E2-S3 · PlaySession 状态机硬闸门（D2）
- **用户故事**：作为系统，我希望 `PlaySession` 在 S3 未完成前不显示可操作的 `ChoicePanel`，以便「未识别不可进入有效抉择」。
- **对应系统·文档条款**：`scenes/play/PlaySession.tscn`、`engin-architecture` §3、控制清单 D2、P3 支柱。
- **验收标准**
  - [ ] 状态机顺序强制 S2→S3→S4→S5→S6，一次一屏
  - [ ] 未确认触发识别前，`ChoicePanel` 选项不可交互（闸门生效）
- **估点**：3
- **红项**：无

### E2-S4 · 识别错→triggers.miss 演出接线（D3，E1，G2 方案A）
- **用户故事**：作为玩家，我希望识别错误时直接看到清晰可感知的错位后果（`triggers.miss`），以便自行发现「我没看清情况」。
- **对应系统·文档条款**：`scripts/systems/ConsequenceEngine.gd`（E3 实现，此处接线）、`engin-architecture` §3/§6.2、`内容数据schema.md` R-gap-1（G2 方案A 已决）、控制清单 D3、边缘 E1。
- **验收标准**
  - [ ] `selected_trigger != triggers.correct` 时，`PlaySession` 进入后果演出并**优先播放 `triggers.miss`**
  - [ ] `triggers.miss` 缺省时回退到所选 choice 的 `consequence`，不崩溃（E1 降级）
  - [ ] 识别正确时按正常所选 choice 的 `consequence` 演出，不受影响
- **估点**：5（跨 E2/E3 接线，记在 E2 闸门侧）
- **红项**：无（E1 降级逻辑本身为绿，仅体验正确性要求）

**E2 验收汇总**：从场景卡读到 `npc.line`；不识别不能选；识别错播放 `miss`。→ 解锁 E3。

---

## E3 · 抉择 S4 + 后果 S5

**目标**：渲染真实语气的选项，按所选 choice 静态查表演出后果；边界强制路由；关系信号仅渲染不持久化。

**依赖**：E2（选项集已派生）。

### E3-S1 · 抉择面板 S4（D4）
- **用户故事**：作为玩家，我希望看到 2–4 句「真实会说的话」作为选项（熟练/陷阱/边界），且样式不标对错，以便我按真实情境选择。
- **对应系统·文档条款**：`scenes/play/ChoicePanel.tscn` + `scripts/systems/ChoiceSystem.gd`、`engin-architecture` §3、控制清单 D4。
- **验收标准**
  - [ ] 选项文本来自 `choices[].text`，写成真实回应（不写技能标签）
  - [ ] 选项样式不暴露 `type`（skilled/trap/boundary）对错
  - [ ] 捕获 `chosen_choice_id` 与 `chosen_type` 写入 `RunState`（仅内存）
- **估点**：3
- **红项**：无

### E3-S2 · 后果引擎 S5 静态查表（D5，ADR-004）
- **用户故事**：作为系统，我希望 `ConsequenceEngine` 直接取所选 choice 的 `consequence` 渲染，以便后果由数据说话、无隐藏逻辑。
- **对应系统·文档条款**：`scenes/play/ConsequenceStage.tscn` + `scripts/systems/ConsequenceEngine.gd`、ADR-004、控制清单 D5。
- **验收标准**
  - [ ] 仅做「取所选 `consequence` → 渲染 `npcReaction` + `judgement`」映射，无分支/随机
  - [ ] 数据层无 `if`/条件键/随机种子/表达式（约束5）
- **估点**：3
- **红项**：无

### E3-S3 · 边界强制 E2（D6，forceBoundary）
- **用户故事**：作为系统，我希望当场景标记 `forceBoundary:true` 时，引擎确定性路由到 boundary 后果，以便不奖励「软化」违规。
- **对应系统·文档条款**：`ConsequenceEngine.gd`、ADR-004（唯一引擎级确定性规则）、控制清单 D6、边缘 E2。
- **验收标准**
  - [ ] `forceBoundary==true` 时，无论所选 choice `type` 为何，后果路由到 boundary 选项 `consequence`
  - [ ] 该路由为固定确定性行为（非数据脚本），不改数据即生效
- **估点**：3
- **红项**：无

### E3-S4 · 关系信号仅渲染不持久化 ★红项 E2（评审卡点）
- **用户故事**：作为系统，我希望 `relationshipSignal` 仅在 `ConsequenceStage` 渲染符号（-/0/+），渲染后即弃，以便满足「不持久化」。
- **对应系统·文档条款**：`scenes/components/RelationshipGlyph.tscn`、`RunState.gd`、`engin-architecture` §6.2、ADR-005、控制清单 **E2（红·评审卡点）**、边缘（关系信号展示）。
- **验收标准**
  - [ ] `ConsequenceEngine` 从所选 `consequence.relationshipSignal` 取 -1/0/+1 仅供 `RelationshipGlyph` 渲染
  - [ ] 渲染后不写入 `RunState` 持久字段，更不出盘
  - [ ] 代码评审确认无 `relationshipSignal` 落盘路径（联合 E4-S4）
- **估点**：2
- **红项**：**E2（红·代码评审卡点）**

### E3-S5 · 安全失败 E3（D8）
- **用户故事**：作为玩家，我希望重复选 trap 也只照常反噬、不封锁不扣分，以便我能安全试错。
- **对应系统·文档条款**：`ChoiceSystem.gd`/`ConsequenceEngine.gd`、`engin-architecture` §6、控制清单 D8、边缘 E3。
- **验收标准**
  - [ ] 同场景连续两次选 trap：后果照常、复盘照常展开
  - [ ] 不封锁、不扣分、重练无冷却
- **估点**：2
- **红项**：无

**E3 验收汇总**：选项真实不标对错；后果纯查表；`forceBoundary` 强制边界；关系信号只显示不存储；重复陷阱安全失败。→ 解锁 E4。

---

## E4 · 复盘 S6 + 导航 S8 + 掌握度 S7 + SaveManager

**目标**：完成复盘面板、技能地图导航、轻量掌握度，以及仅含 mastery/visited/settings 的本地存档（明确排除关系信号）。

**依赖**：E3（后果演出产出复盘输入）；E1-S5（skills_index 已加载）。

### E4-S1 · 复盘面板 S6（D7，A7 降级）
- **用户故事**：作为玩家，我希望在复盘看到机制+真实案例+迁移线索，并能「再练一次/下一场景」，以便把体验转成可迁移认知。
- **对应系统·文档条款**：`scenes/play/ReviewPanel.tscn` + `scripts/systems/ReviewSystem.gd`、`engin-architecture` §3、控制清单 D7、A7（review.case 缺失降级）、P1 不说教。
- **验收标准**
  - [ ] 渲染 `review.mechanism` + `review.migration`；`review.case` 存在则渲染、缺失则跳过（A7 降级）
  - [ ] 文案用「X 身上发生过」案例，无「你必须」口吻、无额外伦理批注（P2 已移除，验收 §8(4)）
  - [ ] 提供「再练一次 / 下一场景」按钮，触发 `PlaySession` 状态机跳转
- **估点**：3
- **红项**：无

### E4-S2 · 技能地图导航 S8（F1，G5 含 s04）
- **用户故事**：作为玩家，我希望从主页进入技能地图，按篇浏览并进入 s01/s03/s04 场景，以便有轻量导航。
- **对应系统·文档条款**：`scenes/menus/SkillMap.tscn` + `scripts/systems/SkillMap.gd`、`engin-architecture` §6.4、控制清单 F1/F3、G5（含 s04 已决）。
- **验收标准**
  - [ ] `SkillMap.gd` 读 `skills_index.json` 渲染入口，含 s01/s03/s04 三技能
  - [ ] 导航元数据走独立索引，不污染场景 Schema（F3）
  - [ ] 完成标记（visited）在地图上以小标记显示（接 E4-S4）
- **估点**：3
- **红项**：无

### E4-S3 · 轻量掌握度 S7（F2，公式 4.2）
- **用户故事**：作为系统，我希望按技能记录 0–3 档掌握度（完成全部场景+至少一次 skilled+读过复盘→3），以便地图有轻反馈而无分数压力。
- **对应系统·文档条款**：`scripts/systems/MasterySystem.gd`、垂直切片 GDD §4.2、控制清单 F2。
- **验收标准**
  - [ ] 掌握度仅 0–3 档，无 meter、无数值压力
  - [ ] 判定逻辑按 GDD §4.2（完成全部场景 && 至少一次 skilled && 读过复盘 → 3）
  - [ ] 结果入 `SaveManager` 的 `mastery`
- **估点**：3
- **红项**：无

### E4-S4 · SaveManager 轻量存档 + 禁持久化 ★红项 E4（评审卡点）
- **用户故事**：作为系统，我希望 `SaveManager` 仅把 `mastery/visited/settings` 写入 `user://save_v1.json`，并**永不**写入 `relationshipSignal` 或任何 S9 数值，以便严格满足存档范围。
- **对应系统·文档条款**：`scripts/autoload/SaveManager.gd`、`engin-architecture` §6.3、ADR-005、控制清单 **E3/E4（E4 红·评审卡点）**。
- **验收标准**
  - [ ] 存档结构为 `{ saveVersion, mastery, visited, settings }`，写入 `user://save_v1.json`
  - [ ] 存档**不含** `relationshipSignal` 或任何 S9 关系账户字段（白名单写入，非黑名单）
  - [ ] `saveVersion` 带版本号，与数据 `schemaVersion` 解耦（E5 蓝·建议）
  - [ ] 代码评审卡点：确认 `relationshipSignal` 未进存档（联合 E3-S4 的 E2）
- **估点**：5
- **红项**：**E4（红·代码评审卡点）**，并保障 **E2（关系信号不持久化）** 端到端成立

### E4-S5 · 主菜单入口
- **用户故事**：作为玩家，我希望从 `MainMenu` 进入技能地图或继续上次进度，以便有统一入口。
- **对应系统·文档条款**：`scenes/Main.tscn` + `scenes/menus/MainMenu.tscn`、S8 入口。
- **验收标准**
  - [ ] `MainMenu` 提供「开始/继续」并接线 `SkillMap` 与 `data_ready` 信号
  - [ ] `DataLoader` 就绪前入口不可用（防空数据进入）
- **估点**：1
- **红项**：无

**E4 验收汇总**：复盘三段+降级；地图含三技能；掌握度 0–3；存档无关系信号。→ 与 E5 数据打通后做 E6。

---

## E5 · 切片内容数据（交付清单）

**目标**：定义 5 场景 + skills_index 的**交付清单与字段核对**，实际 JSON 内容由 design 侧提供，工程负责按 Schema 逐字段核对验收。

**依赖**：E1（Schema 契约与校验器已就绪，可用于核对）。

### E5-S1 · s01 ×2 场景数据核对
- **用户故事**：作为工程，我希望拿到 `s01_scene_01` / `s01_scene_02` 的 JSON 并对照 Schema 核对，以便数据可经本院 Validator 通过。
- **对应系统·文档条款**：`res://data/scenarios/s01_scene_01.json` / `s01_scene_02.json`、`内容数据schema.md`、`垂直切片GDD` §2 场景清单。
- **验收标准**
  - [ ] 两文件字段齐全（`skill="s01-shake-the-hive"`、`triggers.correct∈candidates`、≥1 `skilled`、含 `triggers.miss`）
  - [ ] `s01_scene_02` 体现「识别+陷阱变体」
  - [ ] 经 `ScenarioValidator` 全绿（不触发 strict `push_error`）
- **估点**：2
- **红项**：无（数据由 design 提供；此处为核对，交付责任在 design-strategist）

### E5-S2 · s03 ×2 场景数据核对
- **用户故事**：作为工程，我希望拿到 `s03_scene_01` / `s03_scene_02` 的 JSON 并核对，以便 s03 切片可玩。
- **对应系统·文档条款**：`res://data/scenarios/s03_scene_01.json` / `s03_scene_02.json`（`skill="s03-sense-of-importance"`，最终 id 以设计侧 `.json` 中 `skill` 字段为准）。
- **验收标准**
  - [ ] 两文件字段齐全；体现「诊断→操作」双子循环（s03_scene_01）与「供给具名化」（s03_scene_02）
  - [ ] 含 `triggers.miss`，经 Validator 全绿
- **估点**：2
- **红项**：无

### E5-S3 · s04 ×1 场景数据核对
- **用户故事**：作为工程，我希望拿到 `s04_scene_01` 的 JSON 并核对，以便「供给侧生成」交互可见。
- **对应系统·文档条款**：`res://data/scenarios/s04_scene_01.json`（`skill="s04-genuine-praise-standard"`）、垂直切片 GDD §2.5。
- **验收标准**
  - [ ] 字段齐全；含 `triggers.miss`；`forceBoundary` 路径（严重错误不得假夸）配置到位
  - [ ] 经 Validator 全绿
- **估点**：2
- **红项**：无

### E5-S4 · skills_index.json 切片元数据
- **用户故事**：作为工程，我希望 `skills_index.json` 含切片三技能的 `scenes` 映射，以便 S8 正确列出入口。
- **对应系统·文档条款**：`res://data/skills_index.json`、`engin-architecture` §6.4、G5。
- **验收标准**
  - [ ] 含 `s01-shake-the-hive`（scenes: s01_scene_01/02）、`s03-sense-of-importance`（scenes: s03_scene_01/02）、`s04-genuine-praise-standard`（scenes: s04_scene_01）
  - [ ] `section/order` 与第 1 篇一致
- **估点**：2
- **红项**：无

**E5 验收汇总**：5 场景 JSON + skills_index 全部经 `ScenarioValidator` 零报错，且与 GDD 场景清单一致。

---

## E6 · 集成与竖屏真机验收

**目标**：六屏端到端跑通、单局 ≤3 分钟，并在真机验证中文渲染与安全区，达成 Lean 预制作门。

**依赖**：E0–E5 全部完成。

### E6-S1 · 六屏端到端跑通（≤3 分钟/局）
- **用户故事**：作为玩家，我希望从场景卡到复盘再到再练/下一场景完整跑通，且单局 ≤3 分钟，以便验证核心循环。
- **对应系统·文档条款**：全系统、`垂直切片GDD` §8 验收(1)(8)、控制清单 C6/D1–D9。
- **验收标准**
  - [ ] s01/s03/s04 各至少 1 场景完整闭环（场景卡→识别→抉择→后果→复盘→再练）
  - [ ] 单局（含阅读）≤3 分钟，六屏单屏可达
  - [ ] 无硬编码文案（数据驱动验收 §8(6)）
- **估点**：3
- **红项**：无

### E6-S2 · 真机中文渲染验证 ★红项 B3
- **用户故事**：作为工程，我希望在 iOS/Android 真机确认中文非豆腐块，以便满足 R1 最高优先硬阻塞。
- **对应系统·文档条款**：B1/B2 落地的真机验证、`engin-architecture` §5.2、控制清单 **B3（红）**。
- **验收标准**
  - [ ] iOS 真机 + Android 真机中文场景卡/复盘/UI 均正常渲染
  - [ ] 模拟器通过**不**作为唯一验证（必须有至少一台真机证据）
  - [ ] （建议）此 smoke 提前到 Sprint 1 末执行，越晚发现字体缺失成本越高
- **估点**：5
- **红项**：**B3（红·真机）**

### E6-S3 · 真机安全区验证 ★红项 C4
- **用户故事**：作为工程，我希望在带刘海/手势条的真机上确认 UI 不被遮挡，以便满足 C4。
- **对应系统·文档条款**：`ui_adapter.gd` 真机验证、`engin-architecture` §5.2、控制清单 **C4（红）**。
- **验收标准**
  - [ ] 真机（含异形屏）顶部/底部/侧边 UI 在安全区内，无裁切
  - [ ] 横屏不可触发（仅竖屏）
- **估点**：3
- **红项**：**C4（红·真机验证，适配器已在 E0-S3 落地）**

### E6-S4 · Lean 预制作门
- **用户故事**：作为工程，我希望按 GDD §8 八条验收 + 控制清单全红项清零，以便声明 Phase 4 实现就绪。
- **对应系统·文档条款**：`垂直切片GDD` §8 八条、`docs/architecture/control-list.md` 验收口径。
- **验收标准**
  - [ ] 八条验收全满足：可玩闭环 / P3 闸门有效 / 陷阱真实 / P1 不说教 / 边缘覆盖 E1–E3 / 数据驱动 / 轻量反馈 / 竖屏可达
  - [ ] 控制清单全部【红】项清零（A4/B1/B2/B3/C4/E2/E4）
  - [ ] G1–G5 决策落地（Godot 4.3 / 方案A / npc.line / schemaVersion / 含 s04）
- **估点**：3
- **红项**：汇总门（含 B3/C4/E2/E4 真机/评审）

**E6 验收汇总**：六屏跑通 + 真机中文 + 真机安全区 + 八条验收 + 全红项清零 = Phase 4 实现就绪。

---

## 附录 A · 红项 ↔ Epic 追溯矩阵

| 红项 | E0 | E1 | E2 | E3 | E4 | E5 | E6 |
|---|---|---|---|---|---|---|---|
| A4 BOM | | ✅ S1 | | | | | |
| B1 CJK 导入 | ✅ S2 | | | | | | |
| B2 默认字体 | ✅ S2 | | | | | | |
| B3 真机中文 | | | | | | | ✅ S2 |
| C4 安全区 | ✅ S3 | | | | | | ✅ S3 |
| E2 关系信号不持久化 | | | | ✅ S4 | ✅ S4(保障) | | ✅ S4(门) |
| E4 禁出盘 | | | | | ✅ S4 | | ✅ S4(门) |

## 附录 B · 与上游的一致性承诺
- 系统命名沿用 S1–S8（S9 推迟，不在切片）。
- ADR 编号沿用 ADR-001~005；本拆分不新增 ADR。
- 控制清单红项编号沿用 A4/B1/B2/B3/C4/E2/E4；A6–A10 按控制清单真实色标为绿。
- Schema 字段名（id/skill/title/context/npc{name,role,mood,line?}/impulse/triggers{candidates,correct,miss?}/choices[]{id,type,text,consequence}/review{mechanism,case,migration}/forceBoundary?/schemaVersion?）逐字沿用。
- 路径与类名沿用 `engin-architecture.md` §2：DataLoader.gd / RunState.gd / SaveManager.gd / scenario_types.gd / ScenarioValidator.gd / ScenarioEngine.gd / TriggerSystem.gd / ChoiceSystem.gd / ConsequenceEngine.gd / ReviewSystem.gd / MasterySystem.gd / SkillMap.gd / ui_adapter.gd / portrait_theme.tres。
