; CapsLock layer entry — CapsLock+ model: variable flag + KeyWait.
; While the layer is held, CapsLock hotkeys are turned Off so key-repeat / chatter
; does not flood A_MaxHotkeysPerInterval (each repeat still counts as a hotkey fire).

RegisterCapsEntryHotkeys() {
    Hotkey("CapsLock", (*) => HandleCapsLockDown(false), "On")
    Hotkey("<!CapsLock", (*) => HandleCapsLockDown(true), "On")
    Hotkey("#CapsLock", (*) => HandleCapsLockDown(true), "On")
}

SetCapsEntryHotkeys(enabled) {
    if enabled {
        RegisterCapsEntryHotkeys()
        return
    }
    try Hotkey("CapsLock", "Off")
    try Hotkey("<!CapsLock", "Off")
    try Hotkey("#CapsLock", "Off")
}
