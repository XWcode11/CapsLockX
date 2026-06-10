; Suppress OS key-repeat for single-shot Caps layer actions until the key is released.

PhysicalKeyFromHotkey(hotkeyName) {
    key := RegExReplace(hotkeyName, "^\$", "")
    if RegExMatch(key, "^#(\d)$", &m)
        return m[1]
    return key
}

class CapsRepeatGuard {
    static blocked := Map()
    static pollFn := ""

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
        if this.pollFn
            return
        this.pollFn := this.Poll.Bind(this)
        SetTimer(this.pollFn, 20)
    }

    static StopPoll() {
        if !this.pollFn
            return
        SetTimer(this.pollFn, 0)
        this.pollFn := ""
    }

    static Poll() {
        if !this.blocked.Count {
            this.StopPoll()
            return
        }
        remove := []
        for hk, key in this.blocked {
            if !GetKeyState(key, "P")
                remove.Push(hk)
        }
        for hk in remove
            this.blocked.Delete(hk)
        if !this.blocked.Count
            this.StopPoll()
    }

    static Reset() {
        this.blocked := Map()
        this.StopPoll()
    }
}
