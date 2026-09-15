package executor

import (
	"strings"

	lua "github.com/yuin/gopher-lua"
	"go.uber.org/zap"
)

func RegisterZapPrint(state *lua.LState, log *zap.Logger) {
	state.SetGlobal("print", state.NewFunction(func(state *lua.LState) int {
		caller := strings.TrimSuffix(strings.TrimSpace(state.Where(1)), ":")
		top := state.GetTop()
		parts := make([]string, 0, top)

		for i := 1; i <= top; i++ {
			parts = append(parts, state.Get(i).String())
		}

		message := strings.Join(parts, "\t")

		log.Info(message, zap.String("lua_src", caller), zap.String("source", "lua"))

		return 0
	}))
}
