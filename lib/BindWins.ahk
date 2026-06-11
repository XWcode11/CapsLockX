; Window binding groups — pure V2 data layer.
; Data file: CapsLockX-wins.ini, one section per slot:
;   [1]
;   bindType=2
;   win1=class|exe|id
;   win2=class|exe|id
; Entries are contiguously numbered from win1; every change rewrites the
; whole section (no sparse-index key shuffling).
; NOTE: entries are plain objects accessed only via dot properties
; (e.cls / e.exe / e.id) — dynamic subscript access is forbidden here.

class BindWins {
    static INI_FILE := "CapsLockX-wins.ini"
    static MAX_GROUPS := 20

    __New() {
        this.winsInfos := Map()
        this.tapCounts := Map()
        this.tapBtn := -1
        this.winTapedX := -1
        this.lastActiveWinId := 0
        this.gettingWinInfo := false
        this.doGetWinInfoTimer := ""
        Loop BindWins.MAX_GROUPS
            this.InitGroup(A_Index)
    }

    IniPath() => A_ScriptDir "\" BindWins.INI_FILE

    ActiveWinId() => WinExist("A")

    static MakeEntry(cls, exe, id) {
        return {cls: cls, exe: exe, id: id}
    }

    Init() {
        ini := this.IniPath()
        if !FileExist(ini) {
            SafeFileAppend(
                "; CapsLockX - window binding data`n; Do not edit manually.`n",
                ini, "UTF-16"
            )
            return
        }
        Loop BindWins.MAX_GROUPS {
            n := A_Index
            section := String(n)
            bt := ""
            try bt := IniRead(ini, section, "bindType", "")
            if (bt = "")
                continue
            gx := this.Group(n)
            gx.bindType := Integer(bt)
            idx := 0
            Loop {
                idx++
                val := ""
                try val := IniRead(ini, section, "win" idx, "")
                if (val = "")
                    break
                parts := StrSplit(val, "|", , 3)
                if (parts.Length = 3)
                    gx.wins.Push(BindWins.MakeEntry(parts[1], parts[2], parts[3]))
            }
        }
    }

    InitGroup(n) {
        this.winsInfos[n] := {bindType: 0, wins: []}
        this.tapCounts[n] := 0
    }

    Group(n) {
        if !this.winsInfos.Has(n)
            this.InitGroup(n)
        return this.winsInfos[n]
    }

    ; Rewrite the whole section from memory: delete then write contiguous winN keys.
    SaveGroup(n) {
        ini := this.IniPath()
        section := String(n)
        SafeIniDelete(ini, section)
        gx := this.Group(n)
        if (gx.bindType = 0 && gx.wins.Length = 0)
            return
        SafeIniWrite(gx.bindType, ini, section, "bindType")
        for i, e in gx.wins
            SafeIniWrite(e.cls "|" e.exe "|" e.id, ini, section, "win" i)
    }

    TapTimes(btnx, hotkeyName := "") {
        this.gettingWinInfo := true
        if (this.doGetWinInfoTimer)
            SetTimer(this.doGetWinInfoTimer, 0)
        this.doGetWinInfoTimer := (*) => this.DoGetWinInfo()
        SetTimer(this.doGetWinInfoTimer, -500)

        this.tapBtn := btnx
        if (!this.tapCounts.Has(btnx) || this.tapCounts[btnx] < 1)
            this.tapCounts[btnx] := 1

        if (hotkeyName != "" && hotkeyName = A_PriorHotkey && A_TimeSincePriorHotkey < 500) {
            if (this.tapCounts[btnx] < 4)
                this.tapCounts[btnx]++
        }
    }

    DoGetWinInfo() {
        if (this.doGetWinInfoTimer)
            SetTimer(this.doGetWinInfoTimer, 0)
        winBtnx := this.tapBtn
        tTapTimes := this.tapCounts.Has(winBtnx) ? this.tapCounts[winBtnx] : 0
        if (tTapTimes > 0 && winBtnx > -1)
            this.GetWinInfo(winBtnx, tTapTimes)
        if (this.tapCounts.Has(winBtnx))
            this.tapCounts[winBtnx] := 0
        this.tapBtn := -1
        this.gettingWinInfo := false
    }

    ; Caps+Win+N x4: clear slot (no foreground window required).
    ClearGroup(btnx) {
        gx := this.Group(btnx)
        hadBinding := gx.bindType != 0 || gx.wins.Length > 0
        gx.bindType := 0
        gx.wins := []
        this.SaveGroup(btnx)
        NotifyWinBind(btnx, 4, true, hadBinding ? "" : "槽位本就未绑定")
    }

