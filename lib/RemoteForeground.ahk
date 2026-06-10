; Detect when keyboard focus is in a remote-forwarding client (any vendor).

; Builtin exe/class always suspend the layer; ini extras need remoteLayerSuspend=1.



class RemoteForeground {

    static defaultExes := [

        "mstsc.exe", "msrdc.exe",

        "vmware-remotemks.exe", "vmware-view.exe",

        "wfica32.exe",

        "parsecd.exe",

        "teamviewer.exe", "anydesk.exe",

        "sunloginclient.exe", "awesun.exe",

        "todesk.exe",

        "rustdesk.exe",

        "mremoteng.exe",

        "vncviewer.exe", "tvnviewer.exe",

        "virtviewer.exe",

        "dwagent.exe",

        "nxplayer.bin", "nxrunner.exe",

    ]

    static defaultClassPrefixes := [

        "tscshell",

        "rail_window",

        "vmwarefullscreenwindow",

    ]

    static defaultTitleHints := [

        "remote desktop",

        "chrome remote desktop",

        "novnc",

        "guacamole",

        "vnc viewer",

        "向日葵",

    ]



    static userExes := []

    static userClassPrefixes := []

    static userTitleHints := []

    static listsLoaded := false

    static settingsMtime := ""

    static cacheHwnd := 0

    static cacheTick := 0

    static cacheResult := false



    static EnsureUserLists() {

        try FileGetTime(&mtime, Settings.Path())

        catch

            mtime := ""

        if (this.listsLoaded && mtime = this.settingsMtime)

            return

        this.settingsMtime := mtime

        this.listsLoaded := true

        this.userExes := []

        this.userClassPrefixes := []

        this.userTitleHints := []

        if Settings.GetGlobal("remoteLayerSuspend", "1") = "0"

            return

        this.MergeCsv(this.userExes, Settings.GetGlobal("remoteForegroundExes", ""))

        this.MergeCsv(this.userClassPrefixes, Settings.GetGlobal("remoteForegroundClasses", ""))

        this.MergeCsv(this.userTitleHints, Settings.GetGlobal("remoteForegroundTitleHints", ""))

    }



    static MergeCsv(arr, csv) {

        if (csv = "")

            return

        for part in StrSplit(csv, ",") {

            item := Trim(part)

            if (item = "")

                continue

            item := StrLower(item)

            if !this.Contains(arr, item)

                arr.Push(item)

        }

    }



    static Contains(arr, value) {

        for v in arr {

            if (v = value)

                return true

        }

        return false

    }



    static ClassMatchesPrefix(className, prefix) {

        return InStr(StrLower(className), StrLower(prefix)) = 1

    }



    static Invalidate() {

        this.listsLoaded := false

        this.cacheHwnd := 0

    }



    static MatchExeList(exe, names) {

        if (exe = "")

            return false

        for name in names {

            if (exe = name)

                return true

        }

        return false

    }



    static MatchClassList(className, prefixes) {

        if (className = "")

            return false

        for prefix in prefixes {

            if this.ClassMatchesPrefix(className, prefix)

                return true

        }

        return false

    }



    static MatchTitleList(title, hints) {

        if (title = "")

            return false

        title := StrLower(title)

        for hint in hints {

            if InStr(title, hint)

                return true

        }

        return false

    }



    static MatchBuiltin(hwnd) {

        try exe := StrLower(WinGetProcessName(hwnd))

        catch

            exe := ""

        if this.MatchExeList(exe, this.defaultExes)

            return true

        try class := WinGetClass(hwnd)

        catch

            class := ""

        return this.MatchClassList(class, this.defaultClassPrefixes)

    }



    static MatchUser(hwnd) {

        try exe := StrLower(WinGetProcessName(hwnd))

        catch

            exe := ""

        if this.MatchExeList(exe, this.userExes)

            return true

        try class := WinGetClass(hwnd)

        catch

            class := ""

        if this.MatchClassList(class, this.userClassPrefixes)

            return true

        try title := WinGetTitle(hwnd)

        catch

            title := ""

        if this.MatchTitleList(title, this.userTitleHints)

            return true

        if this.MatchTitleList(title, this.defaultTitleHints)

            return true

        return false

    }



    static IsActive() {

        try hwnd := WinExist("A")

        catch

            return false

        if !hwnd

            return false



        now := A_TickCount

        if (hwnd = this.cacheHwnd && now - this.cacheTick < 40)

            return this.cacheResult



        result := this.MatchBuiltin(hwnd)

        if !result {

            this.EnsureUserLists()

            result := this.MatchUser(hwnd)

        }



        this.cacheHwnd := hwnd

        this.cacheTick := now

        this.cacheResult := result

        return result

    }

}



CapsLayerBlocked() => RemoteForeground.IsActive()



IsRemoteInputForeground() => CapsLayerBlocked()

