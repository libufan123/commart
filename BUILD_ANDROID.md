# 生成 Android App（APK）指南

本项目是 Godot 4.3 竖屏移动端游戏，工程根在 `godot/`。APK 二进制需由
**本地 Godot+Android SDK** 或 **GitHub Actions** 实际编译——本开发沙箱无 Godot/SDK/Java，
不产出 `.apk`，但已把工程与构建管线准备到「一键出包」状态。

## 方式 A：GitHub Actions 自动出包（最省事，推荐）

1. 把整个仓库（含 `godot/`、`export_presets.cfg`、`.github/`）推到 GitHub。
2. 在仓库 **Actions → Build Android (APK)** 页面点 **Run workflow**（或 push 到 main/master 自动触发）。
3. 工作流使用 `barichello/godot-ci@6` 镜像（内置 Godot 4.3 + 导出模板 + Android SDK + debug keystore），
   自动产出 **debug 签名 APK** 制品 `commart-android`，下载即可 `adb install` 侧载真机。
4. **上架 Google Play**：在仓库 Secrets 配置 `PLAY_KEYSTORE_BASE64` / `KEYSTORE_PASSWORD` 等，
   取消 `.github/workflows/build-android.yml` 末尾 release 段注释，并把
   `godot/export_presets.cfg` 的 `package/signed` 改为 `true`。

## 方式 B：本地一键出包

前置（一次性）：
- Godot 4.3（标准版，非 .NET）
- JDK 17 + Android SDK command-line tools
- 在 Godot 编辑器「Editor → Manage Export Templates」下载 4.3 官方模板
- 把 `NotoSansSC-Regular.ttf`（OFL，Google Fonts 取）放到 `godot/assets/fonts/`（解 B1/B3 中文前置）
- 生成 keystore：
  `keytool -genkey -v -keystore commart.keystore -alias commart -keyalg RSA -keysize 2048 -validity 10000`

然后运行对应脚本（与 `godot/` 同级）：
- Windows：`build_android.bat`
- Linux/macOS：`build_android.sh`
- 等价命令：`godot --headless --path godot --export-release "Android" commart.apk`

## 真机验证清单（发布前必做）

- [ ] 中文显示正常（非豆腐块）—— 验证 B1/B2/B3
- [ ] 刘海/挖孔安全区不遮挡 UI —— 验证 C4
- [ ] 仅竖屏、沉浸模式生效
- [ ] 从 SkillMap 进 s01 玩完两场景返回，`user://save_v1.json` 的 `visited` 含**两个** id（验证 P1 修复）
- [ ] 关系信号符号仅渲染、存档无 `relationshipSignal` 字段（验证 E2/E4 白名单）

## 包信息（默认值，可改）

- 应用 ID：`com.commart.app`
- 显示名：`沟通的艺术`
- 版本：`0.1.0` / code `1`
- 架构：arm64-v8a + armeabi-v7a
- 发布包已通过 `exclude_filter` 剔除 `addons/gut/*` 与 `tests/*`
