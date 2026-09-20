package runtime

import (
	"net/http"

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

func RegisterHttpHeaderAdd(state *lua.LState, header *http.Header) {
	state.SetGlobal("http_header_add", state.NewFunction(func(state *lua.LState) int {
		if *header == nil {
			*header = make(http.Header)
		}

		key := state.CheckString(1)
		top := state.GetTop()
		for i := 2; i <= top; i++ {
			val := state.CheckString(i)
			header.Add(key, val)
		}
		return 0
	}))
}

func RegisterHttpRequestTable(state *lua.LState, req *http.Request) {
	reqTable := state.NewTable()
	state.SetField(reqTable, "path", lua.LString(req.PathValue("path")))
	state.SetField(reqTable, "method", lua.LString(req.Method))

	headerTable := state.NewTable()
	for key, values := range req.Header {
		if len(values) == 1 {
			state.SetField(headerTable, key, lua.LString(values[0]))
		} else if len(values) > 1 {
			arr := state.NewTable()
			for _, v := range values {
				arr.Append(lua.LString(v))
			}
			state.SetField(headerTable, key, arr)
		}
	}
	state.SetField(reqTable, "header", headerTable)

	state.SetGlobal("http_request", reqTable)
}
