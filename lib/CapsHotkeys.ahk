; Caps layer hotkeys — registered "Off" at startup, switched On only while
; HandleCapsLockDown holds the layer (between Caps down and KeyWait end).
; When Off they are NOT in the keyboard hook: typing/IME physically cannot be affected.
; No #HotIf: nothing is evaluated per keystroke while the layer is off.
; "$" + I1: own CapsSend (SendLevel 0) can never re-trigger layer keys.

global g_layerHotkeyNames := []
global g_layerHotkeysOn := false

CapsLayerBlockLAlt(*) {
}

RegisterLayerHotkeys() {
    global g_layerHotkeyNames
    names := []

    add(name, fn) {
        Hotkey(name, fn, "Off I1")
        names.Push(name)
    }
    key(name, settingKey) => add(name, CapsKeyHandler.Bind(settingKey, name))

    for c in StrSplit("abcdefghijklmnopqrstuvwxyz")
        key("$" c, "caps_" c)

    Loop 10 {
        d := Mod(A_Index, 10)
        key("$" d, "caps_" d)
    }

    Loop 12
        key("$F" A_Index, "caps_f" A_Index)

    key("$``", "caps_backquote")
    key("$-", "caps_minus")
    key("$=", "caps_equal")
    key("$[", "caps_leftSquareBracket")
    key("$]", "caps_rightSquareBracket")
    key("$\", "caps_backslash")
    key("$;", "caps_semicolon")
    key("$'", "caps_quote")
    key("$,", "caps_comma")
    key("$.", "caps_dot")
    key("$/", "caps_slash")

    key("$Space", "caps_space")
    key("$Tab", "caps_tab")
    key("$Enter", "caps_enter")
    key("$Backspace", "caps_backspace")
    key("$RAlt", "caps_ralt")

    add("$LAlt", CapsLayerBlockLAlt.Bind())

    Loop 10 {
        d := Mod(A_Index, 10)
        add("$#" d, WinBindHandler.Bind(d, "$#" d))
    }

    g_layerHotkeyNames := names
}

SetLayerHotkeys(on) {
    global g_layerHotkeyNames, g_layerHotkeysOn
    if (g_layerHotkeysOn = on)
        return
    g_layerHotkeysOn := on
    for name in g_layerHotkeyNames {
        try Hotkey(name, on ? "On" : "Off")
        catch as err
            LogCapsLockX("SetLayerHotkeys " name " " (on ? "On" : "Off") ": " err.Message)
    }
}

RegisterLayerHotkeys()
