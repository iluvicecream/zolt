package server

import (
	"context"
	"log/slog"
	"net"
	"net/http"

	"go.uber.org/fx"
)

func NewHTTPServer(lc fx.Lifecycle, mux *http.ServeMux, log *slog.Logger) *http.Server {
	srv := &http.Server{Addr: ":8080", Handler: mux}
	lc.Append(fx.Hook{
		OnStart: func(ctx context.Context) error {
			ln, err := net.Listen("tcp", srv.Addr)
			if err != nil {
				return err
			}
			log.Info("http server started", "addr", srv.Addr)
			go func() {
				_ = srv.Serve(ln)
			}()
			return nil
		},
		OnStop: func(ctx context.Context) error {
			return srv.Shutdown(ctx)
		},
	})
	return srv
}

func NewServeMux(routes []Route) *http.ServeMux {
	mux := http.NewServeMux()
	for _, route := range routes {
		mux.Handle(route.Pattern(), route)
	}
	return mux
}
