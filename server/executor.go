package server

import (
	"fmt"

	"github.com/iluvicecream/zolt/vm/lua"
)

type LuaExecutor struct {
}

func ExecutePath(path string, state *lua.State) *LuaExecutor {
	exec := &LuaExecutor{}
	err := state.DoString(`print("execpath")`)
	if err != nil {
		fmt.Printf("lua err %v", err)
	}
	return exec
}

func (exec *LuaExecutor) GetRetcode() int {
	return 200
}
