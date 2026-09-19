package executor

import (
	"embed"
	"fmt"
	"log/slog"
	"strings"

	"github.com/iluvicecream/zolt/protocol"
	"github.com/iluvicecream/zolt/runtime"
	lua "github.com/yuin/gopher-lua"
)

//go:embed syslib/*.lua
var embeddedFS embed.FS

func SysLibLoader(L *lua.LState) int {
	modName := L.CheckString(1)
	if !strings.HasPrefix(modName, "@") {
		L.Push(lua.LString("\n\t[syslib loader]: skipped non-@ package"))
		return 1
	}
	cleanPath := strings.TrimPrefix(modName, "@")
	cleanPath = strings.ReplaceAll(cleanPath, ".", "/")
	filePath := "syslib/" + cleanPath + ".lua"

	content, err := embeddedFS.ReadFile(filePath)
	if err != nil {
		L.Push(lua.LString(fmt.Sprintf("\n\t[syslib loader]: file %s not found", filePath)))
		return 1
	}
	fn, err := L.LoadString(string(content))
	if err != nil {
		L.RaiseError("error loading module %s: %s", modName, err.Error())
		return 0
	}
	L.Push(fn)
	return 1
}

type Executor struct {
	log *slog.Logger
}

func Execute(path string, log *slog.Logger) protocol.HttpResponse {
	LuaState := lua.NewState()
	defer LuaState.Close()

	LuaState.OpenLibs()

	pkgTable := LuaState.GetGlobal("package").(*lua.LTable)
	loadersTable := LuaState.GetField(pkgTable, "loaders").(*lua.LTable)
	loadersTable.Insert(1, LuaState.NewFunction(SysLibLoader))

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
