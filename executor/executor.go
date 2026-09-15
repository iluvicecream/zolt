package executor

import (
	"os"

	executor "github.com/iluvicecream/zolt/executor/env"
	lua "github.com/yuin/gopher-lua"
	"go.uber.org/zap"
)

type Executor struct {
	log *zap.Logger
}

func Execute(path string, log *zap.Logger) string {
	scriptContent, _ := os.ReadFile(path)

	LuaState := lua.NewState()
	defer LuaState.Close()

	executor.RegisterZapPrint(LuaState, log)

	err := LuaState.DoFile(path)
	if err != nil {
		log.Error("error occured during function execution", zap.String("scriptPath", path), zap.Error(err))
		return "error during script execution"
	}

	return string(scriptContent)
}
