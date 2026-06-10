English | [中文](README_zh-CN.md)

---

> [!TIP]
> <a href="https://capslox.com"><img src="https://dl.capslox.com/static/assets/image/logo/capslox-app-logo_v3_128x128@2x.png" alt="Capslox" width="80" align="left"></a>
> **[Capslox](https://capslox.com) is the cross-platform successor to Capslock+.**
> Capslock+ enriched the Caps Lock key. Capslox extends that idea across your whole keyboard — drive cursor, text, windows and clipboards from home row, with a default keymap that works out of the box and layered shortcuts you can change per app. Available on macOS and Windows.

---

master branch: v3.0+

v2 branch: v2.x

[Docs](https://capslox.com/capslock-plus/en.html)


## How to run the source code?
1. Download and install [AutoHotkey v2](https://www.autohotkey.com/)
2. Clone this repository
3. Run `CapsLockX.ahk`

## How to customize hotkeys?
Edit the `[Keys]` section in `CapsLockX-settings.ini`; changes are applied automatically within about 0.5s (no reload needed). Available action names are the methods of the `KeyActions` class in `lib/Keys.ahk`, for example:

    caps_f7=reload

## Project layout
`CapsLockX.ahk` is the entry script, library files are in the `/lib` folder:

|File|Description|
|:---|:---|
|CapsLockX.ahk|Entry: Caps layer lifecycle and key handlers|
|lib/CapsEntry.ahk|CapsLock entry hotkeys|
|lib/CapsHotkeys.ahk|Layer hotkey registration (On only while Caps held)|
|lib/CapsLayer.ahk|Layer lifecycle, tap detection, watchdog|
|lib/Keys.ahk|Key actions and default bindings|
|lib/BindWins.ahk|Window binding (data in CapsLockX-wins.ini)|
|lib/Settings.ahk|CapsLockX-settings.ini loading and live monitoring|
|lib/CapsRepeatGuard.ahk|Single-shot key repeat suppression|
|lib/RemoteForeground.ahk|Suspend the layer in remote-desktop sessions|
|lib/Tray.ahk|Tray icon and menu|
|lib/Util.ahk|Shared helpers (safe IO, logging)|
|tests/run_tests.ahk|Test suite (`tests/run_tests.ps1` to run)|
|build.ps1|Compile CapsLockX.exe into release/|

