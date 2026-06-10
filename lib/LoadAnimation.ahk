; Startup splash — minimal card UI with spinner and progress bar

class LoadAnimation {
    static SPINNER := ["◐", "◓", "◑", "◒"]

    static gui := ""
    static spinnerCtrl := ""
    static progressCtrl := ""
    static frameIndex := 1
    static progress := 0
    static progressDir := 1
    static tickTimer := ""
    static shownAt := 0

    static MinDisplayMs() {
        try {
            ms := Settings.GetGlobal("loadingAnimationMinMs", "700")
            return Max(400, Integer(ms))
        } catch {
            return 700
        }
    }

    static Show() {
        if this.gui
            return
        this.shownAt := A_TickCount
        this.frameIndex := 1
        this.progress := 12
        this.progressDir := 1

        g := Gui("-Caption +AlwaysOnTop -DPIScale")
        g.BackColor := "F8FAFC"
        g.MarginX := 32
        g.MarginY := 24
        g.SetFont("s14 bold c0F172A", "Segoe UI")
        g.AddText("w260 Center", "CapsLockX")
        g.SetFont("s22 c2563EB", "Segoe UI")
        this.spinnerCtrl := g.AddText("w260 h34 Center", this.SPINNER[1])
        g.SetFont("s9 c64748B", "Segoe UI")
        g.AddText("w260 Center", "正在启动…")
        this.progressCtrl := g.AddProgress("w260 h6 BackgroundE2E8F0 c2563EB Range0-100 Smooth", 12)
        g.Show("Center NoActivate")
        try WinSetTransparent(245, "ahk_id " g.Hwnd)
        Sleep(40)
        this.gui := g
        this.tickTimer := SetTimer(this.Tick.Bind(this), 80)
    }

    static Tick() {
        if !this.spinnerCtrl
            return
        this.frameIndex := Mod(this.frameIndex, this.SPINNER.Length) + 1
        this.spinnerCtrl.Text := this.SPINNER[this.frameIndex]

        this.progress += this.progressDir * 5
        if (this.progress >= 88)
            this.progressDir := -1
        else if (this.progress <= 12)
            this.progressDir := 1
        try this.progressCtrl.Value := this.progress
    }

    static Hide() {
        if !this.gui
            return
        remain := this.MinDisplayMs() - (A_TickCount - this.shownAt)
        if (remain > 0)
            Sleep(remain)
        if this.tickTimer {
            SetTimer(this.tickTimer, 0)
            this.tickTimer := ""
        }
        try this.gui.Destroy()
        this.gui := ""
        this.spinnerCtrl := ""
        this.progressCtrl := ""
    }
}
