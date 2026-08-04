# Phase 6 打磨清单 · 《沟通的艺术》Android 出包前走查

> **Owner**：engineering-lead（程基岩）
> **引擎**：Godot 4.3 · Android 竖屏 · Lean
> **用途**：Android 发布前的走查清单（**只列项、不重复实现**）。逐项勾选，不通过不发布。
> **上游 carry-over**：`production/Sprint3_收口与门判定.md`（Lean 门 PASS，含真机验证 carry-over）。

---

## 0. 发布前硬门（必过，来自 Sprint3 carry-over）

| # | 项 | 来源 | 验证方式 | 状态 |
|---|---|---|---|---|
| B3 | 真机中文渲染（非豆腐块） | Sprint3 收口 R1/B1 | 真机装包，确认全中文正常 | ☐ |
| C4 | 真机安全区遮挡 | Sprint3 收口 R3 | 刘海/手势条设备，UI 不被遮挡 | ☐ |
| TS | `.tscn↔.gd` 节点耦合运行期验证 | Sprint3 §7 / QA P1-1 | 真机或 GUT headless 打开六屏，无缺节点报错 | ☐ |
| OR | 仅竖屏（portrait） | `export_presets.cfg` + `project.godot` | 旋转设备不转横屏、不破版 | ☐ |

> 以上四项本沙箱（无 Godot/SDK）**一律不可验证**，只能由用户侧真机或 CI 编译后确认。

---

## 1. 真机 smoke（E6-S2/S3）

- [ ] **B3** 真机中文：主菜单 / 技能地图 / 五场景文案 / 复盘全中文，无豆腐块（先决 `assets/fonts/NotoSansSC-Regular.ttf` 已放置，OFL 授权）。
- [ ] **C4** 真机安全区：`ui_adapter` 读取 `get_safe_area()` 并施加到根 `MarginContainer`；刘海 / 挖孔 / 手势条下标题、选项、复盘 Bottom Sheet 不被裁切。
- [ ] **OR** 仅竖屏：物理旋转设备保持竖屏；`window/stretch/aspect="expand"` 下不同高度不破版。
- [ ] **TS** 节点耦合：从主菜单 → 技能地图 → 单局六屏 → 复盘 → 回地图，全链路无 `Node not found` / 缺节点报错。
- [ ] **六屏视觉**：场景卡 / 识别 / 选择 / 后果 / 复盘 / 地图 六屏在 1080×1920 基准与一台小屏（≈360dp）均单屏可达、可点。
- [ ] **GUT headless 全绿**（用户侧）：`godot --headless --path . --rendering-driver opengl3 --scene res://addons/gut/gut.tscn -gdir=res://tests -gexit`；重点复核 **P1 修复**：玩完 s01 两场景返回，`user://save_v1.json` 的 `visited` 含两个场景 id、`mastery["s01-shake-the-hive"]` 正确（Sprint3 §3.2 步骤2）。

---

## 2. 资产审计（对照 `docs/art/资产规格.md`）

- [ ] **纹理预算**：切片美术侧 ≤ **8–12 MB**（资产规格 §2.4）；最终总包与目标机型核对；图标/UI 合 AtlasTexture（≤2048²），ETC2/ASTC 压缩。
- [ ] **符号 ◌⬡⑂**：触发 / 技巧 / 后果（顺畅·紧张）三符号 + 文字双编码已落地 SVG（`sym_trigger` / `sym_technique` / `sym_consequence_smooth` / `sym_consequence_tension`）。
- [ ] **NPC persona**：4 persona（subordinate / colleague / veteran / partner）× 各 3 态（neutral / mood / warm）≈ 12 帧是否已产并接入；s04 可选 creator persona 状态确认。
- [ ] **引导伙伴「蜜蜂」立绘**：资产规格 §1.5 标记为 **⓷ 待拍板 / Lean 延后**；当前仅符号 + 文字旁白承载引导，确认 MVP 不阻塞、补产或显式归档。
- [ ] **卡片 / UI 9Patch**：trigger / choice / consequence 卡板 + btn / tag / progress-hex / sheet / toast 是否到位，九宫格圆角不变形。
- [ ] **动态字体**：中文动态字体（FontFile）加载，无「带字图片」（资产规格 §5-1 硬约束，评审一票否决）。
- [ ] **浅/深双 Theme**：颜色走 Theme 变量，切换仅换 Theme 不动布局（资产规格 §1.6 / §2.6）。
- [ ] **字体授权 G8**：`NotoSansSC-Regular.ttf` 的 OFL 授权在上架分发前 closing（Sprint3 §3.2-4）。

