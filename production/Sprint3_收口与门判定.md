# Sprint 3 收口与最终 Lean 门判定

> 主理人（游承峰）汇编 · Phase 5 第三个制作脉冲
> 上游：Sprint1（E0+E1+E2-S1+E5）、Sprint2（E2完整+E3完整+E4-S1）、Sprint2 QA（§7 七条强制项）
> 本 Sprint 目标：E4 收尾（S8 导航 / S7 掌握度 / SaveManager 轻量存档，关 E2/E4 红项）+ E6 集成（六屏状态机烟雾 + 修复双重解析）+ 收口 Sprint2 QA §7 全部强制项
> 后续补丁：P1 多场景进度漏记修复（QA 在最终门发现的 P1，已修 + 补根因测试）

---

## 1. Sprint 3 范围与落盘清单

### 1.1 工程交付（E4 + E6）
| 文件 | 类型 | 说明 |
|---|---|---|
| `godot/scripts/autoload/SaveManager.gd` | 新增 | E4-S5 轻量存档。**白名单写入**：`ALLOWED_KEYS=["saveVersion","mastery","visited","settings"]`，`_sanitize` 双保险（载入 + 落盘前各一次），永不写 relationshipSignal/consequence/S9。已注册 autoload。 |
| `godot/scripts/core/MasterySystem.gd` | 新增 | E4-S4 掌握度 0–3 轻量（replay 递增、skilled 保底，无惩罚语义）。 |
| `godot/scripts/ui/SkillMap.gd` + `SkillMap.tscn` | 新增 | E4-S2/S3 导航：读 `skills_index` 渲染 s01/s03/s04 入口，visited/掌握度标记来自 SaveManager，点击启动 PlaySession 首场景，all_done 回地图。 |
| `godot/scripts/ui/MainMenu.gd` + `MainMenu.tscn` | 新增 | E4-S5 入口：标题 + 开始/继续。已设为 `project.godot` 的 `main_scene`。 |
| `godot/scripts/systems/PlaySession.gd` | 修改 | 最小化修复：加 `external_boot` 旗标（防 _ready 自动 load 与导航冲突）；修双重解析（`_on_choice_chosen` 置 `pass`，resolve 仅 `choose()` 内一次）；加 `get_last_chosen_type()`。 |
| `godot/project.godot` | 修改 | 启用 SaveManager autoload；main_scene 改 MainMenu.tscn。 |
| `godot/tests/test_save_manager.gd` | 新增 | E2/E4 红项断言：脏 dict（含 relationshipSignal/consequence/S9）→ 三层断言仅白名单键。 |
| `godot/tests/test_play_session.gd` | 新增 | 六屏状态机烟雾 + D8 安全失败 + A7 降级。 |
| `godot/tests/test_mastery.gd` | 新增 | 0–3 钳制 / replay 递增 / 不串扰 / 存档干净。 |
| `godot/README_Sprint3.md` | 新增 | 新增文件清单 + 导航接线 + 运行/验证指引。 |

### 1.2 复用未重写
DataLoader / ScenarioValidator / scenario_types / ui_adapter / TriggerSystem / ChoiceSystem / ConsequenceEngine / ScenarioEngine 核心契约全部不变。

---

## 2. 独立校验结论（主理人 Python 等价 + 静态核对）

- **白名单存档**：复刻 `_sanitize`，脏 dict（含 `relationshipSignal:-1` / `consequence{...}` / `s9Account:42`）经 sanitize→to_dict→读盘三层，仅留 `["saveVersion","mastery","visited","settings"]`，禁出盘字段全剔除 ✅
- **main_scene / autoload**：`project.godot` 已切 `MainMenu.tscn`，SaveManager autoload 已启用 ✅
- **测试就位**：3 个新增测试文件存在 ✅
- **全量场景 Schema 回归**：5 场景 `correct∈candidates` / ≥1 skilled / `review.case` / `triggers.miss` 同构 / `s04 forceBoundary` 全过 ✅

---

## 3. 最终 Lean 质量门判定

### 判定：**PASS（carry-over 真机验证清单）**

**依据**：无 P0、无契约逻辑矛盾；Sprint 2 QA §7 七条强制项全部处置；控制清单全红项进入三态之一（实现期关闭 / 待真机验 / Lean 延后），**无红项处于「未实现」**。

### 3.1 红项清零复核（对照 control-list.md）
| 状态 | 红项 |
|---|---|
| **实现期已关闭**（代码+测试就位，待真机/CI 复核） | A4 BOM、B2 主题引用、C4 安全区适配器、E2/E4 白名单存档、A6–A10 数据层校验 |
| **carry-over**（Lean 不阻塞，须用户侧跑证） | B3 真机中文渲染、C4 真机安全区遮挡、`.tscn↔.gd` 节点耦合运行期验证、六屏/竖屏可达 |
| **Lean 延后** | 藤蔓三态（仅符号+文字双编码，达色盲下限） |
| ⚠️ 资产缺口（非代码缺陷） | **B1 字体二进制 `.ttf` 缺失**——`portrait_theme.tres` 已正确引用路径，但 `assets/fonts/` 仅 README。放置前 B3 无法 pass，属用户侧资产动作。 |

