# 控制清单 · MVP 实现就绪验收（Control List）

> **Owner**：engineering-lead（程基岩）
> **用途**：供开发（Phase 4/5）与 QA 逐条对照的 MVP 就绪检查项；每条标注对应约束/ADR/系统。
> **原则**：Lean、可执行、一页可扫。通过 = 绿；阻塞 = 红（必须先解）；建议 = 蓝（非阻塞）。
> **版本基线**：**Godot 4.3**（已锁定；安全区/JSON 错误 API 均按 4.3 复核）。

---

## A. 数据层 / 加载（S1，约束1/2/4）

- [ ] **A1 数据驱动** — 全部可玩文案来自 `内容数据schema.md` 结构；systems 脚本中无硬编码场景文案（ADR-001）。【绿】
- [ ] **A2 每技能 .json** — 场景文件位于 `res://data/scenarios/sNN.json`，一个文件 = 一个 Scenario（ADR-002）。【绿】
- [ ] **A3 读取 API** — 用 `FileAccess.get_file_as_string()` + `JSON.new().parse_string()`（禁用已弃用 `parse_json`）。【绿】
- [ ] **A4 BOM 剥离** — 加载前检测并剥离 UTF-8 BOM（`EF BB BF`）（R2）。【红·阻塞】
- [ ] **A5 编码规约** — 所有 `*.json` 以无 BOM UTF-8 入库（CI/提交钩子校验）。【蓝·建议】
- [ ] **A6 加载期校验** — `triggers.correct ∈ candidates`；`choices` 含 ≥1 `skilled`；必填字段齐全（约束4）。【绿】
- [ ] **A7 降级不崩溃** — `review.case` 缺失时 `ReviewPanel` 仅渲染 mechanism+migration，不崩溃（约束4）。【绿】
- [ ] **A8 解析错误定位** — 解析失败打印 `文件:行:get_error_message()`（R4）。【绿】
- [ ] **A9 strict/release 分流** — 开发 strict 失败 `push_error`+跳过；release 日志+跳过（不崩溃）。【绿】
- [ ] **A10 单一入口** — S2–S8 仅经 `DataLoader.get_scenario(id)` 取数，无直接 `FileAccess` 读盘（ADR-001）。【绿】

## B. 中文 / 字体（R1，最高优先）

- [ ] **B1 CJK 字体导入** — 导入 Noto Sans SC / Source Han Sans（确认授权）。【红·阻塞】
- [ ] **B2 默认字体** — `portrait_theme.tres` `default_font` 指向 CJK 字体，全 Label/Button 继承。【红·阻塞】
- [ ] **B3 真机渲染验证** — iOS/Android 真机中文正常（非豆腐块）；模拟器不可作为唯一验证。【红·阻塞】

## C. 竖屏 / UI 适配（约束3/ADR-003，R3）

- [ ] **C1 锁定竖屏** — `orientation="portrait"`，禁用横屏。【绿】
- [ ] **C2 拉伸配置** — `stretch mode=canvas_items` + `aspect=expand`，基准 1080×1920。【绿】
- [ ] **C3 容器布局** — 六屏用 Margin/VBox/Scroll 容器，无写死像素坐标；超长复盘用 ScrollContainer。【绿】
- [ ] **C4 安全区** — `ui_adapter` 读取设备安全区内边距并施加根 Margin（刘海/手势条不遮挡）。【红·阻塞·缺口 R3】
- [ ] **C5 触控尺寸** — 可点击元素 ≥ 44×44pt / 48dp（TagButton/ChoiceCard 最小高度）。【绿】
- [ ] **C6 单屏单局** — 六屏互斥显示；单局 ≤3 分钟（切片 GDD §6/§8）。【绿】

## D. 核心循环（S2–S6，约束3/5，ADR-003/004）

