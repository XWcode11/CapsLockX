[English](readme.md) | 中文

## CapsLockX 是什么？

**CapsLockX** 是一款 Windows 后台工具（基于 AutoHotkey v2），把 **Caps Lock** 变成修饰键层，延续经典 **Capslock+** 的用法，并用更稳妥的方式重写：

- **按住 Caps** → 层内快捷键生效（移动、选区、剪贴板、窗口切换等）。
- **轻点 Caps** → 默认切换大写锁定灯（与 Windows 一致）。
- **未按住 Caps 时** → 正常打字、输入法、系统快捷键均不受影响。

层热键仅在 **按住 Caps 期间** 动态注册（On/Off），而不是每次按键都做判断，因此打字和输入法更稳定。

需要 **Windows**；从源码运行需安装 **AutoHotkey v2**，也可直接使用编译好的 `CapsLockX.exe`。

## 主要功能

| 功能 | 说明 |
|------|------|
| **主键盘区编辑** | Vim 风格：`E/S/D/F` 移动，`I/J/K/L` 扩展选区 |
| **剪贴板** | `C` / `V` / `X` 复制、粘贴、剪切 |
| **窗口槽位 1–9** | `Caps+1`…`9` 激活已绑定窗口；`Caps+Win+数字` 绑定当前窗口 |
| **设置热更新** | 改 `CapsLockX-settings.ini` 约 0.5 秒内生效，无需重载 |
| **远程桌面友好** | 在 RDP、VMware、向日葵、ToDesk 等前台时自动暂停 Caps 层 |
| **异常恢复** | 托盘「释放键盘层」，或 **Ctrl+Alt+F12** 紧急释放 |

## 快速开始

### 使用编译好的程序

1. 将 `release/` 目录下文件复制到目标文件夹（如 `C:\exe\capslock\`）。
2. 运行 `CapsLockX.exe`，托盘出现图标即可。
3. 可选：托盘菜单 → **开机自启**。

### 从源码运行

1. 安装 [AutoHotkey v2](https://www.autohotkey.com/)。
2. 克隆本仓库。
3. 运行 `CapsLockX.ahk`。

重新编译：执行 `.\build.ps1`，产物在 `release/`。

## 基本用法

| 操作 | 效果 |
|------|------|
| **按住 Caps + 字母/数字** | 层内快捷键（如 Caps+J = 向左扩展选区） |
| **轻点 Caps**（短按、未按层内键） | 切换大写灯（`press_caps=toggleCapsLock`） |
| **Caps + 1…9** | 切换到槽位 1…9 已绑定的窗口 |
| **Caps + Win + 1**（点一下） | 单窗口绑定到槽位 1 |
| **Caps + Win + 1**（连点两下） | 多窗口加入槽位 1 |
| **Caps + Win + 1**（连点三下） | 同程序全部窗口绑定（类型 3） |
| **Caps + Win + 1**（连点四下） | **清空槽位 1** 的窗口绑定 |

### 默认移动与选区（按住 Caps）

```
        E  ↑          I  Shift+↑
    S ←   D →    J ←   L →
        F  ↓          K  Shift+↓
```

| 键 | 动作 | 键 | 动作 |
|----|------|-----|------|
| E / D / F | 上 / 下 / 右移 | I / K / L | 向上 / 下 / 右扩展选区 |
| S | 左移 | J | 向左扩展选区 |
| W | 退格 | R | Delete |
| C / V / X | 复制 / 粘贴 / 剪切 | P / O | Home / End |
| 空格 | 回车 | Backspace | 删整行 |

完整默认布局见 `lib/Keys.ahk` 中的 `GetDefaultKeyBindings()`。

## 设置（`CapsLockX-settings.ini`）

### 轻点 Caps 与输入法

```ini
; 默认：轻点切换大写灯（类似 Windows）
press_caps=toggleCapsLock

; 中文输入法用户：轻点不做任何事（避免误开大写灯、拼音变英文）
; press_caps=none
```

未按住 Caps 时，**不会**拦截 `Win+Space` 等输入法切换快捷键。

### 远程桌面

```ini
remoteLayerSuspend=1
remoteForegroundExes=
remoteForegroundClasses=
remoteForegroundTitleHints=
```

内置匹配常见远程客户端；浏览器远程等可在 ini 里追加 exe、类名或标题关键字。

## 自定义热键

编辑 `CapsLockX-settings.ini` 的 `[Keys]` 段。动作名对应 `lib/Keys.ahk` 里 `KeyActions` 类的方法，例如：

```ini
caps_f7=reload
caps_q=none
```

仅支持 V2 动作名（`copy`、`moveLeft`、`winbind_activate(1)` 等），不再支持旧版 `keyFunc_*` 写法。

## 日志与排错

| 文件 | 用途 |
|------|------|
| `CapsLockX-error.log` | 错误、旧版按键名警告 |
| `CapsLockX-storm.log` | 热键洪泛诊断 |
| 托盘 → **释放键盘层** | 层卡住时强制关闭 |

## 测试

```powershell
.\tests\run_tests.ps1
# 或
AutoHotkey64.exe tests\run_tests.ahk -q
```

## 项目结构

| 文件 | 说明 |
|------|------|
| `CapsLockX.ahk` | 入口：层生命周期与按键处理 |
| `lib/CapsEntry.ahk` | CapsLock 入口热键 |
| `lib/CapsHotkeys.ahk` | 层热键注册（仅按住 Caps 时 On） |
| `lib/CapsLayer.ahk` | 层生命周期、轻点判定、看门狗 |
| `lib/Keys.ahk` | 按键动作与默认布局 |
| `lib/BindWins.ahk` | 窗口绑定（`CapsLockX-wins.ini`） |
| `lib/Settings.ahk` | 设置读取与热更新 |
| `lib/CapsRepeatGuard.ahk` | 单发按键连按抑制 |
| `lib/RemoteForeground.ahk` | 远程桌面前台暂停层 |
| `lib/HotkeyStormDiag.ahk` | 热键洪泛日志 |
| `lib/Tray.ahk` | 托盘图标与菜单 |
| `lib/Util.ahk` | 公共工具 |
| `tests/run_tests.ahk` | 测试套件 |
| `build.ps1` | 编译 `CapsLockX.exe` 到 `release/` |
