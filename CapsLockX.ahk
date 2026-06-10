#Requires AutoHotkey v2.0
#SingleInstance Off

#Include lib\Util.ahk
#Include lib\Tray.ahk
#Include lib\LoadAnimation.ahk
#Include lib\BindWins.ahk
#Include lib\Settings.ahk
#Include lib\CapsRepeatGuard.ahk

if IsAlreadyRunning()
    ExitApp(0)

showLoading := Settings.LoadingAnimationEnabled()
if showLoading
    LoadAnimation.Show()

global CL_VERSION := "CapsLockX 1.0.0"
global capsLockHeld := false
global capsLockTapToggle := true
global capsLockBusy := false
global winBinder
winBinder := BindWins()
global keyBindings := Map()

SetStoreCapsLockMode(false)
SendMode("Input")
ProcessSetPriority("Normal")
; CapsLock+ default; burst from CapsLock repeat is mitigated by SetCapsEntryHotkeys(false) during hold.
A_HotkeyInterval := 2000
A_MaxHotkeysPerInterval := 500
A_MaxThreadsPerHotkey := 1
InstallKeybdHook(true)

OnExit(LogExit)
OnError(CapsLockX_OnError)

try {
    keyBindings := Settings.LoadKeyBindings()
    winBinder.Init()
} catch as err {
    if showLoading
        LoadAnimation.Hide()
    LogCapsLockX("Startup failed: " err.Message)
    MsgBox("CapsLockX 启动失败:`n" err.Message, "CapsLockX", "Icon!")
    ExitApp(1)
}

if showLoading
    LoadAnimation.Hide()

SetupTray()
Settings.ApplyAutostart()
Settings.StartMonitor()

if !IsScriptDirWritable()
    LogCapsLockX("配置目录不可写，窗口绑定/设置可能无法保存")

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

    SetCapsEntryHotkeys(false)
    try
        KeyWait("CapsLock")
    finally {
        capsLockHeld := false
        CapsRepeatGuard.Reset()
        SetCapsEntryHotkeys(true)
    }

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

CapsKeyHandler(settingKey, hotkeyName, *) {
    global capsLockTapToggle, keyBindings, winBinder
    capsLockTapToggle := false
    try {
        spec := keyBindings.Get(settingKey, "none")
        if CapsRepeatGuard.ShouldBlock(hotkeyName, spec)
            return
        RunKeyAction(spec, winBinder, hotkeyName)
        if !KeyActionAllowsRepeat(spec)
            CapsRepeatGuard.Arm(hotkeyName)
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
        if CapsRepeatGuard.ShouldBlock(hotkeyName, spec)
            return
        RunKeyAction(spec, winBinder, hotkeyName)
        if !KeyActionAllowsRepeat(spec)
            CapsRepeatGuard.Arm(hotkeyName)
    } catch as err {
        LogCapsLockX("WinBindHandler [" n "]: " err.Message)
    }
}

#Include lib\CapsHotkeys.ahk
#Include lib\CapsEntry.ahk

RegisterCapsEntryHotkeys()

CapsLockX_OnError(exc, mode) {
    LogCapsLockX("OnError mode=" mode " " exc.Message)
    if Settings.GetGlobal("errorTrayTip", "0") = "1" {
        try TrayTip("CapsLockX 错误", exc.Message, "Icon! 3")
    }
    return true
}

LogExit(reason, code, *) {
    try LoadAnimation.Hide()
    LogCapsLockXExit(Format("{} - {} - {}", A_Now, reason, code))
}
