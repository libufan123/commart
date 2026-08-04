# CJK 字体放置说明（红项 B1 / B2）

本工程**不含字体二进制**（仓库/沙箱无二进制资产，且无法下载）。请按以下步骤手动放置：

1. 获取 **Noto Sans SC**（OFL 授权，免费可商用）：
   - 官方：<https://github.com/notofonts/noto-cjk> 或 Google Fonts 的 `NotoSansSC-Regular.ttf`
   - 须为 **.ttf**（Godot 4 的 `FontFile` 直接支持；如用 .otf 也可，但路径要改）
   - 授权：OFL-1.1，允许随游戏分发（关联控制清单 G8 资产阻塞，真机分发前由 art/eng 协同 closing）

2. 把文件放到本目录，命名为：
   ```
   godot/assets/fonts/NotoSansSC-Regular.ttf
   ```
   即与 `res://assets/fonts/NotoSansSC-Regular.ttf` 对应。

3. 放置后，`scripts/theme/portrait_theme.tres` 的 `default_font` 即指向该字体，
   所有 `Label` / `Button` 经主题继承默认字体，中文正常渲染（否则为豆腐块，R1 最高优先）。

4. 验证：编辑器内打开 `scenes/play/ScenarioCard.tscn`，或跑 GUT 用例 `test_cjk_font.gd`。
   真机中文渲染须以 iOS/Android 真机为准（B3，模拟器不可作为唯一验证）。

> 注意：未放置字体前，`portrait_theme.tres` 仍能加载但 `default_font` 为 null；
> `test_cjk_font.gd` 会因此 assert 失败——这是预期，放好字体后即绿。
