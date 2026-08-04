# README · Android 出包指南（Phase 5 → 发布准备）

> **Owner**：engineering-lead（程基岩）
> **引擎**：Godot 4.3 · Android 竖屏 · Lean
> **目标**：把垂直切片（s01×2 + s03×2 + s04×1，共 5 场景）做成可侧载 / 可上架的 Android App。
> **本文件范围**：仅构建期 / 发布期指引。**不**改动任何游戏逻辑 / 场景 / 系统脚本。

---

## ⚠️ 环境限制（必读）

本沙箱**没有 Godot 二进制、没有 Android SDK、无法运行导出命令或 GUT**。
本仓库所新增的 `export_presets.cfg` / `icon.svg` / CI 工作流 / 本文档均为**配置与说明**，
**APK / AAB 二进制必须由你（用户侧）在装好 Godot 4.3 + Android SDK 的机器上，或经 GitHub Actions 实际编译产出。**

本环境产不出 `.apk`。

---

## 新增文件清单（本指南配套）

| 文件 | 作用 |
|---|---|
| `godot/export_presets.cfg` | Godot 4.3 Android 导出预设（包名/显示名/版本/竖屏/架构/图标/剔除 GUT 与测试） |
| `godot/icon.svg` | 启动图标占位（蜜蜂 + 蜂巢，暖中性底，Godot 自动生成各密度 png） |
| `godot/project.godot` | 最小编辑：新增 `config/version="0.1.0"`（未改 main_scene / autoload / 逻辑） |
| `.github/workflows/build-android.yml` | CI 自动出包（barichello/godot-ci@6） |
| `CHANGELOG.md`（仓库根） | 0.1.0 初始条目 |
| `production/Phase6_打磨清单.md` | Phase 6 打磨走查清单 |

> 游戏逻辑脚本（DataLoader / PlaySession / SaveManager / TriggerSystem / ConsequenceEngine 等）**一律未改**。

---

## A. 本地出包（用户侧：Godot 4.3 + Android SDK）

### 1. 安装工具链
- **Godot 4.3**（与 `project.godot` 的 `config/features` 中 `"4.3"` 严格一致）。
- **Android SDK command-line tools**（sdkmanager）。
- **OpenJDK 17**（Godot 4.3 Android 导出要求 JDK 17）。
- 在 Godot 编辑器「**Editor → Manage Export Templates**」下载匹配 4.3 的官方导出模板（r4.3）。
  （Godot 4.x Android 用预编译导出模板出包，无需 Android Studio / Gradle 全量编译。）

### 2. 放置 CJK 字体（先决 B1 / B3）
将 `NotoSansSC-Regular.ttf`（OFL 授权）放入 `godot/assets/fonts/`：
```
godot/assets/fonts/NotoSansSC-Regular.ttf
```
`scripts/theme/portrait_theme.tres` 已引用该路径；放入即生效，中文不再豆腐块。
（缺失时 Godot 回退默认字体，不崩溃，但中文会乱码 —— Sprint3 收口已标记 B1 为资产缺口，属用户侧动作。）

### 3. （可选）移除 / 保留 GUT
- 发布预设已通过 `exclude_filter="addons/gut/*;tests/*"` 把 GUT 与测试剔除出包，**本地验证后仍建议移除以减小体积**。
- 若你还要本地跑 GUT：把 GUT 9.x（兼容 4.3）vendor 到 `godot/addons/gut/`，编辑器 `Project → Plugins` 启用。

### 4. 生成发布签名 keystore（仅上架需要；侧载测试可跳过）
```bash
keytool -genkey -v -keystore commart.keystore -alias commart \
        -keyalg RSA -keysize 2048 -validity 10000
```
参数说明：
- `-keystore commart.keystore`：输出 keystore 文件名（妥善保管，**丢失无法更新上架应用**）。
- `-alias commart`：密钥别名（导出预设 `keystore/release_user` 与之对应）。
- `-keyalg RSA -keysize 2048`：RSA 2048 位（Play 商店最低要求）。
- `-validity 10000`：有效期 10000 天（≈27 年）。
- 交互式询问：密钥库口令、密钥口令、姓名/组织等 DN 信息；**口令务必记下**。

