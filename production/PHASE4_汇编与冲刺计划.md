# Phase 4 预制作 · 汇编与冲刺计划

> **汇编人**：主理人 游承峰（Orchestrator）
> **阶段**：Phase 4 预制作（pre-production）收口 → 申请 **Lean 预制作门**
> **切片范围**：s01 不批评（×2）+ s03 显要感（×2）+ s04 真诚赞赏（×1），共 **5 场景**
> **引擎 / 平台 / 评审**：Godot 4.3 / iOS·Android 竖屏 / Lean
> **上游依据**：Phase 1（概念文档 / 美术圣经）、Phase 2（系统拆解 / 垂直切片 GDD / 内容数据 Schema / 跨 GDD 自检）、Phase 3（主架构 / ADR / 架构评审 / 控制清单 / 可访问性分级 / 资产规格）

---

## 1. Phase 4 交付物清单（四份）

| 交付 | Owner | 路径 | 状态 |
|---|---|---|---|
| UX 规格（六屏 wireflow / S3 识别 UX / 导航进度 / Standard 对照 / Lean 延后） | design-strategist | `design/ux/UX规格_垂直切片.md` | ✅ |
| 资产规格（符号/NPC/卡片/UI/纹理预算/给工程约束） | art-director | `docs/art/资产规格.md` | ✅ |
| Epic / Story 拆分（E0–E6 + 红项矩阵 + 估点 ≈101） | engineering-lead | `production/epics/垂直切片_EpicStory.md` | ✅ |
| 测试脚手架（GUT + 首批用例 + Sprint 1 草案 + 最小可玩证据） | engineering-lead | `production/tests/test-scaffolding.md` | ✅ |

> 仅 art-director 的 `资产规格.md` 在上一轮已落盘；本轮回补了缺失的 UX 规格与两份工程文档，四份齐备。

---

## 2. 跨成员一致性核对

| 维度 | 设计（UX/GDD） | 美术（圣经/资产/可访问性） | 工程（架构/Epic/测试） | 结论 |
|---|---|---|---|---|
| **六屏结构** | GDD §6 六屏命名 | — | 架构 §3 节点（ScenarioCard/TriggerPanel/ChoicePanel/ConsequenceStage/ReviewPanel/SkillMap）+ Epic E2–E4 | ✅ 一致 |
| **循环命名** | 识别→抉择→后果 | ◌触发 / ⬡技巧 / ⑂后果（美术圣经 §0） | 符号由 UI 拼接，不写死逻辑 | ✅ 一致 |
| **可访问性** | UX §5 Standard 七项 | Standard 基线（16pt/48·44pt/语义色双编码/双 Theme/Reduce Motion/动态字号/安全区） | 控制清单 C3/C4/C5 + 测试含 `get_safe_area` | ✅ 一致 |
| **系统映射** | S1–S8（S9 推迟） | — | 架构 §2 节点 + Epic E0–E6 + 控制清单 A–F | ✅ 一致 |
| **数据契约** | 内容数据 Schema 字段名 | — | Epic/测试逐字沿用 `id/skill/.../triggers.miss/choices[].consequence/review` | ✅ 一致 |
| **切片 NPC** | 5 场景 persona（小陈/同事/老员工/伴侣/创作者） | 资产规格 §1.2 四+1 persona×3 态 | 美术资产命名与切片场景逐级对应 | ✅ 一致 |
| **支柱校验** | P1 不说教 / P3 识别优先 / P4 低门槛 | 非评判（去纯红）+ 符号+文字双编码 | `triggers.miss` 自学（E1）、复盘无「你必须」（D7） | ✅ 一致 |

**一致性结论**：无结构性冲突；设计/美术/工程三侧对六屏、三符号、Standard 基线、S1–S8 映射、Schema 字段全部对齐，可进入质量门。

---

## 3. 首个冲刺计划（Sprint 1 · 最小可玩证据）

> 来源：`production/tests/test-scaffolding.md` §3 + `production/epics/垂直切片_EpicStory.md` E0/E1。

