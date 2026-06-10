#Requires AutoHotkey v2.0
; Run: AutoHotkey64.exe tests\run_tests.ahk

#Include ..\lib\Util.ahk
#Include ..\lib\IdxStore.ahk
#Include ..\lib\Keys.ahk
#Include ..\lib\BindWins.ahk

global g_passed := 0
global g_failed := 0

AssertTrue(cond, name) {
    global g_passed, g_failed
    if cond {
        g_passed++
    } else {
        g_failed++
        OutputLine("FAIL: " name)
    }
}

AssertEqual(actual, expected, name) {
    AssertTrue(actual = expected, name " (got: " actual ", want: " expected ")")
}

OutputLine(msg) {
    try FileAppend(msg "`n", A_ScriptDir "\test-results.log", "UTF-8")
    OutputDebug(msg)
}

class TestBindWins extends BindWins {
    __New(iniPath) {
        super.__New()
        this.testIniPath := iniPath
    }
    IniPath() => this.testIniPath
}

; --- IdxStore ---
RunIdxStoreTests() {
    s := IdxStore()
    AssertTrue(s.IsEmpty(), "IdxStore starts empty")
    AssertEqual(s.MaxIndex(), -1, "IdxStore MaxIndex empty")

    s.Set(0, "a")
    s.Set(1, "b")
    AssertEqual(s.MaxIndex(), 1, "IdxStore MaxIndex after two sets")
    AssertEqual(s.Get(0), "a", "IdxStore Get(0)")

    removed := s.Remove(0)
    AssertEqual(removed, "a", "IdxStore Remove returns value")
    AssertEqual(s.Get(0), "b", "IdxStore shift after Remove(0)")
    AssertEqual(s.MaxIndex(), 0, "IdxStore MaxIndex after Remove")

    s2 := IdxStore()
    s2.Insert("x")
    AssertEqual(s2.Get(1), "x", "IdxStore Insert at 1 when empty max=-1")

    s3 := IdxStore()
    s3.Set(0, "first")
    s3.Set(1, "second")
    s3.InsertAt0("new0")
    AssertEqual(s3.Get(0), "new0", "IdxStore InsertAt0")
    AssertEqual(s3.Get(1), "first", "IdxStore InsertAt0 shifts")
}

; --- NormalizeActionSpec ---
RunNormalizeTests() {
    AssertEqual(NormalizeActionSpec(""), "none", "empty spec")
    AssertEqual(NormalizeActionSpec("keyFunc_doNothing"), "none", "legacy doNothing")
    AssertEqual(NormalizeActionSpec("keyFunc_copy_1"), "copy", "legacy copy_1")
    AssertEqual(NormalizeActionSpec("keyFunc_paste_1"), "paste", "legacy paste_1")
    AssertEqual(NormalizeActionSpec("keyFunc_cut_1"), "cut", "legacy cut_1")
    AssertEqual(NormalizeActionSpec("winbind_activate(3)"), "winbind_activate(3)", "winbind not stripped")
    AssertEqual(NormalizeActionSpec("  moveLeft  "), "moveLeft", "trim")
    AssertEqual(NormalizeActionSpec("custom_action_1"), "custom_action_1", "custom _1 suffix preserved")
    AssertEqual(NormalizeActionSpec("copy_2"), "copy", "legacy copy_2")
}

; --- Default bindings ---
RunDefaultBindingsTests() {
    d := GetDefaultKeyBindings()
    AssertEqual(d["caps_q"], "none", "caps_q disabled")
    AssertEqual(d["caps_c"], "copy", "caps_c system copy")
    AssertEqual(d["caps_1"], "winbind_activate(1)", "caps_1 winbind")
    AssertEqual(d["caps_0"], "none", "caps_0 disabled")
    AssertEqual(d["caps_f2"], "none", "caps_f2 math disabled")
    AssertEqual(d["caps_f5"], "reload", "caps_f5 reload")
    AssertEqual(d["caps_win_9"], "winbind_binding(9)", "caps_win_9 binding")
    AssertEqual(d["caps_win_0"], "none", "caps_win_0 disabled")
    AssertEqual(d.Get("caps_lalt_a", "missing"), "missing", "no lalt keys in defaults")
}

; --- Settings ini merge (local parser, mirrors Settings.ahk) ---
LoadBindingsFromIni(iniPath) {
    bindings := GetDefaultKeyBindings()
    try keysText := IniRead(iniPath, "Keys")
    catch
        return bindings
    Loop Parse keysText, "`n", "`r" {
        if !RegExMatch(A_LoopField, "^([^=]+)=(.*)$", &m)
            continue
        key := Trim(m[1])
        val := Trim(m[2])
        if (val != "")
            bindings[key] := NormalizeActionSpec(val)
    }
    return bindings
}

