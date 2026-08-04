# 测试脚手架 · GUT + 最小可玩证据（垂直切片）

> **Owner**：engineering-lead（程基岩）
> **阶段**：Phase 4 预制作（测试落地方案，先于实现）
> **引擎基线**：Godot 4.3（已锁定）
> **平台**：iOS / Android 竖屏 · Lean
> **关联**：`production/epics/垂直切片_EpicStory.md` · `docs/architecture/engin-architecture.md` · `docs/architecture/adr.md` · `docs/architecture/control-list.md` · `design/gdd/内容数据schema.md`

---

## 1. 测试框架选定：GUT（Godot Unit Test）

**选择 GUT 的理由**
- GDScript 原生、与 Godot 4.3 集成最紧，无需引入外部语言运行时；契合 Lean 与移动端纯 Control UI 的轻量测试需求。
- 支持编辑器内一键运行、CI headless 运行、参数化 `assert_eq`/`assert_true`/`assert_ne` 等断言，足够覆盖数据层 / 系统逻辑 / 存档断言。
- 与「数据驱动 + 静态查表」架构天然匹配：我们的核心风险在**加载/校验/查表/存档白名单**，这些全是纯逻辑，可在无 GUI 下断言。

> **版本钉定**：GUT 9.x 系列支持 Godot 4.x；本切片按 **Godot 4.3** 锁定，须在 `addons/gut/` 提交一个与 4.3 兼容的 GUT 版本（建议 GUT 9.3+，提交前在 4.3 跑通冒烟）。

### 1.1 安装 / 启用（Godot 4.3）

1. **获取 addon**：将 GUT 仓库的 `addons/gut/` 目录整体放入工程
   ```
   res://addons/gut/          # Gut 插件主体（.gd + plugin.cfg + 图标）
   ```
2. **启用插件**：编辑器内 `Project → Project Settings → Plugins`，找到 **Gut**，将状态切到 **Enable**（等效写入 `project.godot` 的 `[editor_plugins] enabled`）。
3. **（可选）CLI/Git 忽略**：`addons/gut/` 作为 vendored 依赖提交；CI 不改它。

### 1.2 运行方式

- **编辑器内**：`Project → Tools → GUT`（或快捷键 `Ctrl+Shift+G`）打开 GUT 面板 → 选 `res://tests/` → Run。
- **CI / headless（推荐，Lean 门禁用）**：
  ```bash
  # 无头跑 res://tests 下全部 test_*.gd，跑完即退出（非零码=失败）
  godot --headless --path . --rendering-driver opengl3 \
        --scene res://addons/gut/gut.tscn \
        -gdir=res://tests -gexit
  ```
  > 说明：`-gdir` 指定测试目录，`-gexit` 让 GUT 跑完自动退出并返回退出码；CI 用退出码作为质量门。

### 1.3 测试目录与命名约定

沿用 `engin-architecture.md` §2 的 `res://tests/`：

```
res://tests/
├─ test_data_loader.gd        # E1：枚举/读取/BOM/解析错误定位
├─ test_validator.gd          # E1：ScenarioValidator 各项约束
├─ test_trigger_system.gd     # E2/E3：S3 硬闸门 + miss 演出（方案A）
├─ test_consequence_engine.gd # E3：静态查表 + forceBoundary + 关系信号仅渲染
├─ test_save_manager.gd       # E4：存档白名单（关系信号禁出盘）
├─ test_cjk_font.gd           # E0：默认字体含中文字形（B1/B2）
├─ test_play_session.gd       # E6：六屏状态机烟雾
└─ fixtures/                  # 受控 JSON 样本（含带 BOM / 坏数据 / 缺 case 等）
   ├─ s01_ok.json
   ├─ s01_bom.json            # 首 3 字节 EF BB BF
   ├─ s01_bad_correct.json    # correct ∉ candidates
   ├─ s01_no_skilled.json     # 无 skilled 选项
   ├─ s01_no_review_case.json # review.case 缺失
   └─ s04_force_boundary.json # forceBoundary:true
```