    GetWinInfo(btnx, bindType) {
        if (bindType = 4) {
            this.ClearGroup(btnx)
            return
        }
        winId := WinExist("A")
        if !winId {
            NotifyWinBind(btnx, bindType, false, "未检测到活动窗口")
            return
        }
        try {
            winClass := WinGetClass("ahk_id " winId)
            winExe := WinGetProcessPath("ahk_id " winId)
        } catch {
            LogCapsLockX("GetWinInfo: cannot read active window info")
            NotifyWinBind(btnx, bindType, false, "无法读取窗口信息")
            return
        }
        gx := this.Group(btnx)

        if (bindType = 1) {
            gx.bindType := 1
            gx.wins := [BindWins.MakeEntry(winClass, winExe, winId)]
            this.SaveGroup(btnx)
            NotifyWinBind(btnx, 1, true)
            return
        }

        if (bindType = 2) {
            ; Double-tap on a type-3 group restarts it as a single binding.
            if (gx.bindType = 3) {
                gx.bindType := 1
                gx.wins := [BindWins.MakeEntry(winClass, winExe, winId)]
                this.SaveGroup(btnx)
                NotifyWinBind(btnx, 1, true)
                return
            }
            for e in gx.wins {
                if (e.id = winId) {
                    NotifyWinBind(btnx, 2, false, "该窗口已在绑定列表")
                    return
                }
            }
            gx.wins.Push(BindWins.MakeEntry(winClass, winExe, winId))
            gx.bindType := 2
            this.SaveGroup(btnx)
            NotifyWinBind(btnx, 2, true)
            return
        }

        if (bindType = 3) {
            gx.bindType := 3
            wins := []
            for hwnd in WinGetList("ahk_class " winClass " ahk_exe " winExe)
                wins.Push(BindWins.MakeEntry(winClass, winExe, hwnd))
            gx.wins := wins
            this.SaveGroup(btnx)
            NotifyWinBind(btnx, 3, true)
        }
    }

    Activate(btnx) {
        if (this.gettingWinInfo)
            this.DoGetWinInfo()

        gx := this.Group(btnx)

        if (gx.bindType = 0)
            return

        if (gx.bindType = 1) {
            if (gx.wins.Length = 0)
                return
            e := gx.wins[1]
            tempId := e.id
            if !WinExist("ahk_id " tempId) {
                tempId := WinExist("ahk_exe " e.exe " ahk_class " e.cls)
                if tempId {
                    e.id := tempId
                    this.SaveGroup(btnx)
                } else {
                    if FileExist(e.exe)
                        Run(e.exe)
                    return
                }
            }
            if WinActive("ahk_id " tempId) {
                WinMinimize("ahk_id " tempId)
                if (this.lastActiveWinId && this.lastActiveWinId != tempId)
                    WinActivate("ahk_id " this.lastActiveWinId)
                return
            }
            this.lastActiveWinId := WinExist("A")
            WinActivate("ahk_id " tempId)
            return
        }

        if (gx.bindType = 2) {
            this.winTapedX := btnx
            live := []
            for e in gx.wins {
                if WinExist("ahk_id " e.id)
                    live.Push(e)
            }
            if (live.Length != gx.wins.Length) {
                gx.wins := live
                this.SaveGroup(btnx)
            }
            if (live.Length = 0)
                return
            if (live.Length = 1) {
                gx.bindType := 1
                this.SaveGroup(btnx)
                tempId := live[1].id
                if WinActive("ahk_id " tempId) {
                    WinMinimize("ahk_id " tempId)
                    return
                }
                WinActivate("ahk_id " tempId)
                return
            }
            this.ActivateNext(gx)
            return
        }

        if (gx.bindType = 3) {
            this.winTapedX := btnx
            if (gx.wins.Length = 0)
                return
            cls := gx.wins[1].cls
            exe := gx.wins[1].exe
            live := []
            for e in gx.wins {
                if WinExist("ahk_id " e.id)
                    live.Push(e)
            }
            for hwnd in WinGetList("ahk_class " cls " ahk_exe " exe) {
                found := false
                for e in live {
                    if (e.id = hwnd) {
                        found := true
                        break
                    }
                }
                if !found
                    live.Push(BindWins.MakeEntry(cls, exe, hwnd))
            }
            if (live.Length = 0) {
                ; Keep stale entries so cls/exe survive for relaunch next time.
                if FileExist(exe)
                    Run(exe)
                return
            }
            gx.wins := live
            this.SaveGroup(btnx)
            if (live.Length = 1) {
                tempId := live[1].id
                if WinActive("ahk_id " tempId) {
                    WinMinimize("ahk_id " tempId)
                    return
                }
                WinActivate("ahk_id " tempId)
                return
            }
            this.ActivateNext(gx)
        }
    }

    ; Cycle: if the active window is in the group, go to the next one; else first.
    ActivateNext(gx) {
        actWinId := WinExist("A")
        for i, e in gx.wins {
            if (e.id = actWinId) {
                next := (i = gx.wins.Length) ? 1 : i + 1
                WinActivate("ahk_id " gx.wins[next].id)
                return
            }
        }
        WinActivate("ahk_id " gx.wins[1].id)
    }

    ; After Caps release: move the active window to the front of its group.
    WinsSort(btnx) {
        gx := this.Group(btnx)
        actWinId := this.ActiveWinId()
        moved := false
        for i, e in gx.wins {
            if (e.id = actWinId) {
                gx.wins.RemoveAt(i)
                gx.wins.InsertAt(1, e)
                moved := true
                break
            }
        }
        this.winTapedX := -1
        if moved
            this.SaveGroup(btnx)
    }
}
