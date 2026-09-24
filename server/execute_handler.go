package server

import (
	"errors"
	"log/slog"
	"maps"
	"net/http"
	"os"
	"path/filepath"
	"strings"

	"github.com/iluvicecream/zolt/executor"
	"github.com/iluvicecream/zolt/zoltexecutor"
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

	// static file serving
	if strings.HasPrefix(executePath, "public/") {
		http.ServeFile(writer, req, executePath)
		return
	}

	// if executePath is empty, execute index.lua
	if executePath == "" {
		// check if either index.lua or index.zolt exist
		doesIndexLuaExist, _ := scriptExistsInCWD("index.lua")
		doesIndexZoltExist, _ := scriptExistsInCWD("index.zolt")
		if doesIndexLuaExist {
			executePath = "index.lua"
			req.SetPathValue("path", "index.lua")
		} else if doesIndexZoltExist {
			executePath = "index.zolt"
			req.SetPathValue("path", "index.zolt")
		} else {
			writer.WriteHeader(http.StatusNotFound)
			return
		}
	}

	doesExecutePathEndWithLuaOrZolt := filepath.Ext(executePath) == ".lua" || filepath.Ext(executePath) == ".zolt"
	if !doesExecutePathEndWithLuaOrZolt {
		writer.WriteHeader(http.StatusNotFound)
		return
	}

	doesExecuteScriptExist, err := scriptExistsInCWD(executePath)
	if doesExecuteScriptExist {
		scriptExt := filepath.Ext(executePath)
		switch scriptExt {
		case ".zolt":
			rsp := zoltexecutor.Execute(req, executePath, handler.log)
			maps.Copy(writer.Header(), rsp.Headers)
			writer.Header().Add("Content-Type", rsp.ContentType)
			writer.WriteHeader(rsp.StatusCode)
			_, _ = writer.Write(rsp.Body.Bytes())
		case ".lua":
			rsp := executor.Execute(req, executePath, handler.log)
			maps.Copy(writer.Header(), rsp.Headers)
			writer.Header().Add("Content-Type", rsp.ContentType)
			writer.WriteHeader(rsp.StatusCode)
			_, _ = writer.Write(rsp.Body.Bytes())
		}
	} else {
		writer.WriteHeader(http.StatusNotFound)
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
	relativePath, err := filepath.Rel(cwd, targetPath)
	if err != nil {
		return false, err
	}
	if relativePath == ".." || strings.HasPrefix(relativePath, ".."+string(filepath.Separator)) {
		return false, nil
	}

	_, err = os.Stat(targetPath)
	if err == nil {
		return true, nil
	}
	if errors.Is(err, os.ErrNotExist) {
		return false, nil
	}
	return false, err
}