> GUT 自动发现并运行 `test_*.gd`；每个测试脚本以 `extends GutTest` 开头，`func test_xxx()` 为用例。

---

## 2. 首批测试用例（按 Epic 成熟度）

> 下面给出**最小骨架**（脚手架级，非完整实现），用于固化验收口径；实际断言在对应 Epic 实现期补全。每条标注对应 **控制清单项 / Schema 规则 / 边缘情况**。

### 2.1 数据层（E1）

**A. JSON 解析成功 / 失败定位（A8）**
```gdscript
# test_data_loader.gd
func test_parse_error_reports_line_and_message():
    var bad = '{\"id\": \"x\", \"triggers\": }'          # 故意坏 JSON
    var json = JSON.new()
    var err = json.parse_string(bad)
    assert_true(err != OK, "坏数据应解析失败")
    # A8：取 get_error_line()/get_error_message() 用于定位
    assert_true(json.get_error_line() > 0, "应给出错误行号")
    assert_ne(json.get_error_message(), "", "应给出错误信息")
```

**B. BOM 剥离（A4，红）**
```gdscript
# test_data_loader.gd
func test_loader_strips_utf8_bom():
    # fixtures/s01_bom.json 首 3 字节为 EF BB BF
    var path = "res://tests/fixtures/s01_bom.json"
    var scen = DataLoader.load_one(path)        # 内部：字节级 slice(3) 后 get_string_from_utf8
    assert_eq(scen.id, "s01_scene_01", "带 BOM 文件应被正确解析为首个场景")
```

**C. ScenarioValidator（correct∈candidates / ≥1 skilled / review.case 缺失降级 / miss 同构）（A6/A7）**
```gdscript
# test_validator.gd
func test_validator_correct_must_be_in_candidates():      # A6
    var d = _load_dict("res://tests/fixtures/s01_bad_correct.json")
    assert_false(ScenarioValidator.validate(d).ok, "correct∉candidates 应不通过")

func test_validator_requires_one_skilled():               # A6
    var d = _load_dict("res://tests/fixtures/s01_no_skilled.json")
    assert_false(ScenarioValidator.validate(d).ok, "无 skilled 选项应不通过")

func test_validator_missing_review_case_degrades():       # A7 / E5 降级
    var d = _load_dict("res://tests/fixtures/s01_no_review_case.json")
    var r = ScenarioValidator.validate(d)
    assert_true(r.ok, "review.case 缺失应放行")
    assert_false(r.has_review_case, "应标记 case 缺失，供 ReviewPanel 降级渲染")

func test_validator_miss_is_consequence_shaped():         # 约束4 / G2
    var d = _load_dict("res://tests/fixtures/s01_ok.json")
    var r = ScenarioValidator.validate(d)
    assert_true(r.miss_isomorphic, "triggers.miss 须与 consequence 同构")
```

### 2.2 S3 硬闸门（E2/E3）

**A. 未识别不可进入有效抉择（D2）**
```gdscript
# test_trigger_system.gd
func test_cannot_enter_choice_before_identification():    # D2 硬闸门
    var ps = PlaySession.new()
    ps.load_scenario(DataLoader.get_scenario("s01_scene_01"))
    assert_false(ps.can_choose(), "S3 未完成前 ChoicePanel 不可操作")
    ps.submit_trigger("我正想批评 / 对方在防御")   # == correct
    assert_true(ps.can_choose(), "识别正确后解锁抉择")
```

**B. 识别错 → triggers.miss 演出（方案A，G2 / E1）**
```gdscript
func test_wrong_identification_plays_miss():              # D3 / E1
    var ps = PlaySession.new()
    ps.load_scenario(DataLoader.get_scenario("s01_scene_01"))
    ps.submit_trigger("纯事务沟通")            # != correct
    var cons = ps.resolve_consequence()
    var miss = DataLoader.get_scenario("s01_scene_01").triggers.miss
    assert_eq(cons.npc_reaction, miss.npc_reaction, "识别错应优先演出 triggers.miss")
```

