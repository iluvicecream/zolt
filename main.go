package main

import (
	"log/slog"
	"net/http"

	"github.com/iluvicecream/zolt/server"
	"go.uber.org/fx"
	"go.uber.org/fx/fxevent"
)

func main() {
	fx.New(
		fx.Provide(
			func() *slog.Logger {
				return slog.Default()
			},
			server.NewHTTPServer,
			fx.Annotate(
				server.NewServeMux,
				fx.ParamTags(`group:"routes"`),
			),
			server.AsRoute(server.NewExecuteHandler),
		),
		fx.WithLogger(func(logger *slog.Logger) fxevent.Logger {
			return &fxevent.SlogLogger{
				Logger: logger,
			}
		}),
		fx.Invoke(func(*http.Server) {}),
	).Run()
}
