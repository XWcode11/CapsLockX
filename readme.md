English | [中文](README_zh-CN.md)

## What is CapsLockX?

**CapsLockX** is a Windows background utility (AutoHotkey v2) that turns **Caps Lock** into a modifier layer — the same idea as the classic **Capslock+**, rebuilt for reliability:

- **Hold Caps** → layer shortcuts active (movement, selection, clipboard, window switching).
- **Tap Caps** → toggles Caps Lock LED by default (like Windows).
- **While the layer is off** → normal typing, IME, and system shortcuts are untouched.

Layer hotkeys are registered **only while Caps is held** (dynamic On/Off), not filtered on every keystroke — so typing and input methods stay stable.

Requires **Windows** and **AutoHotkey v2** (for running from source) or use the pre-built `CapsLockX.exe`.

## Features

| Feature | Description |
|--------|-------------|
| **Home-row editing** | Vim-style `E/S/D/F` move, `I/J/K/L` select — see table below |
| **Clipboard** | `C` / `V` / `X` copy, paste, cut |
| **Window slots 1–9** | `Caps+1`…`9` activate bound windows; `Caps+Win+1`… bind current window |
| **Live settings** | Edit `CapsLockX-settings.ini` — changes apply in ~0.5s without reload |
| **Remote-desktop safe** | Caps layer auto-suspends in RDP, VMware, ToDesk, etc. |
| **Recovery** | Tray menu “释放键盘层”, or **Ctrl+Alt+F12** emergency release |

## Quick start

### Pre-built executable

1. Copy everything from `release/` to a folder (e.g. `C:\exe\capslock\`).
2. Run `CapsLockX.exe` — icon appears in the system tray.
3. Optional: tray menu → **开机自启**.

### From source

1. Install [AutoHotkey v2](https://www.autohotkey.com/).
2. Clone this repository.
3. Run `CapsLockX.ahk`.

Build a fresh exe: `.\build.ps1` → output in `release/`.

## How to use

| Action | Result |
|--------|--------|
| **Hold Caps + key** | Layer shortcut (e.g. Caps+J = select left) |
| **Tap Caps** (short press, no layer key) | Toggle Caps Lock LED (`press_caps=toggleCapsLock`) |
| **Caps + 1…9** | Switch to window bound in slot 1…9 |
| **Caps + Win + 1** (tap once) | Bind active window to slot 1 (single-window mode) |
| **Caps + Win + 1** (tap twice) | Add to slot 1 (multi-window mode) |
| **Caps + Win + 1** (tap three times) | Bind all windows of same app (type 3) |

### Default movement & selection (hold Caps)

```
        E  ↑          I  Shift+↑
    S ←   D →    J ←   L →
        F  ↓          K  Shift+↓
```

| Key | Action | Key | Action |
|-----|--------|-----|--------|
| E / D / F | Move up / down / right | I / K / L | Select up / down / right |
| S | Move left | J | Select left |
| W | Backspace | R | Delete |
| C / V / X | Copy / paste / cut | P / O | Home / End |
| Space | Enter | Backspace | Delete line |

Full defaults are in `GetDefaultKeyBindings()` in `lib/Keys.ahk`.

## Settings (`CapsLockX-settings.ini`)

### Tap Caps & IME

```ini
; Default: tap toggles Caps Lock LED (Windows-like)
press_caps=toggleCapsLock

; For Chinese IME: tap does nothing (avoids accidental uppercase English)
; press_caps=none
```

`Win+Space` and other IME switch shortcuts are **not** intercepted when Caps is not held.

### Remote desktop

```ini
remoteLayerSuspend=1
remoteForegroundExes=
remoteForegroundClasses=
remoteForegroundTitleHints=
```

Built-in clients (mstsc, VMware, ToDesk, etc.) always skip the layer; add custom exe/class/title hints for browser-based remote tools.

## Customize hotkeys

Edit the `[Keys]` section in `CapsLockX-settings.ini`. Action names are methods on the `KeyActions` class in `lib/Keys.ahk`, for example:

```ini
caps_f7=reload
caps_q=none
```

V2 action names only (`copy`, `moveLeft`, `winbind_activate(1)`, …). Legacy `keyFunc_*` names are not supported.

## Logs & troubleshooting

| File | Purpose |
|------|---------|
| `CapsLockX-error.log` | Errors, legacy key warnings |
| `CapsLockX-storm.log` | Hotkey burst diagnostics |
| Tray → **释放键盘层** | Force layer off if keys feel stuck |

## Tests

```powershell
.\tests\run_tests.ps1
# or
AutoHotkey64.exe tests\run_tests.ahk -q
```

## Project layout

| File | Description |
|------|-------------|
| `CapsLockX.ahk` | Entry: layer lifecycle and key handlers |
| `lib/CapsEntry.ahk` | CapsLock entry hotkeys |
| `lib/CapsHotkeys.ahk` | Layer hotkeys (On only while Caps held) |
| `lib/CapsLayer.ahk` | Layer lifecycle, tap detection, watchdog |
| `lib/Keys.ahk` | Key actions and default bindings |
| `lib/BindWins.ahk` | Window binding (`CapsLockX-wins.ini`) |
| `lib/Settings.ahk` | Settings load and live monitor |
| `lib/CapsRepeatGuard.ahk` | Single-shot key repeat suppression |
| `lib/RemoteForeground.ahk` | Suspend layer in remote sessions |
| `lib/HotkeyStormDiag.ahk` | Hotkey burst logging |
| `lib/Tray.ahk` | Tray icon and menu |
| `lib/Util.ahk` | Shared helpers |
| `tests/run_tests.ahk` | Test suite |
| `build.ps1` | Compile `CapsLockX.exe` into `release/` |
