#Requires AutoHotkey v2.0
#SingleInstance Off

#Include lib\Util.ahk
#Include lib\Tray.ahk
#Include lib\LoadAnimation.ahk
#Include lib\BindWins.ahk
#Include lib\Settings.ahk
#Include lib\CapsRepeatGuard.ahk
#Include lib\RemoteForeground.ahk
#Include lib\HotkeyStormDiag.ahk

if IsAlreadyRunning()
    ExitApp(0)

showLoading := Settings.LoadingAnimationEnabled()
if showLoading
    LoadAnimation.Show()

global CL_VERSION := "1.0.0"
global capsLockBusy := false
global winBinder
winBinder := BindWins()
global keyBindings := Map()

SetStoreCapsLockMode(false)
SendMode("Input")
ProcessSetPriority("Normal")
; CapsLock+ default; Caps repeat during hold is swallowed by entry hotkey + capsLockBusy skip.
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
    global capsLockBusy, g_layerKeyFired, winBinder, keyBindings
    if capsLockBusy {
        HotkeyStormDiag.Note("caps", A_ThisHotkey, "", "busy-skip")
        return
    }
    if CapsLayerBlocked() {
        HotkeyStormDiag.Note("caps", A_ThisHotkey, "", "remote-skip " ForegroundBrief())
        return
    }
    HotkeyStormDiag.Note("caps", A_ThisHotkey, "",
        (suppressTapToggle ? "layer-start-alt" : "layer-start") " " ForegroundBrief())
    t0 := A_TickCount
    g_layerKeyFired := false

    ; Keep entry hotkeys On so OS key-repeat cannot reach the system and toggle Caps LED.
    layerActive := ActivateCapsLayerHotkeys()
    try {
        if layerActive
            WaitForCapsLockRelease()
    } finally {
        DeactivateCapsLayerHotkeys()
        HotkeyStormDiag.Note("caps", "", "", "layer-end")
    }

    if (!suppressTapToggle && IsCapsTap(g_layerKeyFired, A_TickCount - t0)) {
        spec := Settings.GetPressCaps(keyBindings)
        RunKeyAction(spec, winBinder)
    }

    if (winBinder.winTapedX != -1)
        winBinder.WinsSort(winBinder.winTapedX)
}

CapsKeyHandler(settingKey, hotkeyName, *) {
    global g_layerKeyFired, keyBindings, winBinder
    g_layerKeyFired := true
    try {
        spec := keyBindings.Get(settingKey, "none")
        blocked := CapsRepeatGuard.ShouldBlock(hotkeyName, spec)
        HotkeyStormDiag.Note("layer", hotkeyName, settingKey,
            blocked ? "blocked" : NormalizeActionSpec(spec))
        if blocked
            return
        if !KeyActionAllowsRepeat(spec)
            CapsRepeatGuard.Arm(hotkeyName)
        RunKeyAction(spec, winBinder, hotkeyName)
    } catch as err {
        LogCapsLockX("CapsKeyHandler [" settingKey "]: " err.Message)
    }
}

WinBindHandler(n, hotkeyName, *) {
    global g_layerKeyFired, keyBindings, winBinder
    g_layerKeyFired := true
    try {
        sk := "caps_win_" n
        spec := keyBindings.Get(sk, "winbind_binding(" n ")")
        blocked := CapsRepeatGuard.ShouldBlock(hotkeyName, spec)
        HotkeyStormDiag.Note("winbind", hotkeyName, sk, blocked ? "blocked" : spec)
        if blocked
            return
        if !KeyActionAllowsRepeat(spec)
            CapsRepeatGuard.Arm(hotkeyName)
        RunKeyAction(spec, winBinder, hotkeyName)
    } catch as err {
        LogCapsLockX("WinBindHandler [" n "]: " err.Message)
    }
}

#Include lib\CapsHotkeys.ahk
#Include lib\CapsLayer.ahk
#Include lib\CapsEntry.ahk

RegisterCapsEntryHotkeys()
SetLayerHotkeys(false)
CapsLayerWatchdog.Start()

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
