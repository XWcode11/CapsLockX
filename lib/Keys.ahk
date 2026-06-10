; CapsLockX key actions and Capslox default bindings
; Actions use CapsSend (SendInput + SendLevel 0) — same role as CapsLock+ SendInput.

; Repeat policy: hold-to-repeat for movement/selection/destructive keys;
; single fire per press for clipboard, window bind, line ops, etc.
KeyActionAllowsRepeat(spec) {
    spec := NormalizeActionSpec(spec)
    if (spec = "none")
        return false
    if RegExMatch(spec, "i)^(copy|paste|cut|reload|winPin|openDocs|toggleCapsLock)")
        return false
    if RegExMatch(spec, "i)^winbind")
        return false
    if RegExMatch(spec, "i)^(enter|home|end|deleteLine|deleteToLine|selectCurrentWord)")
        return false
    if RegExMatch(spec, "i)^(move|select)")
        return true
    if RegExMatch(spec, "i)^(backspace|delete)$")
        return true
    return false
}

class KeyActions {
    static none(*) {
    }

    static moveLeft(n := 1) => CapsSend("{Left " n "}")
    static moveRight(n := 1) => CapsSend("{Right " n "}")
    static moveUp(n := 1) => CapsSend("{Up " n "}")
    static moveDown(n := 1) => CapsSend("{Down " n "}")
    static moveWordLeft(n := 1) => CapsSend("^{Left " n "}")
    static moveWordRight(n := 1) => CapsSend("^{Right " n "}")
    static backspace(*) => CapsSend("{Backspace}")
    static delete(*) => CapsSend("{Delete}")
    static end(*) => CapsSend("{End}")
    static home(*) => CapsSend("{Home}")
    static enter(*) => CapsSend("{Enter}")
    static enterWherever(*) => CapsSend("{End}{Enter}")
    static copy(*) => CapsSend("^c")
    static paste(*) => CapsSend("^v")
    static cut(*) => CapsSend("^x")
    static toggleCapsLock(*) {
        ; Layer hotkeys are Off after KeyWait; safe to toggle LED.
        SetCapsLockState(!GetKeyState("CapsLock", "T"))
    }
    static reload(*) => Reload()
    static winPin(*) {
        id := WinExist("A")
        if id
            WinSetAlwaysOnTop(-1, "ahk_id " id)
    }
    static openDocs(*) => Run("https://capslox.com/capslock-plus/")

    static deleteLine(*) => CapsSend("{End}+{Home}{Backspace}")
    static deleteToLineBeginning(*) => CapsSend("+{Home}{Backspace}")
    static deleteToLineEnd(*) => CapsSend("+{End}{Backspace}")

    static selectUp(n := 1) => CapsSend("+{Up " n "}")
    static selectDown(n := 1) => CapsSend("+{Down " n "}")
    static selectLeft(n := 1) => CapsSend("+{Left " n "}")
    static selectRight(n := 1) => CapsSend("+{Right " n "}")
    static selectHome(*) => CapsSend("+{Home}")
    static selectEnd(*) => CapsSend("+{End}")
    static selectWordLeft(n := 1) => CapsSend("+^{Left " n "}")
    static selectWordRight(n := 1) => CapsSend("+^{Right " n "}")
    static selectCurrentWord(*) {
        CapsSend("^{Left}")
        CapsSend("+^{Right}")
    }
}

