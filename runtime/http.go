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

	// Header
	state.SetField(reqTable, "header", urlValuesToLuaTable(state, req.Header))
	state.SetField(reqTable, "ip", lua.LString(req.RemoteAddr))
	// Query Param
	state.SetField(reqTable, "query", urlValuesToLuaTable(state, req.URL.Query()))
	//Form
	req.ParseForm()
	state.SetField(reqTable, "form", urlValuesToLuaTable(state, req.PostForm))

	state.SetGlobal("http_request", reqTable)
}

func urlValuesToLuaTable(L *lua.LState, values map[string][]string) *lua.LTable {
	tbl := L.NewTable()

	for key, vals := range values {
		if len(vals) == 1 {
			L.SetField(tbl, key, lua.LString(vals[0]))
		} else if len(vals) > 1 {
			arrTable := L.NewTable()
			for _, v := range vals {
				arrTable.Append(lua.LString(v))
			}
			L.SetField(tbl, key, arrTable)
		}
	}

	return tbl
}