---

## 3. 可访问性走查（Standard 基线，七项）

对照 `docs/art/可访问性分级与特性矩阵.md` §1.2（MVP 出货目标 = Standard）：

| # | 项 | 要点 | 验证 |
|---|---|---|---|
| 1 | 触控尺寸 | 可点元素 ≥ 48×48pt（Material）/ 44pt（Apple），整卡可点 | 真机/布局边界视图实测 |
| 2 | 语义色双编码 | 触发◌/技巧⬡/后果⑂ 均**符号 + 文字标签**，不只靠颜色 | 过 Deuter/Protan/Tritan 模拟 |
| 3 | 动态字号 | 响应系统字号至 ~200% 主流程不破版 | 系统字号拉到 200% 走查 |
| 4 | Reduce Motion | 系统开启后转场退化为淡入/瞬切，循环动画停用 | 开 Reduce Motion 复查 |
| 5 | 安全区 | `get_safe_area()` 适配 360dp 小屏→平板竖屏单列 | 见 §0 C4 |
| 6 | 浅/深 Theme | 提供浅/深两套，默认跟随系统 + 手动 + 记忆 | 切换仅换 Theme、布局不变 |
| 7 | 字号下限/对比度 | 正文 ≥ 16pt 下限；陶土白字 / 蜂蜜金不作正文（AA 对比度） | 工具实测对比度 |

---

## 4. 音频（待主理人拍板，Sprint3 §6 / §7-2）

- [ ] **音频策略**：现在介入 audio-director（产基调 + 关键音效 + 混音策略），还是 MVP **静音**、发布前补？（当前 `assets/audio/` 空，P2 已标记音频空白）。
- [ ] 若决定做：关键音效（选项点击 / 抉择反馈 / 复盘）与音乐基调占位；混音阈值（避免覆盖语音旁白）。
- [ ] 若决定静音：显式「无音频」决策归档，避免上架后用户预期落差。

---

## 5. 性能

- [ ] **首屏加载**：主菜单冷启到可交互时间（目标机型）可接受；DataLoader 一次性载入约 5 场景 JSON + skills_index，K 级体量，无阻塞。
- [ ] **场景切换帧率**：六屏切换（S2→S3→S4→S5→S6）在目标中低端机维持流畅（无掉帧 / 明显卡顿）。
- [ ] **存档开销**：SaveManager 每次 `mark_visited` 整盘写入（P2 已知），体量下效率可忽略；确认无双写盘/频繁落盘。

---

## 6. 内容与合规（设计 / 主理人侧）

- [ ] **陷阱真实文案**：5 场景陷阱选项文案是否真实可信（design 侧）。
- [ ] **P1 不说教语气**：复盘文案无「你必须」口吻（Sprint3 §5 已落实，发布前复核）。
- [ ] **声誉风险对冲**：伦理支柱已移除，复盘文案对冲方式确认；onboarding 免责声明（Sprint3 §5 风险项）是否补。
- [ ] **藤蔓三态**：补实现或显式归档为延后（当前符号+文字已达标色盲下限）。

---

## 7. 构建 / 发布物核对（本 Phase 新增）

- [ ] `godot/export_presets.cfg` 在 Godot 4.3 导出窗口打开无报错、键名自动校正后复检。
- [ ] `godot/icon.svg` 在真机显示正常（各密度自适应图标清晰）。
- [ ] `exclude_filter="addons/gut/*;tests/*"` 生效：发布包不含 GUT 与测试（包体核对）。
- [ ] CI 工作流 `.github/workflows/build-android.yml` 跑通，产出 `commart-android` APK artifact（debug 签名）。
- [ ] 上架所需 release keystore + Secret 准备就绪（若走 Google Play）。
- [ ] `CHANGELOG.md` 0.1.0 条目与发版一致；后续扩展到全章/全本追加条目。

---

> 本清单为走查项集合，不重复实现任何系统；实现责任按现有分工（程基岩/文策渊/林绘澄/阮和鸣/严守真）归口。
> 所有「真机 / 运行期」项均无法在本沙箱验证，必须由用户侧或 CI 编译后执行。