**C. miss 缺省回退不崩溃（E1 降级）**
```gdscript
func test_missing_miss_falls_back_no_crash():             # E1 降级
    var scen = _scenario_without_miss()    # triggers 无 miss 字段
    var ps = PlaySession.new()
    ps.load_scenario(scen)
    ps.submit_trigger("错误标签")
    var cons = ps.resolve_consequence()      # 回退到所选 choice.consequence
    assert_not_null(cons, "miss 缺省应回退所选 choice 后果，不崩溃")
```

### 2.3 S5 后果引擎（E3）

**A. forceBoundary:true 确定性路由 boundary（E2 / D6）**
```gdscript
# test_consequence_engine.gd
func test_force_boundary_routes_to_boundary():            # E2 / D6
    var scen = DataLoader.get_scenario("s04_scene_01")    # forceBoundary:true
    var eng = ConsequenceEngine.new()
    # 即便玩家选了 skilled，也应被强制路由到 boundary 后果
    var cons = eng.resolve(scen, "c_skilled")             # 假设 c_skilled 为 skilled 选项
    var boundary = scen.choices_by_type("boundary")[0].consequence
    assert_eq(cons.npc_reaction, boundary.npc_reaction, "forceBoundary 应确定性路由到 boundary")
```

**B. relationshipSignal 仅渲染不持久化（E2/E4 评审卡点）**
```gdscript
func test_relationship_signal_not_persisted():            # E2/E4 卡点
    var scen = DataLoader.get_scenario("s01_scene_01")
    var ps = PlaySession.new(); ps.load_scenario(scen)
    ps.submit_trigger(scen.triggers.correct)
    ps.choose("c1")                          # 取一个 consequence
    # 渲染层应拿到信号
    assert_ne(ps.current_relationship_signal(), 0, "ConsequenceStage 渲染可见信号")
    # 但存档不得含该字段
    SaveManager.save()
    var raw = _read_save_file("user://save_v1.json")
    assert_false(raw.has("relationshipSignal"), "存档禁止含 relationshipSignal")
    assert_false(_save_has_any_s9_key(raw), "存档禁止含任何 S9 关系账户字段")
```

### 2.4 CJK 字体（E0）

**默认字体含中文字形（B1/B2）**
```gdscript
# test_cjk_font.gd
func test_default_font_points_to_cjk():                   # B1/B2
    var theme = load("res://scripts/theme/portrait_theme.tres")
    assert_not_null(theme.default_font, "主题必须有 default_font")
    # 断言默认字体资源路径指向 CJK 字体（如 NotoSansSC-Regular.ttf）
    assert_true(theme.default_font.resource_path.contains("NotoSansSC"),
                "default_font 应指向 CJK 字体，否则中文豆腐块")
```

---

## 3. Sprint 1 草案（最小可玩证据）

### 3.1 排期原则（红项最早可验证）
- **B1/B2（CJK 字体，最高优先硬阻塞）**与 **A4（BOM 剥离，红）**与 **C4（安全区，红）** 全部进入 Sprint 1 最早节点——它们是最廉价、却能最早起封锁验证的「地基性红项」。
- 逻辑上：先 E0-S1/S2/S3（工程+字体+安全区），再 E1-S1/S2/S3/S4（数据管线+校验），最后 E2-S1（渲染一个场景卡）产出最小可玩证据。
- **B3（真机中文）**虽在 E6 验收，但鉴于 R1 最高优先，建议在 **Sprint 1 末做一次真机 smoke**（一台真机跑通场景卡中文），越晚发现字体/渲染问题返工成本越高。

### 3.2 Sprint 1 Story 清单（取自 Epic）

