#Requires AutoHotkey v2.0
; Run: AutoHotkey64.exe tests\run_tests.ahk
;
; AHK v2 constraints exercised here:
; - SetTimer(off): pass the same callback object; SetTimer's return value is NOT a handle.
; - SendLevel: CapsSend must restore A_SendLevel in finally.
; - BoundFunc: .Bind() for class methods used with SetTimer.

#Include ..\lib\Util.ahk
#Include ..\lib\IdxStore.ahk
#Include ..\lib\Keys.ahk
#Include ..\lib\BindWins.ahk
#Include ..\lib\CapsRepeatGuard.ahk

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

AssertType(value, typeName, name) {
    AssertTrue(Type(value) = typeName, name " (type: " Type(value) ", want: " typeName ")")
}

AssertDoesNotThrow(callable, name) {
    try
        callable.Call()
    catch as err {
        AssertTrue(false, name " threw: " err.Message)
        return
    }
    AssertTrue(true, name)
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
    idx := s2.Insert("x")
    AssertEqual(idx, 0, "IdxStore Insert returns 0 when empty")
    AssertEqual(s2.Get(0), "x", "IdxStore Insert at 0 when empty")

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
RunRepeatPolicyTests()
RunCapsRepeatGuardTests()
RunV2TimerContractTests()
RunCapsSendTests()
RunDefaultBindingsRepeatConsistencyTests()

RunRepeatPolicyTests() {
    AssertTrue(KeyActionAllowsRepeat("moveDown"), "moveDown allows repeat")
    AssertTrue(KeyActionAllowsRepeat("moveDown(10)"), "moveDown(10) allows repeat")
    AssertTrue(KeyActionAllowsRepeat("selectLeft"), "selectLeft allows repeat")
    AssertTrue(KeyActionAllowsRepeat("selectWordLeft"), "selectWordLeft allows repeat")
    AssertTrue(KeyActionAllowsRepeat("backspace"), "backspace allows repeat")
    AssertTrue(KeyActionAllowsRepeat("delete"), "delete allows repeat")
    AssertTrue(!KeyActionAllowsRepeat("copy"), "copy single fire")
    AssertTrue(!KeyActionAllowsRepeat("paste"), "paste single fire")
    AssertTrue(!KeyActionAllowsRepeat("none"), "none single fire")
    AssertTrue(!KeyActionAllowsRepeat("winbind_activate(1)"), "winbind_activate single fire")
    AssertTrue(!KeyActionAllowsRepeat("winbind_binding(2)"), "winbind_binding single fire")
    AssertTrue(!KeyActionAllowsRepeat("deleteLine"), "deleteLine single fire")
    AssertTrue(!KeyActionAllowsRepeat("deleteToLineBeginning"), "deleteToLineBeginning single fire")
    AssertTrue(!KeyActionAllowsRepeat("selectCurrentWord"), "selectCurrentWord single fire")
    AssertTrue(!KeyActionAllowsRepeat("reload"), "reload single fire")
    AssertEqual(PhysicalKeyFromHotkey("$j"), "j", "physical key from $j")
    AssertEqual(PhysicalKeyFromHotkey("$#3"), "3", "physical key from $#3")
    AssertEqual(PhysicalKeyFromHotkey("$Space"), "Space", "physical key from $Space")
    AssertEqual(PhysicalKeyFromHotkey("$" Chr(96)), Chr(96), "physical key from grave accent")
}

; CapsRepeatGuard lifecycle — catches SetTimer misuse and poll teardown bugs.
RunCapsRepeatGuardTests() {
    CapsRepeatGuard.Reset()

    AssertTrue(!CapsRepeatGuard.ShouldBlock("$c", "copy"), "copy not blocked before Arm")
    CapsRepeatGuard.Arm("$c")
    AssertTrue(CapsRepeatGuard.ShouldBlock("$c", "copy"), "copy blocked after Arm")
    AssertTrue(!CapsRepeatGuard.ShouldBlock("$c", "moveLeft"), "repeatable spec never blocked")
    AssertType(CapsRepeatGuard.pollFn, "Func", "pollFn is Func after Arm")
    AssertDoesNotThrow(CapsRepeatGuard.StopPoll.Bind(CapsRepeatGuard), "StopPoll when active")
    AssertEqual(CapsRepeatGuard.pollFn, "", "pollFn cleared after StopPoll")
    AssertDoesNotThrow(CapsRepeatGuard.StopPoll.Bind(CapsRepeatGuard), "StopPoll idempotent")

    CapsRepeatGuard.Arm("$c")
    AssertDoesNotThrow(CapsRepeatGuard.Reset.Bind(CapsRepeatGuard), "Reset with active poll")
    AssertEqual(CapsRepeatGuard.pollFn, "", "pollFn cleared after Reset")
    AssertTrue(!CapsRepeatGuard.ShouldBlock("$c", "copy"), "Reset clears blocked keys")

    CapsRepeatGuard.Arm("$F24")
    AssertDoesNotThrow(CapsRepeatGuard.Poll.Bind(CapsRepeatGuard), "Poll with F24 unheld")
    AssertTrue(!CapsRepeatGuard.ShouldBlock("$F24", "copy"), "Poll drops unheld key")
    AssertEqual(CapsRepeatGuard.pollFn, "", "Poll stops timer when blocked empty")

    CapsRepeatGuard.Arm("$c")
    CapsRepeatGuard.Arm("$c")
    AssertDoesNotThrow(CapsRepeatGuard.Poll.Bind(CapsRepeatGuard), "Poll with empty blocked map")
    CapsRepeatGuard.Reset()
}

; Regression: v2 SetTimer disable requires callback object, not return value / "".
RunV2TimerContractTests() {
    fn := ( *) => ""
    SetTimer(fn, 20)
    AssertType(fn, "Func", "literal timer callback is Func")
    timerRet := SetTimer(fn, 20)
    SetTimer(fn, 0)
    if (timerRet = "") {
        threw := false
        try
            SetTimer(timerRet, 0)
        catch
            threw := true
        AssertTrue(threw, "SetTimer('', 0) must throw (CapsRepeatGuard regression)")
    }
    bound := CapsRepeatGuard.Poll.Bind(CapsRepeatGuard)
    SetTimer(bound, 20)
    AssertDoesNotThrow(() => SetTimer(bound, 0), "SetTimer(BoundFunc, 0) must not throw")
}

RunCapsSendTests() {
    SendLevel(5)
    CapsSend("{F13}")
    AssertEqual(A_SendLevel, 5, "CapsSend restores SendLevel after Send")
    SendLevel(0)
}

; Every default binding must classify as repeat or single-shot consistently.
RunDefaultBindingsRepeatConsistencyTests() {
    singleShot := Map(
        "copy", 1, "paste", 1, "cut", 1, "reload", 1, "winPin", 1, "openDocs", 1,
        "none", 1, "enter", 1, "enterWherever", 1, "home", 1, "end", 1,
        "deleteLine", 1, "deleteToLineBeginning", 1, "deleteToLineEnd", 1,
        "selectCurrentWord", 1, "toggleCapsLock", 1
    )
    repeatOk := Map(
        "backspace", 1, "delete", 1, "moveLeft", 1, "moveRight", 1, "moveUp", 1,
        "moveDown", 1, "moveWordLeft", 1, "moveWordRight", 1,
        "selectUp", 1, "selectDown", 1, "selectLeft", 1, "selectRight", 1,
        "selectHome", 1, "selectEnd", 1, "selectWordLeft", 1, "selectWordRight", 1
    )
    for key, spec in GetDefaultKeyBindings() {
        if (key = "press_caps")
            continue
        allows := KeyActionAllowsRepeat(spec)
        if RegExMatch(spec, "^winbind_")
            AssertTrue(!allows, "default " key " winbind is single-shot")
        else if singleShot.Has(spec)
            AssertTrue(!allows, "default " key " " spec " is single-shot")
        else if repeatOk.Has(spec) || RegExMatch(spec, "^(move|select)")
            AssertTrue(allows, "default " key " " spec " allows repeat")
        else if RegExMatch(spec, "^\w+\(\d+\)$")
            AssertTrue(allows, "default " key " parameterized move/select allows repeat")
    }
}

summary := "CapsLockX tests: " g_passed " passed, " g_failed " failed"
OutputLine(summary)
if !quiet
    MsgBox(summary, "CapsLockX Tests", g_failed ? "Icon!" : "Iconi")
else
    FileAppend(summary "`n", A_ScriptDir "\test-results.log", "UTF-8")

ExitApp(g_failed ? 1 : 0)
