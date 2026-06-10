; Shared helpers: safe IO, logging, permission checks

LogCapsLockX(line) {
    try FileAppend(Format("{} - {}`n", A_Now, line), A_ScriptDir "\CapsLockX-error.log", "UTF-8")
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
