package executor

import (
	"bytes"
	"fmt"
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

	var echoBuffer bytes.Buffer

	LuaState.SetGlobal("echo", LuaState.NewFunction(func(L *lua.LState) int {
		top := L.GetTop()
		for i := 1; i <= top; i++ {
			echoBuffer.WriteString(L.Get(i).String())
		}
		return 0
	}))

	funcMap := template.FuncMap{
		"lua": func(code string) (interface{}, error) {
			echoBuffer.Reset()

			err := LuaState.DoString("return " + code)
			if err != nil {
				err = LuaState.DoString(code)
				if err != nil {
					return nil, fmt.Errorf("lua error: %v", err)
				}
			}

			if echoBuffer.Len() > 0 {
				return template.HTML(echoBuffer.String()), nil
			}

			top := LuaState.GetTop()
			if top > 0 {
				retVal := LuaState.Get(top)
				LuaState.Pop(1)

				switch v := retVal.(type) {
				case lua.LBool:
					return bool(v), nil
				case lua.LString:
					return template.HTML(string(v)), nil
				case lua.LNumber:
					return fmt.Sprintf("%v", v), nil
				}
			}

			return template.HTML(""), nil
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
