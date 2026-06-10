; CapsLock layer entry — CapsLock+ model: variable flag + KeyWait.
; Entry hotkeys stay On during hold; capsLockBusy skips repeat events (prevents LED toggle).

global g_capsEntryActive := false

CapsEntryPlain(*) => HandleCapsLockDown(false)
CapsEntryWin(*) => HandleCapsLockDown(true)

RegisterCapsEntryHotkeys() {
    Hotkey("CapsLock", CapsEntryPlain, "On")
    Hotkey("#CapsLock", CapsEntryWin, "On")
    global g_capsEntryActive
    g_capsEntryActive := true
}

SetCapsEntryHotkeys(enabled) {
    global g_capsEntryActive
    if (enabled = g_capsEntryActive)
        return
    g_capsEntryActive := enabled
    if enabled {
        Hotkey("CapsLock", CapsEntryPlain, "On")
        Hotkey("#CapsLock", CapsEntryWin, "On")
    } else {
        try Hotkey("CapsLock", "Off")
        try Hotkey("#CapsLock", "Off")
    }
}
