package executor

import (
	"log/slog"

	"github.com/iluvicecream/zolt/protocol"
	"github.com/iluvicecream/zolt/runtime"
	lua "github.com/yuin/gopher-lua"
)

type Executor struct {
	log *slog.Logger
}

func Execute(path string, log *slog.Logger) protocol.HttpResponse {
	LuaState := lua.NewState()
	defer LuaState.Close()

	LuaState.OpenLibs()

	rsp := protocol.HttpResponse{}
	rsp.StatusCode = 200

	runtime.RegisterZapPrint(LuaState, log)
	runtime.RegisterEcho(LuaState, &rsp.Body)
	runtime.RegisterHttpStatus(LuaState, &rsp.StatusCode)
	runtime.RegisterHttpContentType(LuaState, &rsp.ContentType)
	runtime.RegisterHttpHeaderAdd(LuaState, &rsp.Headers)

	err := LuaState.DoFile(path)
	if err != nil {
		rsp.StatusCode = 500
		rsp.Body.Reset()
		rsp.Body.WriteString(err.Error())
		log.Error("error occurred during function execution", "scriptPath", path, "err", err)
		return rsp
	}

	return rsp
}
