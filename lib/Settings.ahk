#Include Keys.ahk



class Settings {

    static FILE := "CapsLockX-settings.ini"

    static settingsMtime := ""

    static monitorTimer := ""



    static Path() => A_ScriptDir "\" this.FILE



    static EnsureFile() {

        path := this.Path()

        if FileExist(path)

            return

        SafeFileAppend(

            "; CapsLockX settings`n; [Keys] 修改后自动生效，无需重载脚本`n`n"

            . "[Global]`n"

            . "loadingAnimation=1`n"

            . "loadingAnimationMinMs=700`n"

            . "autostart=0`n"

            . "errorTrayTip=0`n`n[Keys]`n",

            path, "UTF-8"

        )

    }



    static GetGlobal(key, default := "") {

        this.EnsureFile()

        try

            return IniRead(this.Path(), "Global", key, default)

        catch

            return default

    }



    static SetGlobal(key, value) {

        this.EnsureFile()

        if !SafeIniWrite(value, this.Path(), "Global", key)

            return false

        this.RefreshMtime()

        return true

    }



    static LoadingAnimationEnabled() {

        return this.GetGlobal("loadingAnimation", "1") != "0"

    }



    static AutostartEnabled() {

        return this.GetGlobal("autostart", "0") = "1"

    }



    static SetAutostartEnabled(enabled) {

        this.SetGlobal("autostart", enabled ? "1" : "0")

        this.ApplyAutostart()

        UpdateAutostartMenuCheck()

    }



    static AutostartLnk() => A_Startup "\CapsLockX.lnk"



    static ApplyAutostart() {

        lnk := this.AutostartLnk()

        try {

            if this.AutostartEnabled() {

                FileCreateShortcut(A_ScriptFullPath, lnk, A_ScriptDir)

            } else if FileExist(lnk) {

                FileDelete(lnk)

            }

        } catch as err {

            LogCapsLockX("ApplyAutostart: " err.Message)

        }

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



    static RefreshMtime() {

        try

            FileGetTime(&t, this.Path())

        catch

            return

        this.settingsMtime := t

    }



    static StartMonitor() {

        this.RefreshMtime()

        if this.monitorTimer

            SetTimer(this.monitorTimer, 0)

        this.monitorTimer := SetTimer(this.MonitorTick.Bind(this), 500)

    }



    static MonitorTick() {

        try

            FileGetTime(&latest, this.Path())

        catch

            return

        if (latest = this.settingsMtime)

            return

        this.settingsMtime := latest

        this.OnSettingsChanged()

    }



    static OnSettingsChanged() {

        global keyBindings

        keyBindings := this.LoadKeyBindings()

        this.ApplyAutostart()

        UpdateAutostartMenuCheck()

    }

}


