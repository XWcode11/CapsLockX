#Include IdxStore.ahk

class BindWins {
    static INI_FILE := "CapsLock+winsInfosRecorder.ini"

    __New() {
        this.winsInfos := Map()
        this.tapCounts := Map()
        this.tapBtn := -1
        this.winTapedX := -1
        this.lastActiveWinId := 0
        this.gettingWinInfo := false
        this.doGetWinInfoTimer := ""
        Loop 20
            this.InitGroup(A_Index)
    }

    IniPath() => A_ScriptDir "\" BindWins.INI_FILE

    Init() {
        ini := this.IniPath()
        if !FileExist(ini) {
            SafeFileAppend(
                "; CapsLockX - window binding data`n; Do not edit manually.`n`n[0]`n",
                ini, "UTF-16"
            )
        }
        Loop 20 {
            n := A_Index
            section := String(n)
            try {
                bt := IniRead(ini, section, "bindType", "")
            } catch {
                continue
            }
            if (bt = "")
                continue
            gx := this.winsInfos[n]
            gx.bindType := Integer(bt)
            try {
                keys := IniRead(ini, section)
            } catch
                continue
            Loop Parse keys, "`n", "`r" {
                line := A_LoopField
                if !RegExMatch(line, "^([^=]+)=(.*)$", &m)
                    continue
                key := m[1]
                val := m[2]
                if (key = "bindType")
                    continue
                if RegExMatch(key, "^(class|exe|id)_(\d+)$", &p) {
                    gx[p[1]].Set(Integer(p[2]), val)
                }
            }
        }
    }

    InitGroup(n) {
        this.winsInfos[n] := {
            bindType: 0,
            class: IdxStore(),
            exe: IdxStore(),
            id: IdxStore()
        }
        this.tapCounts[n] := 0
    }

