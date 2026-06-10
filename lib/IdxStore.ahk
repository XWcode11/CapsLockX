; Sparse 0-based index store (compatible with CapsLock+ winsInfosRecorder.ini)
class IdxStore {
    __New() => this.m := Map()

    Has(i) => this.m.Has(i)

    Get(i, default := "") => this.m.Has(i) ? this.m[i] : default

    Set(i, val) => this.m[i] := val

    MaxIndex() {
        mx := -1
        for k in this.m
            if (k > mx)
                mx := k
        return mx
    }

    IsEmpty() => this.m.Count = 0

    Remove(i) {
        if !this.m.Has(i)
            return ""
        val := this.m[i]
        mx := this.MaxIndex()
        Loop mx - i {
            j := mx - A_Index + 1
            if this.m.Has(j)
                this.m[j - 1] := this.m[j]
        }
        this.m.Delete(mx)
        return val
    }

    Insert(val) {
        idx := this.MaxIndex() + 1
        this.m[idx] := val
        return idx
    }

    InsertAt0(val) {
        mx := this.MaxIndex()
        if (mx < 0) {
            this.m[0] := val
            return
        }
        Loop mx + 1 {
            j := mx - A_Index + 1
            this.m[j + 1] := this.m[j]
        }
        this.m[0] := val
    }
}