- [ ] **D1 场景卡 S2** — 渲染 context + NPC 末句（`npc.line`，G3 已决）+ 冲动气泡。【绿】
- [ ] **D2 触发硬闸门 S3** — 未识别不可进入有效抉择；`PlaySession` 状态机强制顺序。【绿】
- [ ] **D3 识别解锁 S4** — 选项集由 `TriggerSystem` 从识别结果派生；识别错→`ConsequenceEngine` 演出 `triggers.miss`（G2 方案A 已决，E1 错位）。【绿】
- [ ] **D4 抉择 S4** — 2–4 选项写成「真实会说的话」，样式不标对错。【绿】
- [ ] **D5 后果查表 S5** — 纯取所选 `consequence` 静态演出；无分支/随机（ADR-004）。【绿】
- [ ] **D6 边界强制 E2** — `forceBoundary:true` 时引擎确定性路由到 boundary 后果，不奖励软化。【绿】
- [ ] **D7 复盘 S6** — 展开 mechanism+case+migration；「再练一次/下一场景」；无伦理批注（P2 已移除）。【绿】
- [ ] **D8 安全失败 E3** — 重复选 trap 不封锁、不扣分，重练无冷却。【绿】
- [ ] **D9 冲动非闸门 E4** — 冲动气泡仅信息层，不约束选择。【绿】

## E. 状态 / 存档（约束3/6，ADR-005）

- [ ] **E1 RunState 内存** — 当前局 skill/scenario/selected_trigger/chosen_choice 仅内存。【绿】
- [ ] **E2 relationshipSignal 不持久化** — 仅 `ConsequenceStage` 渲染用，不写 RunState 持久字段、不出盘。【红·代码评审卡点】
- [ ] **E3 轻量存档** — `SaveManager` 仅存 mastery/visited/settings 到 `user://save_v1.json`。【绿】
- [ ] **E4 禁止出盘** — 代码评审确认 `relationshipSignal` / 任何 S9 数值未写入存档。【红·代码评审卡点】
- [ ] **E5 存档版本化** — 存档带 `saveVersion`，与数据 `schemaVersion`（顶层可选，缺省 1，G4 已决）解耦。【蓝·建议】

## F. 导航 / 掌握度（S7/S8）

- [ ] **F1 技能地图 S8** — 读 `skills_index.json` 渲染；切片含 s01/s03/s04（G5 已决）。【绿】
- [ ] **F2 掌握度 S7** — 轻量 0–3 档，无分数压力，仅作地图小标记（切片可最简）。【绿】
- [ ] **F3 元数据隔离** — S8 导航元数据走独立索引文件，不污染场景 Schema。【绿】

## G. 待主理人拍板项（阻塞 / 决策）

- [x] **G1 Godot 版本 pin** — **已决：Godot 4.3**（安全区/JSON 错误 API 按 4.3 复核，无未决版本缺口）。
- [x] **G2 R-gap-1 处理** — **已决：采纳方案A**，Schema 增可选 `triggers.miss`（consequence 结构）；`ScenarioValidator`/`ConsequenceEngine` 支持「识别错→演出 miss，miss 缺省→回退，不崩溃」。
- [x] **G3 R-gap-2 处理** — **已决：增可选 `npc.line`**；渲染层在场景卡显示 NPC 末句。
- [x] **G4 R-gap-3 处理** — **已决：增顶层可选 `schemaVersion`（缺省 1）**；Loader 按版本决定校验严格度，为 schema_v2 预留。
- [x] **G5 切片是否含 s04** — **已决：含 s04**（S1 数据量增 s04_scene_01、S8 入口增 s04；具体数据由 design 补，架构层已知晓）。
- [ ] **G6 s05 质量门** — 扩展层是否以 `schema_v2` 字段 reintroduce（概念已定不进 MVP）。【决策·前瞻】
- [ ] **G7 iOS 发布路径** — Mac + Apple 开发者账号签名排期（流程，非技术阻塞）。【排期】
- [ ] **G8 字体授权** — 选定 CJK 字体的分发授权范围确认（art/eng 协同）。【阻塞·资产】

---

## 验收口径

- **MVP 就绪（可进入 Phase 4 实现）** = 所有【红】项清零 + G1–G5 决策落地（G1 Godot 4.3 / G2 方案A / G3 npc.line / G4 schemaVersion / G5 含 s04）。
- **质量门**（QA 终验参考切片 GDD §8 八条）：可玩闭环 / P3 闸门有效 / 陷阱真实 / P1 不说教 / 边缘覆盖（E1–E3）/ 数据驱动 / 轻量反馈 / 竖屏可达。
- 本清单与 `architecture-review.md` 一一对应；状态变更须回写对应 R-/ADR 条目。