GetDefaultKeyBindings() {
    d := Map()
    ; Default: tap toggles Caps LED (Windows-like). IME users: press_caps=none in ini.
    d["press_caps"] := "toggleCapsLock"

    d["caps_a"] := "moveWordLeft"
    d["caps_b"] := "moveDown(10)"
    d["caps_c"] := "copy"
    d["caps_d"] := "moveDown"
    d["caps_e"] := "moveUp"
    d["caps_f"] := "moveRight"
    d["caps_g"] := "moveWordRight"
    d["caps_h"] := "selectWordLeft"
    d["caps_i"] := "selectUp"
    d["caps_j"] := "selectLeft"
    d["caps_k"] := "selectDown"
    d["caps_l"] := "selectRight"
    d["caps_m"] := "none"
    d["caps_n"] := "selectDown(10)"
    d["caps_o"] := "selectEnd"
    d["caps_p"] := "home"
    d["caps_q"] := "none"
    d["caps_r"] := "delete"
    d["caps_s"] := "moveLeft"
    d["caps_t"] := "moveUp(10)"
    d["caps_u"] := "selectHome"
    d["caps_v"] := "paste"
    d["caps_w"] := "backspace"
    d["caps_x"] := "cut"
    d["caps_y"] := "selectUp(10)"
    d["caps_z"] := "none"

    d["caps_backquote"] := "none"
    Loop 9
        d["caps_" . A_Index] := "winbind_activate(" . A_Index . ")"
    d["caps_0"] := "none"
    d["caps_minus"] := "none"
    d["caps_equal"] := "none"
    d["caps_backspace"] := "deleteLine"
    d["caps_tab"] := "none"
    d["caps_leftSquareBracket"] := "deleteToLineBeginning"
    d["caps_rightSquareBracket"] := "none"
    d["caps_backslash"] := "none"
    d["caps_semicolon"] := "end"
    d["caps_quote"] := "none"
    d["caps_enter"] := "enterWherever"
    d["caps_comma"] := "selectCurrentWord"
    d["caps_dot"] := "selectWordRight"
    d["caps_slash"] := "deleteToLineEnd"
    d["caps_space"] := "enter"
    d["caps_ralt"] := "none"

    d["caps_f1"] := "openDocs"
    d["caps_f2"] := "none"
    d["caps_f3"] := "none"
    d["caps_f4"] := "none"
    d["caps_f5"] := "reload"
    d["caps_f6"] := "winPin"
    d["caps_f7"] := "none"
    d["caps_f8"] := "none"
    d["caps_f9"] := "none"
    d["caps_f10"] := "none"
    d["caps_f11"] := "none"
    d["caps_f12"] := "none"

    Loop 9
        d["caps_win_" . A_Index] := "winbind_binding(" . A_Index . ")"
    d["caps_win_0"] := "none"

    return d
}

; V2 action names only — V1 specs (keyFunc-prefixed, copy_1, doNothing, ...) are not recognized.
NormalizeActionSpec(spec) {
    spec := Trim(spec)
    if (spec = "")
        return "none"
    return spec
}

IsLegacyActionSpec(spec) {
    spec := Trim(spec)
    if (spec = "")
        return false
    if RegExMatch(spec, "i)^keyFunc_")
        return true
    if RegExMatch(spec, "i)^(copy|paste|cut)_\d+$")
        return true
    if (spec = "doNothing")
        return true
    return false
}

WarnLegacyKeyBindings(bindings) {
    for key, spec in bindings {
        if IsLegacyActionSpec(spec)
            LogCapsLockX("Legacy key spec ignored: " key "=" spec " (use V2 names, e.g. copy/paste)")
    }
}

InvokeKeyAction(name, args := "") {
    if !HasMethod(KeyActions, name, true)
        return false
    try {
        if (args = "") {
            KeyActions.%name%()
            return true
        }
        parts := StrSplit(args, ",")
        Loop parts.Length
            parts[A_Index] := Trim(parts[A_Index])
        if (parts.Length = 1) {
            KeyActions.%name%(Integer(parts[1]))
            return true
        }
        return false
    } catch {
        return false
    }
}

RunKeyAction(spec, bindWins, hotkeyName := "") {
    spec := NormalizeActionSpec(spec)
    if (spec = "none")
        return

    if RegExMatch(spec, "^winbind_activate\((\d+)\)$", &m) {
        try bindWins.Activate(Integer(m[1]))
        catch as err
            LogCapsLockX("winbind_activate: " err.Message)
        return
    }
    if RegExMatch(spec, "^winbind_binding\((\d+)\)$", &m) {
        try bindWins.TapTimes(Integer(m[1]), hotkeyName)
        catch as err
            LogCapsLockX("winbind_binding: " err.Message)
        return
    }

    if RegExMatch(spec, "^(\w+)\((.*)\)$", &m) {
        InvokeKeyAction(m[1], m[2])
        return
    }

    InvokeKeyAction(spec)
}
