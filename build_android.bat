@echo off
REM ============================================================================
REM  沟通的艺术 · 沟通技能学习游戏 — 本地一键出包 (Windows)
REM  前置（一次性）：
REM    1) 安装 Godot 4.3（含标准版，非 .NET 版即可）
REM    2) 安装 Android SDK command-line tools + JDK 17
REM    3) 在 Godot 编辑器「Editor → Manage Export Templates」下载 4.3 官方模板
REM    4) 把 NotoSansSC-Regular.ttf（OFL，Google Fonts 取）放到 godot\assets\fonts\
REM    5) 生成签名 keystore（仅首次）：
REM       keytool -genkey -v -keystore commart.keystore -alias commart ^
REM               -keyalg RSA -keysize 2048 -validity 10000
REM ----------------------------------------------------------------------------
REM  用法：把本文件与 godot\ 目录放在同级，双击或在 cmd 中运行。
REM  确保 godot 命令可用（把 Godot 安装目录加入 PATH，或下面填绝对路径）。
REM ============================================================================

SET GODOT=godot
SET PROJECT_DIR=godot
SET OUTPUT=commart.apk

%GODOT% --headless --path %PROJECT_DIR% --export-release "Android" %OUTPUT%

IF %ERRORLEVEL%==0 (
  echo.
  echo [OK] 已产出 %OUTPUT% —— 用 adb install %OUTPUT% 侧载真机验证。
) ELSE (
  echo.
  echo [FAIL] 导出失败。常见原因：未装导出模板 / 未配 keystore / JDK/SDK 未接入 Godot。
  echo        请先按 godot\README_Android.md 与 BUILD_ANDROID.md 完成前置。
)
pause