### 5. 导出 APK
- **方式一（编辑器）**：`项目 → 导出` → 选 `Android` → 填 keystore（侧载可留空，用 debug 签名）→ 点「**导出**」→ 产出 `commart.apk`。
- **方式二（命令行，release 签名）**：
  ```bash
  godot --headless --export-release "Android" commart.apk
  ```
  （debug 侧载可用 `godot --headless --export "Android" commart.apk`，Godot 用自带 debug keystore。）

### 6. 真机验证（E6-S2/S3 smoke，Lean carry-over）
```bash
adb install commart.apk
```
真机（非模拟器）确认：
- **中文非豆腐块**（B3，依赖步骤 2 字体）。
- **安全区不遮挡**（C4，刘海 / 手势条下 UI 可见，依赖 `ui_adapter` 安全区适配）。
- **仅竖屏**（已在 `export_presets.cfg` 的 `screen/orientation="portrait"` 与 `project.godot` 的 `window/handheld/orientation="portrait"` 双保险）。
- **六屏 / `.tscn↔.gd` 节点耦合运行期可达**（Sprint3 收口 carry-over，本沙箱无法实例化验证）。

---

## B. CI 出包（GitHub Actions 自动产出 APK）

- 把本仓库 push 到 GitHub（默认监听 `main` / `master` / `develop`，PR 亦触发；也可在 Actions 页手动 `workflow_dispatch`）。
- 工作流 `.github/workflows/build-android.yml` 用 `barichello/godot-ci@6`：
  - 内置 **Godot 4.3 + 官方导出模板 + Android SDK + debug keystore**。
  - 执行 `godot --headless --path godot --export "Android" commart.apk`（对应 `export_presets.cfg` 的 `package/signed=false` → **debug 签名**）。
- 跑完后在 **Actions → 本次运行 → Artifacts → `commart-android`** 下载 `commart.apk`，直接 `adb install` 侧载测试。
- **上架 Google Play**：需在仓库 Secrets 放 release keystore（见工作流末尾注释的 `PLAY_KEYSTORE_BASE64` / `KEYSTORE_PASSWORD` 等占位），并把 `export_presets.cfg` 的 `package/signed` 改为 `true`；本工作流默认**不实现真实签名**，仅给占位与指引。

> 说明：CI 默认产出的是 **debug 签名 APK**，可用于真机侧载与内部测试，**不能**直接上架 Google Play（Play 要求 release 签名 AAB）。上架流程见上文「步骤 4 / 5」与 CI 注释。

---

## 关键默认值（用户可改）

| 项 | 值 | 位置 |
|---|---|---|
| 应用 ID（包名） | `com.commart.app` | `export_presets.cfg` → `package/unique_name` |
| 显示名 | `沟通的艺术` | `export_presets.cfg` → `package/name` |
| 版本号 | code `1` / name `0.1.0` | `export_presets.cfg` → `version/code` · `version/name`；`project.godot` → `config/version` |
| 图标 | `res://icon.svg` | `export_presets.cfg` → `application/icon` |
| 竖屏 | portrait + immersive | `export_presets.cfg` → `screen/*` |
| 剔除 | GUT 与 tests | `export_presets.cfg` → `exclude_filter` |

---

## 已知 carry-over（需真机 / 运行验证，非本文件可解）

- **B3** 真机中文渲染（先决步骤 A.2 字体）。
- **C4** 真机安全区遮挡（`ui_adapter` 安全区适配）。
- **`.tscn↔.gd` 节点耦合**：`SkillMap.tscn` 的 `RootMargin/VBox/SkillList`、`PlaySession` 内部 `StageRoot/ReviewPanel/CaseSection` 等节点存在性仅能在编辑器 / 真机 / GUT headless 确认。
- 藤蔓三态（RelationshipGlyph 光秃/抽芽/开花）按 Lean 显式延后，当前仅符号 + 文字双编码（达色盲下限）。

详见 `production/Phase6_打磨清单.md` 与 `production/Sprint3_收口与门判定.md`。
