; Tray icon and menu — CapsLockX runs in the background with no main window.

SetupTray() {
    global CL_VERSION
    iconPath := A_ScriptDir "\capslockx.ico"
    try {
        if FileExist(iconPath)
            TraySetIcon(iconPath)
        else
            TraySetIcon("imageres.dll", 112)
    } catch as err {
        LogCapsLockX("TraySetIcon failed: " err.Message)
    }

    A_IconTip := "CapsLockX " CL_VERSION "`n右键打开菜单"

    try A_TrayMenu.Delete()
    title := "CapsLockX " CL_VERSION
    A_TrayMenu.Add(title, TrayNoop)
    A_TrayMenu.Disable(title)
    A_TrayMenu.Add()
    A_TrayMenu.Add("打开设置", OpenSettings)
    A_TrayMenu.Add("释放键盘层", (*) => ForceReleaseCapsLayer())
    A_TrayMenu.Add("重载脚本", ReloadCapsLockX)
    A_TrayMenu.Add("开机自启", ToggleAutostart)
    A_TrayMenu.Add()
    A_TrayMenu.Add("退出", (*) => ExitApp())
    UpdateAutostartMenuCheck()
}

TrayNoop(*) {
}

OpenSettings(*) {
    try Run('notepad.exe "' Settings.Path() '"')
    catch as err
        LogCapsLockX("OpenSettings: " err.Message)
}

ReloadCapsLockX(*) {
    Reload()
}

ToggleAutostart(*) {
    Settings.SetAutostartEnabled(!Settings.AutostartEnabled())
}

UpdateAutostartMenuCheck() {
    try {
        if Settings.AutostartEnabled()
            A_TrayMenu.Check("开机自启")
        else
            A_TrayMenu.Uncheck("开机自启")
    } catch {
    }
}

IsAlreadyRunning() {
    DllCall("CreateMutex", "Ptr", 0, "Int", 0, "Str", "Local\CapsLockX_v1", "Ptr")
    return DllCall("GetLastError") = 183
}

