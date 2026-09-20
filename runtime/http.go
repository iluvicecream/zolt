package runtime

import (
	"net/http"

	"github.com/iluvicecream/zolt/protocol"
	lua "github.com/yuin/gopher-lua"
)

func RegisterHttpStatus(state *lua.LState, status *int) {
	state.SetGlobal("http_set_status", state.NewFunction(func(state *lua.LState) int {
		top := state.GetTop()
		*status = state.ToInt(top)
		return 0
	}))
}

func RegisterHttpContentType(state *lua.LState, contentType *string) {
	state.SetGlobal("http_content_type", state.NewFunction(func(state *lua.LState) int {
		top := state.GetTop()
		*contentType = state.ToString(top)
		return 0
	}))
}

func RegisterHttpHeaderAdd(state *lua.LState, header *[]protocol.HttpHeader) {
	state.SetGlobal("http_header_add", state.NewFunction(func(state *lua.LState) int {
		top := state.GetTop()
		if top < 2 {
			state.ArgError(1, "expected at least 2 arguments")
		}
		key := state.ToString(1)
		value := state.ToString(2)
		*header = append(*header, protocol.HttpHeader{Key: key, Value: value})
		return 0
	}))
}

func RegisterHttpRequestTable(state *lua.LState, req *http.Request) {
	reqTable := state.NewTable()
	state.SetField(reqTable, "path", lua.LString(req.PathValue("path")))
	state.SetGlobal("http_request", reqTable)
}
