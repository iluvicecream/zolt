package executor

import (
	"log/slog"
	"strings"

	lua "github.com/yuin/gopher-lua"
)

func RegisterZapPrint(state *lua.LState, log *slog.Logger) {
	state.SetGlobal("print", state.NewFunction(func(state *lua.LState) int {
		caller := strings.TrimSuffix(strings.TrimSpace(state.Where(1)), ":")
		top := state.GetTop()
		parts := make([]string, 0, top)

		for i := 1; i <= top; i++ {
			parts = append(parts, state.Get(i).String())
		}

		message := strings.Join(parts, "\t")

		log.Info(message, "lua_src", caller)

		return 0
	}))
}
