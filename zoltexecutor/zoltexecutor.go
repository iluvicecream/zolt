package zoltexecutor

import (
	"bytes"
	"html/template"
	"log/slog"
	"net/http"

	"github.com/iluvicecream/zolt/protocol"
	"github.com/iluvicecream/zolt/runtime"
	lua "github.com/yuin/gopher-lua"
)

func Execute(req *http.Request, path string, log *slog.Logger) protocol.HttpResponse {
	LuaState := lua.NewState()
	defer LuaState.Close()

	LuaState.OpenLibs()

	rsp := protocol.HttpResponse{}
	rsp.StatusCode = 200

	runtime.RegisterZapPrint(LuaState, log)
	runtime.RegisterHttpStatus(LuaState, &rsp.StatusCode)
	runtime.RegisterHttpContentType(LuaState, &rsp.ContentType)
	runtime.RegisterHttpHeaderAdd(LuaState, &rsp.Headers)
	runtime.RegisterHttpRequestTable(LuaState, req)

	funcMap := template.FuncMap{
		"lua": func(code string) (template.HTML, error) {
			var buf bytes.Buffer
			LuaState.SetGlobal("echo", LuaState.NewFunction(func(L *lua.LState) int {
				for i := 1; i <= L.GetTop(); i++ {
					buf.WriteString(L.Get(i).String())
				}
				return 0
			}))
			if err := LuaState.DoString(code); err != nil {
				return "", err
			}
			return template.HTML(buf.String()), nil
		},
	}

	scriptTempl, err := template.New(path).Funcs(funcMap).ParseFiles(path)
	if err != nil {
		rsp.StatusCode = http.StatusInternalServerError
		rsp.Body.Write([]byte(err.Error()))
		return rsp
	}

	err = scriptTempl.Execute(&rsp.Body, nil)
	if err != nil {
		rsp.StatusCode = http.StatusInternalServerError
		rsp.Body.Write([]byte(err.Error()))
		return rsp
	}
	return rsp
}
