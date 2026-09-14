package server

import (
	"net/http"
	"runtime"
	"sync"

	"github.com/iluvicecream/zolt/vm/lua"
)

type LuaPool struct {
	pool sync.Pool
}

func NewLuaPool() *LuaPool {
	return &LuaPool{
		pool: sync.Pool{
			New: func() interface{} {
				return lua.New()
			},
		},
	}
}

type CommandFunc func(req *http.Request, state *lua.State) ([]byte, error)

type Server struct {
	mux      *http.ServeMux
	luaPool  *LuaPool
	commands map[string]CommandFunc
}

func New() *Server {
	server := &Server{
		mux:      http.NewServeMux(),
		luaPool:  NewLuaPool(),
		commands: map[string]CommandFunc{},
	}

	server.mux.HandleFunc("/{path...}", server.handleRoutes)
	return server
}

func (server *Server) handleRoutes(writer http.ResponseWriter, req *http.Request) {
	reqPath := req.PathValue("path")

	runtime.LockOSThread()
	defer runtime.UnlockOSThread()

	state := server.luaPool.pool.Get().(*lua.State)
	defer server.luaPool.pool.Put(state)

	exec_ret := ExecutePath(reqPath, state)
	writer.WriteHeader(exec_ret.GetRetcode())
	writer.Write([]byte("test"))
}

func (server *Server) ServeHTTP(writer http.ResponseWriter, req *http.Request) {
	server.mux.ServeHTTP(writer, req)
}
