package executor

import (
	"bytes"

	executor "github.com/iluvicecream/zolt/executor/env"
	lua "github.com/yuin/gopher-lua"
	"go.uber.org/zap"
)

type Response struct {
	StatusCode  int
	ContentType string
	Body        bytes.Buffer
}

type Executor struct {
	log *zap.Logger
}

func Execute(path string, log *zap.Logger) Response {
	LuaState := lua.NewState()
	defer LuaState.Close()

	rsp := Response{}
	rsp.StatusCode = 200

	executor.RegisterZapPrint(LuaState, log)
	executor.RegisterEcho(LuaState, &rsp.Body)
	executor.RegisterHttpStatus(LuaState, &rsp.StatusCode)
	executor.RegisterHttpContentType(LuaState, &rsp.ContentType)

	err := LuaState.DoFile(path)
	if err != nil {
		rsp.StatusCode = 500
		rsp.Body.Reset()
		rsp.Body.WriteString(err.Error())
		log.Error("error occurred during function execution", zap.String("scriptPath", path), zap.Error(err))
		return rsp
	}

	return rsp
}