| # | Story（Epic 引用） | 红项 | 估点 | Sprint 1 目标贡献 |
|---|---|---|---:|---|
| 1 | E0-S1 竖屏工程初始化（project.godot） | — | 3 | 统一竖屏基线 |
| 2 | **E0-S2 CJK 字体导入+默认（B1/B2）** | **B1/B2** | 5 | 中文可读地基（最高优先） |
| 3 | **E0-S3 安全区适配（C4）** | **C4** | 5 | 真机不遮挡地基 |
| 4 | **E1-S1 DataLoader 枚举+读取+去 BOM（A4）** | **A4** | 5 | 红项 A4 落地 |
| 5 | E1-S2 JSON 错误定位（A8） | — | 3 | 坏数据可定位 |
| 6 | E1-S3 ScenarioValidator（A6/A7） | — | 5 | 校验契约 |
| 7 | E1-S4 scenario_types 类型封装 | — | 2 | 强类型消费 |
| 8 | E2-S1 ScenarioCard 渲染 s01 场景卡（D1/G3） | — | 5 | 最小可玩证据载体 |
| 9 | **B3 真机 smoke（建议并入）** | **B3** | 2 | 真机中文早验证（非必须，强建议） |

> Sprint 1 估点 ≈ 35（Lean 粗略；按团队速率裁剪，最少保留 2/3/4/6/8 五项以满足最小可玩证据）。

### 3.3 Sprint 1 目标：最小可玩证据（Minimal Playable Evidence）

> **定义**：Sprint 1 完成的判据 = 「**加载一个 s01 场景 JSON 并渲染场景卡**」端到端跑通，且关键红项已起验证。具体：

1. **数据可加载**：`DataLoader` 能枚举并加载 `res://data/scenarios/s01_scene_01.json`（无论设计侧是否交付，工程用 `fixtures/s01_ok.json` 代位），且**带 BOM 样本也能加载**（A4 红项验证）。
2. **校验生效**：`ScenarioValidator` 对 `correct∉candidates`、无 `skilled`、缺 `review.case` 的样本给出预期结果（A6/A7 绿项验证）。
3. **中文可读**：`portrait_theme.tres` 的 `default_font` 指向 CJK 字体（B1/B2 红项验证），编辑器内 `ScenarioCard` 渲染的 `context`/`npc.line`/`impulse` 中文**非豆腐块**。
4. **安全区就位**：`ui_adapter.gd` 已读取安全区并施加根 Margin（C4 红项适配器落地，真机验证留 E6-S3）。
5. **回归门**：上述 GUT 用例（`test_data_loader` / `test_validator` / `test_cjk_font`）在编辑器与 headless 均通过，CI 退出码为 0。
6. **（强建议）真机 smoke**：至少一台 iOS 或 Android 真机启动该场景卡，中文正常渲染（B3 早期证据）。

**一句话**：Sprint 1 的最小可玩证据 = 「拖入一个 s01 JSON → 真机/编辑器竖屏卡片显示中文情境+对方末句+冲动气泡，且 BOM/校验/字体/安全区红项已自动化守护」。这证明数据驱动 + 竖屏 + 中文 + 校验四根地基成立，后续 E2–E6 只在其上叠加识别/抉择/后果/复盘/导航/真机验收。

---

## 4. 与上游的一致性承诺
- 测试项编号锚定控制清单：A4 / A6 / A7 / A8（数据层）、D2/D3（S3 闸门）、E1/E2/E3（边缘与关系信号）、B1/B2/B3（CJK）、C4（安全区）。
- 断言对象对应真实类名：`DataLoader.gd` / `ScenarioValidator.gd` / `scenario_types.gd` / `TriggerSystem.gd` / `ConsequenceEngine.gd` / `SaveManager.gd` / `ui_adapter.gd` / `portrait_theme.tres` / `PlaySession.tscn` / `ScenarioCard.tscn`。
- `relationshipSignal` 不持久化以**白名单写入**断言（存档仅含 `mastery/visited/settings`），对应 ADR-005 与 E2/E4 红项。
- `forceBoundary` 确定性路由断言对应 ADR-004 唯一引擎级规则与 E2 边缘。
- `triggers.miss` 演出与降级断言对应 G2 方案A 与架构评审 R-gap-1。
- 所有 fixture 的 Schema 字段名逐字沿用 `内容数据schema.md`。