    Group(n) {
        if !this.winsInfos.Has(n)
            this.InitGroup(n)
        return this.winsInfos[n]
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
            if (this.tapCounts[btnx] < 2)
                this.tapCounts[btnx] := 2
            else
                this.tapCounts[btnx] := 3
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

    GetWinInfo(btnx, bindType) {
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
        ini := this.IniPath()
        gx := this.Group(btnx)
        section := String(btnx)

        if (bindType = 1) {
            gx.bindType := 1
            gx.id.Set(0, winId)
            gx.class.Set(0, winClass)
            gx.exe.Set(0, winExe)
            if !FileExist(ini) {
                LogCapsLockX("GetWinInfo: CapsLock+winsInfosRecorder.ini missing")
                NotifyWinBind(btnx, 1, false, "绑定数据文件不存在")
                return
            }
            SafeIniWrite(1, ini, section, "bindType")
            SafeIniWrite(winClass, ini, section, "class_0")
            SafeIniWrite(winExe, ini, section, "exe_0")
            SafeIniWrite(winId, ini, section, "id_0")
            mx := gx.id.MaxIndex()
            Loop mx {
                i := mx - A_Index + 1
                if (i = 0)
                    continue
                SafeIniDelete(ini, section, "class_" i)
                SafeIniDelete(ini, section, "exe_" i)
                SafeIniDelete(ini, section, "id_" i)
                gx.class.Remove(i)
                gx.exe.Remove(i)
                gx.id.Remove(i)
            }
            NotifyWinBind(btnx, 1, true)
            return
        }

        if (bindType = 2) {
            if (gx.bindType = 3) {
                gx.class.Set(0, winClass)
                gx.exe.Set(0, winExe)
                gx.id.Set(0, winId)
                SafeIniWrite(winClass, ini, section, "class_0")
                SafeIniWrite(winExe, ini, section, "exe_0")
                SafeIniWrite(winId, ini, section, "id_0")
                mx := gx.id.MaxIndex()
                Loop mx {
                    i := mx - A_Index + 1
                    if (i = 0)
                        continue
                    SafeIniDelete(ini, section, "class_" i)
                    SafeIniDelete(ini, section, "exe_" i)
                    SafeIniDelete(ini, section, "id_" i)
                    gx.class.Remove(i)
                    gx.exe.Remove(i)
                    gx.id.Remove(i)
                }
                gx.bindType := 1
                SafeIniWrite(1, ini, section, "bindType")
                NotifyWinBind(btnx, 1, true)
                return
            }
            index := gx.id.MaxIndex() + 1
            Loop index {
                if (gx.id.Get(A_Index - 1) = winId) {
                    NotifyWinBind(btnx, 2, false, "该窗口已在绑定列表")
                    return
                }
            }
            gx.class.Insert(winClass)
            gx.exe.Insert(winExe)
            idx := gx.id.Insert(winId)
            SafeIniWrite(winClass, ini, section, "class_" idx)
            SafeIniWrite(winExe, ini, section, "exe_" idx)
            SafeIniWrite(winId, ini, section, "id_" idx)
            gx.bindType := 2
            SafeIniWrite(2, ini, section, "bindType")
            NotifyWinBind(btnx, 2, true)
            return
        }

        if (bindType = 3) {
            gx.bindType := 3
            winList := WinGetList("ahk_class " winClass " ahk_exe " winExe)
            uselessLength := gx.id.MaxIndex() + 1 - winList.Length
            gx.class.Set(0, winClass)
            gx.exe.Set(0, winExe)
            Loop winList.Length
                gx.id.Set(A_Index - 1, winList[A_Index])
            SafeIniWrite(winClass, ini, section, "class_0")
            SafeIniWrite(winExe, ini, section, "exe_0")
            Loop winList.Length {
                index := A_Index - 1
                SafeIniWrite(winList[A_Index], ini, section, "id_" index)
            }
            Loop uselessLength {
                index := winList.Length + uselessLength - A_Index
                gx.class.Remove(index)
                gx.exe.Remove(index)
                gx.id.Remove(index)
                SafeIniDelete(ini, section, "class_" index)
                SafeIniDelete(ini, section, "exe_" index)
                SafeIniDelete(ini, section, "id_" index)
            }
            SafeIniWrite(3, ini, section, "bindType")
            NotifyWinBind(btnx, 3, true)
        }
    }

    Activate(btnx) {
        if (this.gettingWinInfo)
            this.DoGetWinInfo()

        gx := this.Group(btnx)
        ini := this.IniPath()
        section := String(btnx)

        if (gx.bindType = 0)
            return

        if (gx.bindType = 1) {
            tempId := gx.id.Get(0)
            if !WinExist("ahk_id " tempId) {
                tempClass := gx.class.Get(0)
                tempExe := gx.exe.Get(0)
                tempId := WinExist("ahk_exe " tempExe " ahk_class " tempClass)
                if tempId
                    SafeIniWrite(tempId, ini, section, "id_0")
                else {
                    if FileExist(tempExe)
                        Run(tempExe)
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
            maxIndex := gx.id.MaxIndex()
            Loop maxIndex + 1 {
                index := maxIndex + 1 - A_Index
                tempId := gx.id.Get(index)
                if !WinExist("ahk_id " tempId) {
                    gx.class.Remove(index)
                    gx.exe.Remove(index)
                    gx.id.Remove(index)
                    SafeIniDelete(ini, section, "class_" index)
                    SafeIniDelete(ini, section, "exe_" index)
                    SafeIniDelete(ini, section, "id_" index)
                }
            }
            if (gx.id.IsEmpty())
                return
            if (gx.id.MaxIndex() = 0) {
                SafeIniWrite(1, ini, section, "bindType")
                gx.bindType := 1
                tempId := gx.id.Get(0)
                if !tempId
                    return
                if WinActive("ahk_id " tempId) {
                    WinMinimize("ahk_id " tempId)
                    return
                }
                WinActivate("ahk_id " tempId)
                return
            }
            actWinId := WinExist("A")
            Loop gx.id.MaxIndex() + 1 {
                i := A_Index - 1
                if (gx.id.Get(i) = actWinId) {
                    if (i = gx.id.MaxIndex()) {
                        WinActivate("ahk_id " gx.id.Get(0))
                        return
                    }
                    WinActivate("ahk_id " gx.id.Get(i + 1))
                    return
                }
            }
            firstId := gx.id.Get(0)
            if firstId
                WinActivate("ahk_id " firstId)
            return
        }

        if (gx.bindType = 3) {
            this.winTapedX := btnx
            tempClass := gx.class.Get(0)
            tempExe := gx.exe.Get(0)
            maxIndex := gx.id.MaxIndex()
            Loop maxIndex + 1 {
                index := maxIndex + 1 - A_Index
                tempId := gx.id.Get(index)
                if !WinExist("ahk_id " tempId)
                    gx.id.Remove(index)
            }
            winList := WinGetList("ahk_class " tempClass " ahk_exe " tempExe)
            for hwnd in winList {
                isExist := false
                Loop gx.id.MaxIndex() + 1 {
                    if (gx.id.Get(A_Index - 1) = hwnd) {
                        isExist := true
                        break
                    }
                }
                if !isExist
                    gx.id.Insert(hwnd)
            }
            if (gx.id.IsEmpty()) {
                if FileExist(tempExe)
                    Run(tempExe)
                return
            }
            if (gx.id.MaxIndex() = 0) {
                tempId := gx.id.Get(0)
                if !tempId
                    return
                if WinActive("ahk_id " tempId) {
                    WinMinimize("ahk_id " tempId)
                    return
                }
                WinActivate("ahk_id " tempId)
                return
            }
            actWinId := WinExist("A")
            Loop gx.id.MaxIndex() + 1 {
                i := A_Index - 1
                if (gx.id.Get(i) = actWinId) {
                    if (i = gx.id.MaxIndex()) {
                        WinActivate("ahk_id " gx.id.Get(0))
                        return
                    }
                    WinActivate("ahk_id " gx.id.Get(i + 1))
                    return
                }
            }
            firstId := gx.id.Get(0)
            if firstId
                WinActivate("ahk_id " firstId)
        }
    }

    WinsSort(btnx) {
        gx := this.Group(btnx)
        actWinId := WinExist("A")
        Loop gx.id.MaxIndex() + 1 {
            i := A_Index - 1
            if (gx.id.Get(i) = actWinId) {
                idVal := gx.id.Get(i)
                gx.id.Remove(i)
                gx.id.InsertAt0(idVal)
            }
        }
        this.winTapedX := -1
    }
}