**Sprint 1 目标**：证明「数据驱动 + 竖屏 + 中文 + 校验」四根地基成立——**加载一个 s01 场景 JSON 并渲染场景卡**端到端跑通，且关键红项已被 GUT 自动化守护。

**Story 清单（估点 ≈35，Lean 粗略）**

| # | Story | 红项 | 估点 | 贡献 |
|---|---|---|---:|---|
| 1 | E0-S1 竖屏工程初始化（project.godot） | — | 3 | 统一竖屏基线 |
| 2 | **E0-S2 CJK 字体导入 + 默认（B1/B2）** | B1/B2 | 5 | 中文可读地基（最高优先） |
| 3 | **E0-S3 安全区适配（C4）** | C4 | 5 | 真机不遮挡地基 |
| 4 | **E1-S1 DataLoader 枚举 + 读取 + 去 BOM（A4）** | A4 | 5 | 红项 A4 落地 |
| 5 | E1-S2 JSON 错误定位（A8） | — | 3 | 坏数据可定位 |
| 6 | E1-S3 ScenarioValidator（A6/A7） | — | 5 | 校验契约 |
| 7 | E1-S4 scenario_types 类型封装 | — | 2 | 强类型消费 |
| 8 | E2-S1 ScenarioCard 渲染 s01 场景卡（D1/G3） | — | 5 | 最小可玩证据载体 |
| 9 | **B3 真机 smoke（强建议并入）** | B3 | 2 | 真机中文早验证 |

**Sprint 1 完成六条判据**
1. `DataLoader` 能加载 `s01_scene_01.json`（设计未交付时以 `fixtures/s01_ok.json` 代位），**带 BOM 样本也能加载**（A4）。
2. `ScenarioValidator` 对 `correct∉candidates` / 无 `skilled` / 缺 `review.case` 给出预期结果（A6/A7）。
3. `portrait_theme.tres.default_font` 指向 CJK 字体（B1/B2），`ScenarioCard` 渲染 `context`/`npc.line`/`impulse` 中文非豆腐块。
4. `ui_adapter.gd` 已读安全区并施加根 Margin（C4 适配器落地）。
5. `test_data_loader` / `test_validator` / `test_cjk_font` 在编辑器与 `godot --headless` 均通过，CI 退出码 0。
6. **（强建议）**至少一台真机启动该卡片，中文正常（B3 早期证据）。

> 排期原则：所有红项（A4/B1/B2/C4）进 Sprint 1 最早节点；B3 虽在 E6 验收，但建议 Sprint 1 末做一次真机 smoke——R1 字体问题越晚发现返工越贵。

---

## 4. 垂直切片可玩原型方案（Playable Prototype Plan）

**切片组成**：s01_scene_01（绩效评语）+ s01_scene_02（冷战僵局）+ s03_scene_01（冷淡同事）+ s03_scene_02（留不住的老员工）+ s04_scene_01（问题很多的作品）= 5 场景。

**技术骨架**（沿用架构 §2）：Godot 4.3 竖屏 1080×1920；DataLoader/RunState/SaveManager 三个 Autoload；`res://data/scenarios/*.json` 数据驱动；六屏 `PlaySession` 状态机一次一屏；关系信号仅渲染不持久化；S8 读 `skills_index.json`。

**核心循环验证点**（验证「好玩且能学到」）：
- **识别闸门（P3）**：未识别不能选；识别错优先播放 `triggers.miss`（方案A），让后果自己教「先诊断」。
- **陷阱真实（P1）**：s01「列证据让他认错」/ s03「用钱或忽略需求」/ s04「泛泛夸做得好」须具备真实诱惑性（文案评审）。
- **后果可见不说教**：复盘用「X 身上发生过」案例，无伦理批注（P2 已移除）。
- **安全失败**：重复选陷阱不封锁、不扣分、重练无冷却。

**推进路线**：E0（地基）→ E1（数据层）→ E2（S2+S3）→ E3（S4+S5）→ E4（S6+S7+S8+存档）→ E5（5 场景数据核对）→ E6（六屏集成 + 真机中文/安全区 + Lean 门）。估点 ≈101（Lean 相对值，非人日）。

---

