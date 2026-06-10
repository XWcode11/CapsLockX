#Requires AutoHotkey v2.0
#SingleInstance Force

#Include lib\Util.ahk
#Include lib\BindWins.ahk
#Include lib\Settings.ahk

global CL_VERSION := "CapsLockX 1.0.0"
global capsLockHeld := false
global capsLockTapToggle := true
global capsLockBusy := false
global g_hotkeysRegistered := false
global winBinder
winBinder := BindWins()
global keyBindings := Map()

SetStoreCapsLockMode(false)
SendMode("Input")
ProcessSetPriority("Normal")
A_MaxHotkeysPerInterval := 500
A_MaxThreadsPerHotkey := 1
InstallKeybdHook(true)

OnExit(LogExit)
OnError(CapsLockX_OnError)

; Declare #HotIf expression once; runtime HotIf "capsLockHeld" reuses it (same as CapsLock+ #If CapsLock).
#HotIf capsLockHeld
#HotIf

try {
    keyBindings := Settings.LoadKeyBindings()
    winBinder.Init()
    RegisterCapsHotkeys()
} catch as err {
    LogCapsLockX("Startup failed: " err.Message)
    MsgBox("CapsLockX 启动失败:`n" err.Message, "CapsLockX", "Icon!")
    ExitApp(1)
}

if !IsScriptDirWritable()
    TrayTip("CapsLockX", "配置目录不可写，窗口绑定/设置可能无法保存。", "Icon!")

if FileExist(A_ScriptDir "\capslock+icon.ico")
    TraySetIcon(A_ScriptDir "\capslock+icon.ico")

CapsLock:: {
    HandleCapsLockDown(false)
}

<!CapsLock:: {
    HandleCapsLockDown(true)
}

#CapsLock:: {
    HandleCapsLockDown(true)
}

HandleCapsLockDown(suppressTapToggle := false) {
    global capsLockHeld, capsLockTapToggle, capsLockBusy, winBinder, keyBindings
    if capsLockBusy
        return
    capsLockBusy := true
    capsLockHeld := true
    if !suppressTapToggle {
        capsLockTapToggle := true
        SetTimer(ClearCapsLockTapToggle, -300)
    } else {
        capsLockTapToggle := false
    }

    KeyWait("CapsLock")
    capsLockHeld := false

    if (capsLockTapToggle) {
        spec := Settings.GetPressCaps(keyBindings)
        RunKeyAction(spec, winBinder)
    }

    if (winBinder.winTapedX != -1)
        winBinder.WinsSort(winBinder.winTapedX)

    capsLockBusy := false
}

ClearCapsLockTapToggle(*) {
    global capsLockTapToggle
    capsLockTapToggle := false
}

RegisterCapsHotkeys() {
    global g_hotkeysRegistered
    if g_hotkeysRegistered
        return

    prevMax := A_MaxHotkeysPerInterval
    A_MaxHotkeysPerInterval := 2000

    HotIf "capsLockHeld"

    letters := "abcdefghijklmnopqrstuvwxyz"
    Loop Parse letters {
        key := A_LoopField
        sk := "caps_" key
        CapsHotkey(key, CapsKeyHandler.Bind(sk))
    }

    Loop 10 {
        key := String(A_Index == 10 ? 0 : A_Index)
        sk := "caps_" key
        CapsHotkey(key, CapsKeyHandler.Bind(sk))
    }

    Loop 12
        CapsHotkey("f" A_Index, CapsKeyHandler.Bind("caps_f" A_Index))

    symbols := Map(
        "``", "caps_backquote",
        "-", "caps_minus",
        "=", "caps_equal",
        "[", "caps_leftSquareBracket",
        "]", "caps_rightSquareBracket",
        "\", "caps_backslash",
        ";", "caps_semicolon",
        "'", "caps_quote",
        ",", "caps_comma",
        ".", "caps_dot",
        "/", "caps_slash"
    )
    for hk, sk in symbols
        CapsHotkey(hk, CapsKeyHandler.Bind(sk))

    specials := Map(
        "Space", "caps_space",
        "Tab", "caps_tab",
        "Enter", "caps_enter",
        "Backspace", "caps_backspace",
        "RAlt", "caps_ralt"
    )
    for hk, sk in specials
        CapsHotkey(hk, CapsKeyHandler.Bind(sk))

    Loop 9
        CapsHotkey("#" A_Index, WinBindHandler.Bind(A_Index))

    HotIf
    A_MaxHotkeysPerInterval := prevMax
    g_hotkeysRegistered := true
}

CapsHotkey(key, callback) {
    Hotkey("$" key, callback, "On")
}

CapsKeyHandler(settingKey, hotkeyName, *) {
    global capsLockTapToggle, keyBindings, winBinder
    capsLockTapToggle := false
    try {
        spec := keyBindings.Get(settingKey, "none")
        RunKeyAction(spec, winBinder, hotkeyName)
    } catch as err {
        LogCapsLockX("CapsKeyHandler [" settingKey "]: " err.Message)
    }
}

WinBindHandler(n, hotkeyName, *) {
    global capsLockTapToggle, keyBindings, winBinder
    capsLockTapToggle := false
    try {
        sk := "caps_win_" n
        spec := keyBindings.Get(sk, "winbind_binding(" n ")")
        RunKeyAction(spec, winBinder, hotkeyName)
    } catch as err {
        LogCapsLockX("WinBindHandler [" n "]: " err.Message)
    }
}

CapsLockX_OnError(exc, mode) {
    LogCapsLockX("OnError mode=" mode " " exc.Message)
    return true
}

LogExit(reason, code, *) {
    try FileAppend(
        Format("{} - {} - {}`n", A_Now, reason, code),
        A_ScriptDir "\CapsLockX-exit.log", "UTF-8"
    )
}
