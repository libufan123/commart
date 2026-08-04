# 拿到 APK · 保姆级步骤

> 你已经在浏览器登录了 GitHub，接下来只需要 **3 步**。
> 全程不需要你懂命令行，不需要装 Godot，也不需要装 Android SDK。

---

## 第 1 步：在 GitHub 上建一个空仓库

1. 打开 <https://github.com/new>
2. **Repository name** 填：`commart`
3. Public / Private 都行（Private 也能用 Actions）
4. ⚠️ **下面三个勾一个都不要打**：
   - ❌ Add a README file
   - ❌ Add .gitignore
   - ❌ Choose a license
   （打了勾会导致后面推送冲突）
5. 点绿色按钮 **Create repository**
6. 建好后页面顶部会显示一个网址，形如：

   ```
   https://github.com/你的用户名/commart.git
   ```

   **把它复制下来**（页面上有个复制小图标）

---

## 第 2 步：双击运行 `push_to_github.bat`

文件位置：

```
C:\Users\admin\WorkBuddy\2026-08-04-09-27-03\push_to_github.bat
```

1. **双击**它，会弹出一个黑色窗口
2. 窗口会让你 `Paste the repo URL here` —— 把第 1 步复制的网址**粘贴进去**
   （在黑窗口里粘贴：点右键 就是粘贴，或按 `Ctrl+V`）
3. 按 **回车**
4. 可能会弹出一个 GitHub 登录窗口 → 点 **"Sign in with your browser"**
   （你浏览器已经登录了，通常一点就过）
5. 看到 **SUCCESS** 字样 = 代码已经上传成功

> 如果出现红色报错，**把黑窗口里的报错文字截图或复制给我**，我告诉你怎么修。

---

## 第 3 步：让 GitHub 帮你编译出 APK

1. 回到浏览器，打开你刚建的仓库页面（刷新一下能看到文件了）
2. 点顶部菜单的 **Actions** 标签
3. 左侧列表点 **Build Android (APK)**
4. 右侧点 **Run workflow** → 再点弹出的绿色 **Run workflow** 按钮
5. 等 **3~6 分钟**，页面上那一行出现 ✅ 绿勾就是成功了
6. 点进这次运行的详情页，**往下滚到最底部**，有个 **Artifacts** 区域
7. 下载 **`commart-android`** → 解压出来就是 **APK 文件**

---

## 第 4 步（可选）：装到手机上

**最简单的办法**：把 APK 通过微信/QQ 发到自己手机上，点开安装。
手机会提示"未知来源应用"，允许一次即可。

**用数据线的办法**（需要开发者模式 + USB 调试）：

```
adb install commart.apk
```

---

## 几个你可能会遇到的情况

| 现象 | 原因 / 怎么办 |
|------|--------------|
| 黑窗口说 `Git is not installed` | 你电脑没装 Git，去 <https://git-scm.com/download/win> 装完再双击一次 |
| 推送报 `rejected` / `non-fast-forward` | 第 1 步误勾了 README。删掉仓库重建一个空的即可 |
| Actions 页面看不到 workflow | 刷新页面；或确认第 2 步真的 SUCCESS 了 |
| 游戏里中文全是 **方块** | 缺字体，见下方说明。**不影响 APK 能不能装、能不能玩** |

---

## 关于中文字体（不阻塞出包，但建议补）

我在沙箱里试了 4 个源都下不到（沙箱连不上 github.com / google.com），需要你手动放一次，**一次性**：

1. 打开 <https://fonts.google.com/noto/specimen/Noto+Sans+SC>
2. 点右上角 **Get font** → **Download all**，解压
3. 找到 `NotoSansSC-Regular.ttf`（如果是可变字体 `NotoSansSC[wght].ttf`，改名成 `NotoSansSC-Regular.ttf` 也能用）
4. 放进：

   ```
   C:\Users\admin\WorkBuddy\2026-08-04-09-27-03\godot\assets\fonts\
   ```

5. 然后在项目文件夹再跑一次推送（或者告诉我，我帮你提交），Actions 会自动重新出一个中文正常的 APK

> **先不补也行** —— 你可以先按上面 3 步拿到 APK 装机看看整体效果，中文方块之后再修。

---

## 备用方案：如果 `.bat` 那步实在跑不通

在 GitHub 新建的空仓库页面上，GitHub 自己会显示一段
**"…or push an existing repository from the command line"**，
把那两行复制下来，在项目文件夹里 **右键 → Open Git Bash here**，粘贴回车，效果完全一样。

实在还不行就告诉我卡在哪一步、屏幕上写了什么，我们换招。
