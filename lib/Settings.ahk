#Include Keys.ahk

class Settings {
    static FILE := "CapsLockX-settings.ini"

    static Path() => A_ScriptDir "\" this.FILE

    static EnsureFile() {
        path := this.Path()
        if FileExist(path)
            return
        SafeFileAppend(
            "; CapsLockX settings`n; Override keys under [Keys], then CapsLock+F5 to reload.`n`n[Global]`n`n[Keys]`n",
            path, "UTF-8"
        )
    }

    static LoadKeyBindings() {
        this.EnsureFile()
        bindings := GetDefaultKeyBindings()
        path := this.Path()
        try {
            keysText := IniRead(path, "Keys")
        } catch {
            return bindings
        }
        Loop Parse keysText, "`n", "`r" {
            line := A_LoopField
            if !RegExMatch(line, "^([^=]+)=(.*)$", &m)
                continue
            key := Trim(m[1])
            val := Trim(m[2])
            if (val != "")
                bindings[key] := NormalizeActionSpec(val)
        }
        return bindings
    }

    static GetPressCaps(bindings) {
        if bindings.Has("press_caps")
            return bindings["press_caps"]
        return "toggleCapsLock"
    }
}
