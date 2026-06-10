; Shared helpers: safe IO, logging, permission checks

LOG_MAX_BYTES := 1048576

RotateLogIfLarge(path) {
    try {
        if FileExist(path) && FileGetSize(path) > LOG_MAX_BYTES
            FileMove(path, path ".old", 1)
    } catch {
    }
}

LogCapsLockX(line) {
    path := A_ScriptDir "\CapsLockX-error.log"
    RotateLogIfLarge(path)
    try FileAppend(Format("{} - {}`n", A_Now, line), path, "UTF-8")
}

LogCapsLockXExit(line) {
    path := A_ScriptDir "\CapsLockX-exit.log"
    RotateLogIfLarge(path)
    try FileAppend(Format("{} - {}`n", A_Now, line), path, "UTF-8")
}

; Script-generated keys must not re-trigger the Caps layer (InputLevel / SendLevel isolation).
CapsSend(keys) {
    prev := A_SendLevel
    try {
        SendLevel(0)
        Send(keys)
    } finally {
        SendLevel(prev)
    }
}

NotifyWinBind(btnx, bindType, success, detail := "") {
    try {
        if !success {
            TrayTip("窗口绑定失败", detail != "" ? detail : "槽位 " btnx, "Icon! 2")
            return
        }
        mode := bindType = 1 ? "单窗口" : bindType = 2 ? "多窗口" : bindType = 3 ? "同程序全窗口" : ""
        TrayTip("窗口绑定", "槽位 " btnx (mode != "" ? "：" mode : ""), "Iconi 1")
    } catch {
    }
}

IsScriptDirWritable() {
    testFile := A_ScriptDir "\.capslockx_write_test"
    try {
        FileAppend("", testFile, "UTF-8")
        FileDelete(testFile)
        return true
    } catch {
        return false
    }
}

SafeIniWrite(value, iniPath, section, key) {
    try {
        IniWrite(value, iniPath, section, key)
        return true
    } catch as err {
        LogCapsLockX("IniWrite failed [" section "] " key ": " err.Message)
        return false
    }
}

SafeIniDelete(iniPath, section, key := "") {
    try {
        if (key = "")
            IniDelete(iniPath, section)
        else
            IniDelete(iniPath, section, key)
        return true
    } catch as err {
        LogCapsLockX("IniDelete failed [" section "] " key ": " err.Message)
        return false
    }
}

SafeFileAppend(content, path, encoding := "UTF-8") {
    try {
        FileAppend(content, path, encoding)
        return true
    } catch as err {
        LogCapsLockX("FileAppend failed " path ": " err.Message)
        return false
    }
}
