package server

import (
	"errors"
	"log/slog"
	"net/http"
	"os"
	"path/filepath"

	"github.com/iluvicecream/zolt/executor"
)

type ExecuteHandler struct {
	log *slog.Logger
}

func (*ExecuteHandler) Pattern() string {
	return "/{path...}"
}

func NewExecuteHandler(log *slog.Logger) *ExecuteHandler {
	return &ExecuteHandler{log: log}
}

func (handler *ExecuteHandler) ServeHTTP(writer http.ResponseWriter, req *http.Request) {
	executePath := req.PathValue("path")

	doesExecutePathEndWithLua := filepath.Ext(executePath) == ".lua"
	if !doesExecutePathEndWithLua {
		//TODO: Serve Static File
		writer.WriteHeader(http.StatusNotFound)
		return
	}

	doesExecuteScriptExist, err := scriptExistsInCWD(executePath)
	if doesExecuteScriptExist {
		rsp := executor.Execute(executePath, handler.log)
		writer.Header().Add("Content-Type", rsp.ContentType)
		writer.WriteHeader(rsp.StatusCode)
		_, _ = writer.Write(rsp.Body.Bytes())
	} else {
		writer.WriteHeader(http.StatusInternalServerError)
		_, _ = writer.Write([]byte("script not found"))
		handler.log.Error("script not found", "path", executePath, "err", err)
	}
}

func scriptExistsInCWD(filename string) (bool, error) {
	cwd, err := os.Getwd()
	if err != nil {
		return false, err
	}

	targetPath := filepath.Join(cwd, filename)

	_, err = os.Stat(targetPath)
	if err == nil {
		return true, nil
	}
	if errors.Is(err, os.ErrNotExist) {
		return false, nil
	}
	return false, err
}
