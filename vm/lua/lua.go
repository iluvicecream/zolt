package lua

/*
#cgo CFLAGS: -O2 -DLUA_USE_POSIX
#cgo LDFLAGS: -lm
#include <stdlib.h>
#include "lua.h"
#include "lualib.h"
#include "lauxlib.h"
extern int goCallbackGateway(void *L, int id);

static int c_gate(lua_State *L) {
    int id = (int)lua_tointeger(L, lua_upvalueindex(1));
    return goCallbackGateway((void*)L, id);
}

static void go_register_function(lua_State *L, const char *name, int id) {
    lua_pushinteger(L, id);
    lua_pushcclosure(L, c_gate, 1);
    lua_setglobal(L, name);
}

static void go_luaL_openlibs(lua_State *L) { luaL_openlibs(L); }
static int go_luaL_dostring(lua_State *L, const char *s) { return luaL_dostring(L, s); }
static void go_lua_pop(lua_State *L, int n) { lua_pop(L, n); }

*/
import "C"
import (
	"fmt"
	"sync"
	"unsafe"
)

type GoFunction func(s *State) int

var (
	registryMutex sync.RWMutex
	funcRegistry  = make(map[int]GoFunction)
	nextFuncID    = 1
)

//export goCallbackGateway
func goCallbackGateway(cState unsafe.Pointer, id C.int) C.int {
	registryMutex.RLock()
	fn, ok := funcRegistry[int(id)]
	registryMutex.RUnlock()

	if !ok {
		return 0
	}

	state := &State{LuaState: (*C.lua_State)(cState)}
	return C.int(fn(state))
}

type State struct {
	LuaState *C.lua_State
}

func New() *State {
	luaState := C.luaL_newstate()
	C.go_luaL_openlibs(luaState)
	return &State{LuaState: luaState}
}

func (state *State) Close() {
	if state.LuaState != nil {
		C.lua_close(state.LuaState)
		state.LuaState = nil
	}
}

func (state *State) DoString(script string) error {
	cScriptStr := C.CString(script)
	defer C.free(unsafe.Pointer(cScriptStr))

	if C.go_luaL_dostring(state.LuaState, cScriptStr) != 0 {
		errStr := C.GoString(C.lua_tolstring(state.LuaState, -1, nil))
		C.go_lua_pop(state.LuaState, 1)
		return fmt.Errorf("lua err: %s", errStr)
	}
	return nil
}

func (state *State) Register(name string, function GoFunction) {
	registryMutex.Lock()
	id := nextFuncID
	nextFuncID++
	funcRegistry[id] = function
	registryMutex.Unlock()

	cName := C.CString(name)
	defer C.free(unsafe.Pointer(cName))

	C.go_register_function(state.LuaState, cName, C.int(id))
}

func (state *State) GetString(index int) string {
	return C.GoString(C.lua_tolstring(state.LuaState, C.int(index), nil))
}

func (state *State) GetInteger(index int) int64 {
	return int64(C.lua_tointegerx(state.LuaState, C.int(index), nil))
}

func (state *State) PushString(val string) {
	cStr := C.CString(val)
	defer C.free(unsafe.Pointer(cStr))
	C.lua_pushstring(state.LuaState, cStr)
}

func (state *State) PushInteger(val int64) {
	C.lua_pushinteger(state.LuaState, C.lua_Integer(val))
}

func (state *State) PushBoolean(val bool) {
	b := C.int(0)
	if val {
		b = 1
	}
	C.lua_pushboolean(state.LuaState, b)
}
