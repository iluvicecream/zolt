package executor

import (
	"bytes"

	lua "github.com/yuin/gopher-lua"
)

func RegisterEcho(state *lua.LState, buf *bytes.Buffer) {
	state.SetGlobal("echo", state.NewFunction(func(state *lua.LState) int {
		top := state.GetTop()
		for i := 1; i <= top; i++ {
			buf.WriteString(state.Get(i).String())
		}
		return 0
	}))
}
