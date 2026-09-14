package server

import (
	"fmt"

	"github.com/iluvicecream/zolt/vm/lua"
)

type LuaExecutor struct {
	body []byte
}

func ExecutePath(path string, state *lua.State) *LuaExecutor {
	exec := &LuaExecutor{}
	state.Register("echo", func(ls *lua.State) int {
		msg := ls.GetString(1)
		exec.body = append(exec.body, []byte(msg)...)
		return 0
	})
	err := state.DoString(`echo("execpath")`)
	if err != nil {
		fmt.Printf("lua err %v", err)
	}
	return exec
}

func (exec *LuaExecutor) GetRetcode() int {
	return 200
}
