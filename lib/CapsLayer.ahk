; Caps layer lifecycle — dynamic Hotkey On/Off only while Caps is held.
; No #HotIf: when Off, layer keys are not in the keyboard hook at all.

ForceReleaseCapsLayer() {
    global capsLockBusy
    global g_layerHotkeysOn
    if (capsLockBusy || g_layerHotkeysOn)
        LogCapsLockX("ForceReleaseCapsLayer")
    capsLockBusy := false
    try SetLayerHotkeys(false)
    try CapsRepeatGuard.Reset()
    try SetCapsEntryHotkeys(true)
}

; True only when Caps is still physically down — safe to enable layer hotkeys.
CapsPhysicallyHeld() => GetKeyState("CapsLock", "P")

; Set true by layer key handlers while Caps is held; checked on release.
global g_layerKeyFired := false

; Deterministic tap check: no layer key fired and held shorter than threshold.
IsCapsTap(layerKeyFired, heldMs, thresholdMs := 300) {
    return !layerKeyFired && heldMs < thresholdMs
}

; Turn layer hotkeys on only if Caps is down; returns whether layer is active.
ActivateCapsLayerHotkeys() {
    global capsLockBusy
    if !CapsPhysicallyHeld()
        return false
    capsLockBusy := true
    SetLayerHotkeys(true)
    return true
}

DeactivateCapsLayerHotkeys() {
    global capsLockBusy
    capsLockBusy := false
    SetLayerHotkeys(false)
    try CapsRepeatGuard.Reset()
}

WaitForCapsLockRelease() {
    if CapsPhysicallyHeld()
        KeyWait("CapsLock")
}

class CapsLayerWatchdog {
    static tickFn := ""
    static busySince := 0
    static capsReleasedSince := 0
    static CAPS_RELEASE_FORCE_MS := 1000
    static BUSY_MAX_MS := 120000

    static Start() {
        ForceReleaseCapsLayer()
        try Hotkey("^!F12", (*) => ForceReleaseCapsLayer(), "On")
        if this.tickFn
            return
        this.tickFn := this.Tick.Bind(this)
        SetTimer(this.tickFn, 150)
    }

    static Tick() {
        global capsLockBusy, g_layerHotkeysOn
        if capsLockBusy {
            if CapsPhysicallyHeld() {
                this.capsReleasedSince := 0
                if !this.busySince
                    this.busySince := A_TickCount
                else if (A_TickCount - this.busySince > this.BUSY_MAX_MS)
                    ForceReleaseCapsLayer()
                return
            }
            if !this.capsReleasedSince
                this.capsReleasedSince := A_TickCount
            else if (A_TickCount - this.capsReleasedSince > this.CAPS_RELEASE_FORCE_MS)
                ForceReleaseCapsLayer()
            return
        }
        this.busySince := 0
        this.capsReleasedSince := 0
        if g_layerHotkeysOn
            ForceReleaseCapsLayer()
    }
}