RunSettingsTests() {
    path := A_ScriptDir "\fixtures\settings_sample.ini"
    b := LoadBindingsFromIni(path)
    AssertEqual(b["caps_q"], "none", "ini override caps_q")
    AssertEqual(b["caps_f7"], "reload", "ini override caps_f7")
    AssertEqual(b["caps_c"], "copy", "ini legacy copy")
    AssertEqual(b["caps_v"], "paste", "ini legacy paste")
    AssertEqual(b["caps_a"], "moveWordLeft", "ini leaves default caps_a")
}

; --- BindWins load fixture ---
RunBindWinsTests() {
    path := A_ScriptDir "\fixtures\wins_sample.ini"
    bw := TestBindWins(path)
    bw.Init()

    g1 := bw.Group(1)
    AssertEqual(g1.bindType, 1, "bind group 1 type")
    AssertEqual(g1.class.Get(0), "Notepad", "bind group 1 class")
    AssertEqual(g1.id.Get(0), "123456", "bind group 1 id")

    g2 := bw.Group(2)
    AssertEqual(g2.bindType, 2, "bind group 2 type")
    AssertEqual(g2.id.Get(0), "111", "bind group 2 id_0")
    AssertEqual(g2.id.Get(1), "222", "bind group 2 id_1")

    g3 := bw.Group(3)
    AssertEqual(g3.bindType, 0, "unbound group 3 type")
}

; --- RunKeyAction dispatch (no Send) ---
RunKeyActionTests() {
    calls := []
    stub := {
        Activate: (n) => calls.Push("activate:" n),
        TapTimes: (n, hk := "") => calls.Push("tap:" n)
    }
    RunKeyAction("none", stub)
    AssertEqual(calls.Length, 0, "none does nothing")

    RunKeyAction("winbind_activate(2)", stub)
    AssertEqual(calls[1], "activate:2", "winbind_activate dispatch")

    RunKeyAction("winbind_binding(5)", stub, "#5")
    AssertEqual(calls[2], "tap:5", "winbind_binding dispatch")

    RunKeyAction("keyFunc_doNothing", stub)
    AssertEqual(calls.Length, 2, "legacy doNothing still no call")

    RunKeyAction("notARealAction(9)", stub)
    AssertEqual(calls.Length, 2, "invalid action does not throw")

    AssertTrue(InvokeKeyAction("moveLeft", "3"), "InvokeKeyAction valid arg")
    AssertTrue(!InvokeKeyAction("notARealAction", "1"), "InvokeKeyAction invalid name")
}

RunActivateEmptyGroupTest() {
    path := A_ScriptDir "\fixtures\wins_sample.ini"
    bw := TestBindWins(path)
    bw.Init()
    gx := bw.Group(3)
    gx.bindType := 2
    bw.Activate(3)
    AssertEqual(gx.bindType, 2, "activate empty bindType 2 no crash")
}

RunTapTimesTests() {
    bw := TestBindWins(A_ScriptDir "\fixtures\wins_sample.ini")
    bw.TapTimes(5, "#5")
    AssertEqual(bw.tapBtn, 5, "TapTimes sets tapBtn")
    AssertEqual(bw.tapCounts[5], 1, "TapTimes first tap count")
    AssertTrue(bw.gettingWinInfo, "TapTimes sets gettingWinInfo")
    bw.DoGetWinInfo()
    AssertEqual(bw.tapCounts[5], 0, "DoGetWinInfo resets tap count")
    AssertTrue(!bw.gettingWinInfo, "DoGetWinInfo clears gettingWinInfo")
}

RunUtilTests() {
    tempIni := A_Temp "\capslockx_test_" A_TickCount ".ini"
    AssertTrue(SafeIniWrite("1", tempIni, "1", "bindType"), "SafeIniWrite ok")
    AssertEqual(IniRead(tempIni, "1", "bindType"), "1", "SafeIniWrite readable")
    AssertTrue(SafeIniDelete(tempIni, "1", "bindType"), "SafeIniDelete ok")
    try FileDelete(tempIni)

    writable := IsScriptDirWritable()
    AssertTrue(writable, "test script dir writable")
}

RunBindTypeZeroTest() {
    bw := TestBindWins(A_ScriptDir "\fixtures\wins_sample.ini")
    bw.Init()
    bw.Activate(99)
    AssertEqual(bw.Group(99).bindType, 0, "activate unbound slot no-op")
}

IsQuietMode() {
    for arg in A_Args
        if (arg = "--quiet" || arg = "-q")
            return true
    return false
}

; --- main ---
quiet := IsQuietMode()
try FileDelete(A_ScriptDir "\test-results.log")

RunIdxStoreTests()
RunNormalizeTests()
RunDefaultBindingsTests()
RunSettingsTests()
RunBindWinsTests()
RunKeyActionTests()
RunActivateEmptyGroupTest()
RunTapTimesTests()
RunUtilTests()
RunBindTypeZeroTest()

summary := "CapsLockX tests: " g_passed " passed, " g_failed " failed"
OutputLine(summary)
if !quiet
    MsgBox(summary, "CapsLockX Tests", g_failed ? "Icon!" : "Iconi")
else
    FileAppend(summary "`n", A_ScriptDir "\test-results.log", "UTF-8")

ExitApp(g_failed ? 1 : 0)
