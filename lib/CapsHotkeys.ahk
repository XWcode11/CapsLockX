; Caps layer — CapsLock+ #If CapsLock: static hotkeys only (never runtime Hotkey() loop).
; v2 extras: $ hook prefix, #InputLevel 1, CapsSend(SendLevel 0) against Send feedback.

#InputLevel 1

#HotIf capsLockHeld

$LAlt:: return ; CapsLock+ blocks LAlt while layer is active

$a:: CapsKeyHandler("caps_a", A_ThisHotkey)
$b:: CapsKeyHandler("caps_b", A_ThisHotkey)
$c:: CapsKeyHandler("caps_c", A_ThisHotkey)
$d:: CapsKeyHandler("caps_d", A_ThisHotkey)
$e:: CapsKeyHandler("caps_e", A_ThisHotkey)
$f:: CapsKeyHandler("caps_f", A_ThisHotkey)
$g:: CapsKeyHandler("caps_g", A_ThisHotkey)
$h:: CapsKeyHandler("caps_h", A_ThisHotkey)
$i:: CapsKeyHandler("caps_i", A_ThisHotkey)
$j:: CapsKeyHandler("caps_j", A_ThisHotkey)
$k:: CapsKeyHandler("caps_k", A_ThisHotkey)
$l:: CapsKeyHandler("caps_l", A_ThisHotkey)
$m:: CapsKeyHandler("caps_m", A_ThisHotkey)
$n:: CapsKeyHandler("caps_n", A_ThisHotkey)
$o:: CapsKeyHandler("caps_o", A_ThisHotkey)
$p:: CapsKeyHandler("caps_p", A_ThisHotkey)
$q:: CapsKeyHandler("caps_q", A_ThisHotkey)
$r:: CapsKeyHandler("caps_r", A_ThisHotkey)
$s:: CapsKeyHandler("caps_s", A_ThisHotkey)
$t:: CapsKeyHandler("caps_t", A_ThisHotkey)
$u:: CapsKeyHandler("caps_u", A_ThisHotkey)
$v:: CapsKeyHandler("caps_v", A_ThisHotkey)
$w:: CapsKeyHandler("caps_w", A_ThisHotkey)
$x:: CapsKeyHandler("caps_x", A_ThisHotkey)
$y:: CapsKeyHandler("caps_y", A_ThisHotkey)
$z:: CapsKeyHandler("caps_z", A_ThisHotkey)

$1:: CapsKeyHandler("caps_1", A_ThisHotkey)
$2:: CapsKeyHandler("caps_2", A_ThisHotkey)
$3:: CapsKeyHandler("caps_3", A_ThisHotkey)
$4:: CapsKeyHandler("caps_4", A_ThisHotkey)
$5:: CapsKeyHandler("caps_5", A_ThisHotkey)
$6:: CapsKeyHandler("caps_6", A_ThisHotkey)
$7:: CapsKeyHandler("caps_7", A_ThisHotkey)
$8:: CapsKeyHandler("caps_8", A_ThisHotkey)
$9:: CapsKeyHandler("caps_9", A_ThisHotkey)
$0:: CapsKeyHandler("caps_0", A_ThisHotkey)

$f1:: CapsKeyHandler("caps_f1", A_ThisHotkey)
$f2:: CapsKeyHandler("caps_f2", A_ThisHotkey)
$f3:: CapsKeyHandler("caps_f3", A_ThisHotkey)
$f4:: CapsKeyHandler("caps_f4", A_ThisHotkey)
$f5:: CapsKeyHandler("caps_f5", A_ThisHotkey)
$f6:: CapsKeyHandler("caps_f6", A_ThisHotkey)
$f7:: CapsKeyHandler("caps_f7", A_ThisHotkey)
$f8:: CapsKeyHandler("caps_f8", A_ThisHotkey)
$f9:: CapsKeyHandler("caps_f9", A_ThisHotkey)
$f10:: CapsKeyHandler("caps_f10", A_ThisHotkey)
$f11:: CapsKeyHandler("caps_f11", A_ThisHotkey)
$f12:: CapsKeyHandler("caps_f12", A_ThisHotkey)

$`:: CapsKeyHandler("caps_backquote", A_ThisHotkey)
$-:: CapsKeyHandler("caps_minus", A_ThisHotkey)
$=:: CapsKeyHandler("caps_equal", A_ThisHotkey)
$[:: CapsKeyHandler("caps_leftSquareBracket", A_ThisHotkey)
$]:: CapsKeyHandler("caps_rightSquareBracket", A_ThisHotkey)
$\:: CapsKeyHandler("caps_backslash", A_ThisHotkey)
$;:: CapsKeyHandler("caps_semicolon", A_ThisHotkey)
$':: CapsKeyHandler("caps_quote", A_ThisHotkey)
$,:: CapsKeyHandler("caps_comma", A_ThisHotkey)
$.:: CapsKeyHandler("caps_dot", A_ThisHotkey)
$/:: CapsKeyHandler("caps_slash", A_ThisHotkey)

$Space:: CapsKeyHandler("caps_space", A_ThisHotkey)
$Tab:: CapsKeyHandler("caps_tab", A_ThisHotkey)
$Enter:: CapsKeyHandler("caps_enter", A_ThisHotkey)
$Backspace:: CapsKeyHandler("caps_backspace", A_ThisHotkey)
$RAlt:: CapsKeyHandler("caps_ralt", A_ThisHotkey)

$#1:: WinBindHandler(1, A_ThisHotkey)
$#2:: WinBindHandler(2, A_ThisHotkey)
$#3:: WinBindHandler(3, A_ThisHotkey)
$#4:: WinBindHandler(4, A_ThisHotkey)
$#5:: WinBindHandler(5, A_ThisHotkey)
$#6:: WinBindHandler(6, A_ThisHotkey)
$#7:: WinBindHandler(7, A_ThisHotkey)
$#8:: WinBindHandler(8, A_ThisHotkey)
$#9:: WinBindHandler(9, A_ThisHotkey)
$#0:: WinBindHandler(0, A_ThisHotkey)

#HotIf

#InputLevel 0
