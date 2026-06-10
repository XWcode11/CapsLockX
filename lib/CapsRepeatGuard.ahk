; Suppress OS key-repeat for single-shot Caps layer actions until the key is released.

PhysicalKeyFromHotkey(hotkeyName) {
    key := RegExReplace(hotkeyName, "^\$", "")
    if RegExMatch(key, "^#(\d)$", &m)
        return m[1]
    return key
}

class CapsRepeatGuard {
    static blocked := Map()
    static pollTimer := ""

    static ShouldBlock(hotkeyName, spec) {
        if KeyActionAllowsRepeat(spec)
            return false
        return this.blocked.Has(hotkeyName)
    }

    static Arm(hotkeyName) {
        if this.blocked.Has(hotkeyName)
            return
        this.blocked[hotkeyName] := PhysicalKeyFromHotkey(hotkeyName)
        this.EnsurePoll()
    }

    static EnsurePoll() {
        if this.pollTimer
            return
        this.pollTimer := SetTimer(this.Poll.Bind(this), 20)
    }

    static Poll() {
        if !this.blocked.Count {
            SetTimer(this.pollTimer, 0)
            this.pollTimer := ""
            return
        }
        remove := []
        for hk, key in this.blocked {
            if !GetKeyState(key, "P")
                remove.Push(hk)
        }
        for hk in remove
            this.blocked.Delete(hk)
        if !this.blocked.Count {
            SetTimer(this.pollTimer, 0)
            this.pollTimer := ""
        }
    }

    static Reset() {
        this.blocked := Map()
        if this.pollTimer {
            SetTimer(this.pollTimer, 0)
            this.pollTimer := ""
        }
    }
}