### 3.2 用户侧必须执行的验证清单（carry-over）
1. **放置字体**：把 `NotoSansSC-Regular.ttf`（OFL）放到 `godot/assets/fonts/`，`portrait_theme.tres` 即命中（先决 B3）。
2. **Headless GUT 全绿**：
   ```
   godot --headless --path . --rendering-driver opengl3 \
         --scene res://addons/gut/gut.tscn -gdir=res://tests -gexit
   ```
   （先 Enable GUT 插件、把 GUT 9.3+ vendor 到 `godot/addons/gut/`）。跑后**手动复核 P1 修复**：从地图进 s01 玩完 `_scene_01`+`_scene_02` 返回，`user://save_v1.json` 的 `visited` 应含**两个**场景 id、`mastery["s01-shake-the-hive"]` 正确。
3. **真机 smoke（E6-S2/S3）**：iOS+Android 真机确认中文非豆腐块（模拟器不算）+ 安全区不遮挡 + 仅竖屏。
4. **资产审计**：字体授权 G8 在真机分发前 closing。

---

## 4. QA 发现的缺陷与处置

### P1（高，功能性，已修）· 多场景进度漏记
- **根因**：`SkillMap._on_session_done` 只以技能入口场景 id 记一次 visited/mastery；`PlaySession.next_scenario` 跨多场景单局中途不 emit `all_done`，导致后续场景进度全丢，且末屏 skilled 误归因入口。
- **修复**（最小化，未动六屏状态机）：
  - `PlaySession` 加 `_played: Dictionary`（键=场景 id，值=末次 chosen_type）；每次进 S5（`_render_consequence` 开头）记录；加 `get_played_results()` getter。
  - `SkillMap._on_session_done` 改为遍历 `ps.get_played_results()`，逐场景 `mark_visited` + `record_scenario`。
  - 清理无用 `_current_scenario_id`。
- **锁定**：`test_play_session.gd` 追加 `test_multi_scene_progress_recorded`（断言两场景 id 都在、s01_scene_01=="skilled" / s01_scene_02=="trap"）；`session_progress_equiv.py` 三断言全过（多场景不丢 / 识别错仍记 visited / replay 同 key 覆盖不膨胀）。
- **落盘核对**：主理人已用静态扫描确认 `_played`/`get_played_results`/记录点已写入、SkillMap 旧逻辑残留已清除、等价校验 EXIT 0。

### P2（低，非阻塞）
- SaveManager 单次 `mark_visited` 即 `_write` 整盘（效率可忽略，Lean 不修）。
- `external_boot` 无断言（运行期行为待 GUT 真跑确认）。
- **音频空白**：audio-director 尚未介入（见 §6 待补）。
- 跨技能「下一场景」语义（s01 末→s03 首）未显式定义（当前按 FALLBACK_ORDER 连续，可接受）。

---

## 5. 已知风险与缓解（carry-forward）

| 风险 | 等级 | 缓解 |
|---|---|---|
| 声誉风险（P2 伦理支柱已移除，文案层对冲） | 中 | onboarding 免责声明（未做，留发布前）；复盘文案无「你必须」口吻已落实 |
| 1930s 案例本地化成本 | 低 | 当前 5 场景已用现代语境重写，不依赖原文外壳 |
| 字体二进制缺失阻断 B3 | 中 | 用户侧放置 NotoSansSC-Regular.ttf（OFL） |
| 真机/CI 未跑，`.tscn↔.gd` 耦合未实例化验证 | 中 | GUT headless + 真机 smoke（§3.2） |
| 音频缺失 | 低→中 | Phase 6 评估：补位 audio-director 或显式静音决策 |

---

## 6. 下一步（Phase 6 打磨 / Phase 7 发布前必补 QA）

1. **P1 修复上 GUT 真跑 + 手动复核 visited 双场**（§3.2 步骤2）。
2. **真机 smoke**：B3 真机中文 / C4 真机安全区（建议提前，成本最低）。
3. **音频决策**：audio-director 介入产出音乐基调/音效设计/混音策略，或显式静音。
4. **资产审计**：字体授权 G8、UI 图标符号（◌⬡⑂ / ◈◷）。
5. **可访问性真机走查**：UX §5 A–G（动态字号/Reduce Motion/浅深 Theme）。
6. **内容评审**：陷阱真实文案 / P1 不说教语气（design 侧）。
7. **藤蔓三态**：补实现或显式归档延后（当前符号+文字已达标）。
8. **性能剖析**：单局 ≤3min、双写盘开销。

---

## 7. 待用户拍板项（收口时提交）

1. **音频策略**：现在介入 audio-director（产基调+音效+混音），还是 MVP 静音、发布前补？
2. **藤蔓三态**：补美术形态，还是显式归档为延后（当前已达色盲下限）？
3. **是否进入 Phase 6 打磨**（真机 smoke + 音频 + 资产审计），还是先停在这里由你本地跑通验证？