## 5. 已知风险与缓解（carry-forward）

| # | 风险 | 影响 | 缓解 |
|---|---|---|---|
| R1 | **声誉风险**（去掉 P2 伦理支柱） | 被误解为「教人话术」 | 文案层对冲：onboarding 免责声明「本游戏练沟通技巧，非操控他人」；陷阱后果由 NPC 真实反噬呈现，不美化 |
| R2 | **1930s 案例本地化成本** | 卡耐基案例年代感强，玩家难代入 | 切片 GDD 已用「下属/同事/老员工」现代情境重写外壳，案例仅作旁证；扩 34 技能时统一做现代语境本地化 |
| R3 | **`skills_index.json` 当前不存在**（S8 硬依赖，控制清单 F1） | 技能地图无法渲染 | 已排入 E1-S5（加载）+ E5-S4（切片三技能 `scenes` 映射）；实现期由 data/eng 落地 |
| R4 | **CJK 字体授权（G8，B1/B2 红项前置）** | 无授权字体不可真机分发 | 选 OFL 授权字体（Noto Sans SC / Source Han Sans 均 OFL），真机分发前 closing；见 §7 待拍板 |
| R5 | **真机 / iOS 发布前置**（B3/C4 验证 + G7 Mac+开发者账号） | 真机中文/安全区只能在真机验 | B3/C4 验证排 E6，但 Sprint 1 末建议真机 smoke；G7 为发布流程排期，非技术阻塞 |

---

## 6. Lean 预制作门（质量门判定）

**判定：PASS（CONCERNS）** —— 可进入 Phase 5 制作，下列 CONCERNS 须在 Phase 5 推进中解决（不阻塞进入）。

**通过项**
- ✅ Phase 4 四份交付齐全且落盘。
- ✅ 跨成员（设计/美术/工程）一致性核对无冲突。
- ✅ 切片范围锁定（s01+s03+s04，5 场景），S9 推迟已记录。
- ✅ 首个冲刺计划（Sprint 1）含全部红项（A4/B1/B2/C4）最早排期 + 最小可玩证据定义。
- ✅ 非阻塞延后项已文档化（语音旁白 / S9 meter / 伙伴立绘 / 第 2–6 章 / 氛围背景 / Comprehensive 档）。

**CONCERNS（已决 / 前瞻，均不阻塞 Phase 5 进入）**
- **C1 ✅ 已决**：引导伙伴角色 = **A 蜜蜂**（呼应蜂巢/蜂蜜隐喻，512×512 低面圆润立绘，承载引导/复盘旁白）；MVP 仍先以三符号 ◌⬡⑂ + 文字旁白承载，伙伴立绘排扩展层。
- **C2 ✅ 已决**：场景 JSON **按场景单文件**（`res://data/scenarios/s01_scene_01.json` … 共 5 个）；`skills_index.json` 的 `scenes` 映射按此粒度；DataLoader 目录枚举天然支持。
- **C3 ✅ 已决**：CJK 默认字体 = **Noto Sans SC**（OFL 授权）；落 `res://assets/fonts/NotoSansSC-Regular.ttf`，`portrait_theme.tres.default_font` 指向之（B1/B2 红项前置 closing）。
- **C4**（前瞻，不阻塞）：G6 s05 质量门是否以 `schema_v2` reintroduce —— 留待扩展层决策，不污染 v1 数据。
- **C5**（发布排期，不阻塞）：真机 / iOS 发布前置（G7 Mac + 开发者账号）—— B3/C4 真机验证排 E6，G7 仅发布流程排期。

---

## 7. 用户拍板记录（已决）

> 三项已于 Phase 4 收口前拍板，§6 CONCERNS 已回写 ✅：

1. **引导伙伴角色（⓷）= A 蜜蜂**。
2. **场景 JSON 粒度 = 按场景单文件**（共 5 个）。
3. **CJK 字体 = Noto Sans SC（OFL）**。

> 拍板后组装状态：Phase 4 闭环，Lean 预制作门 PASS（CONCERNS 已清）。可启动 Phase 5（按 Sprint 1 计划进入 E0+E1 实现）。
