[English](readme.md) | 中文

---

> [!TIP]
> <a href="https://capslox.com/cn/"><img src="https://dl.capslox.com/static/assets/image/logo/capslox-app-logo_v3_128x128@2x.png" alt="Capslox" width="80" align="left"></a>
> **[Capslox](https://capslox.com/cn/) 是 Capslock+ 的跨平台继任者。**
> Capslock+ 增强了 Caps Lock 一个键。Capslox 把这个思路扩展到整个键盘 —— 用主键盘区驱动光标、文字、窗口和剪贴板，自带开箱即用的快捷键方案，分层的快捷键还可以按应用切换。支持 macOS 和 Windows。

---

master 分支：v3.0+

v2 分支：v2.x

[官网（说明文档）](https://capslox.com/capslock-plus/)


## 怎么运行源码？
1. 下载并安装 [AutoHotkey v2](https://www.autohotkey.com/)。
2. 克隆本仓库。
3. 运行 `CapsLockX.ahk`。

## 怎么自定义热键？
编辑 `CapsLockX-settings.ini` 的 `[Keys]` 字段，保存后约 0.5 秒内自动生效（无需重载）。可用的动作名即 `lib/Keys.ahk` 中 `KeyActions` 类的方法名，例如：

    caps_f7=reload

## 项目结构
`CapsLockX.ahk` 是入口文件，其他依赖文件在 `/lib` 里，各文件说明如下：

|文件|说明|
|:---|:---|
|CapsLockX.ahk|入口：Caps 层生命周期与按键处理|
|lib/CapsEntry.ahk|CapsLock 入口热键|
|lib/CapsHotkeys.ahk|层热键注册（仅按住 Caps 时开启）|
|lib/CapsLayer.ahk|层生命周期、轻点判定、看门狗|
|lib/Keys.ahk|按键动作与默认布局|
|lib/BindWins.ahk|窗口绑定（数据在 CapsLockX-wins.ini）|
|lib/Settings.ahk|CapsLockX-settings.ini 读取与热更新|
|lib/CapsRepeatGuard.ahk|单发按键的重复抑制|
|lib/RemoteForeground.ahk|远程桌面前台时暂停 Caps 层|
|lib/Tray.ahk|托盘图标与菜单|
|lib/Util.ahk|公共工具（安全 IO、日志）|
|tests/run_tests.ahk|测试套件（用 `tests/run_tests.ps1` 运行）|
|build.ps1|编译 CapsLockX.exe 到 release/|

