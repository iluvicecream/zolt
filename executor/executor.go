package executor

import (
	"bytes"

	executor "github.com/iluvicecream/zolt/executor/env"
	lua "github.com/yuin/gopher-lua"
	"go.uber.org/zap"
)

type Executor struct {
	log *zap.Logger
}

func Execute(path string, log *zap.Logger) []byte {
	LuaState := lua.NewState()
	defer LuaState.Close()

	executor.RegisterZapPrint(LuaState, log)

	var echoBuf bytes.Buffer
	executor.RegisterEcho(LuaState, &echoBuf)

	err := LuaState.DoFile(path)
	if err != nil {
		log.Error("error occured during function execution", zap.String("scriptPath", path), zap.Error(err))
		return []byte("error during script execution")
	}

	return echoBuf.Bytes()
}
