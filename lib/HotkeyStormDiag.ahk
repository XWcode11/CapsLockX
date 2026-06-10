; Ring buffer of recent layer hotkey activations; flush to CapsLockX-storm.log on bursts.

LogCapsLockXStorm(text) {
    path := A_ScriptDir "\CapsLockX-storm.log"
    RotateLogIfLarge(path)
    try FileAppend(text, path, "UTF-8")
}

class HotkeyStormDiag {
    static events := []
    static maxEvents := 80
    static windowMs := 200
    static alertThreshold := 40
    static lastFlush := 0
    static settingsMtime := -1
    static enabledCache := true

    static Enabled() {
        try FileGetTime(&mtime, Settings.Path())
        catch
            mtime := ""
        if (this.settingsMtime == mtime)
            return this.enabledCache
        this.settingsMtime := mtime
        try
            this.enabledCache := Settings.GetGlobal("hotkeyStormDiag", "1") != "0"
        catch
            this.enabledCache := true
        return this.enabledCache
    }

    static Note(source, hotkey := "", settingKey := "", detail := "") {
        if !this.Enabled()
            return
        now := A_TickCount
        this.events.Push({
            t: now,
            src: source,
            hk: hotkey,
            sk: settingKey,
            detail: detail
        })
        while this.events.Length > this.maxEvents
            this.events.RemoveAt(1)

        count := 0
        cutoff := now - this.windowMs
        for ev in this.events {
            if (ev.t >= cutoff)
                count++
        }
        if (count >= this.alertThreshold && (now - this.lastFlush > 400)) {
            this.lastFlush := now
            this.Flush(count)
        }
    }

    static Flush(count) {
        lines := Format("{} HOTKEY STORM ~{} activations in {}ms (limit {}) fg={}`n",
            A_Now, count, this.windowMs, A_MaxHotkeysPerInterval, ForegroundBrief())
        for ev in this.events
            lines .= Format("  +{}ms {} hk={} sk={} {}`n",
                A_TickCount - ev.t, ev.src, ev.hk, ev.sk, ev.detail)
        lines .= "`n"
        LogCapsLockXStorm(lines)
        LogCapsLockX("hotkey storm logged to CapsLockX-storm.log (~" count " in " this.windowMs "ms)")
    }
}
