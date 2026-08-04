#!/usr/bin/env bash
# ============================================================================
#  沟通的艺术 · 沟通技能学习游戏 — 本地一键出包 (Linux / macOS)
#  前置（一次性）：
#    1) 安装 Godot 4.3（标准版）
#    2) 安装 Android SDK command-line tools + JDK 17
#    3) 在 Godot 编辑器下载 4.3 官方导出模板
#    4) 把 NotoSansSC-Regular.ttf 放到 godot/assets/fonts/
#    5) 生成 keystore（仅首次）：
#       keytool -genkey -v -keystore commart.keystore -alias commart \
#               -keyalg RSA -keysize 2048 -validity 10000
#  用法：./build_android.sh
# ============================================================================
set -e
GODOT="${GODOT:-godot}"
PROJECT_DIR="godot"
OUTPUT="commart.apk"

"$GODOT" --headless --path "$PROJECT_DIR" --export-release "Android" "$OUTPUT"
echo "[OK] 已产出 $OUTPUT —— adb install $OUTPUT 侧载真机验证。"
