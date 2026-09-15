package executor

import (
	lua "github.com/yuin/gopher-lua"
)

func RegisterHttpStatus(state *lua.LState, status *int) {
	state.SetGlobal("http_status", state.NewFunction(func(state *lua.LState) int {
		top := state.GetTop()
		*status = state.ToInt(top)
		return 0
	}))
}
