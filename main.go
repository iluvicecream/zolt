package main

import (
	"net/http"

	"github.com/iluvicecream/zolt/server"
	"go.uber.org/fx"
	"go.uber.org/fx/fxevent"
	"go.uber.org/zap"
)

func main() {
	fx.New(
		fx.WithLogger(func(log *zap.Logger) fxevent.Logger {
			return &fxevent.ZapLogger{Logger: log}
		}),
		fx.Provide(
			server.NewHTTPServer,
			fx.Annotate(
				server.NewServeMux,
				fx.ParamTags(`group:"routes"`),
			),
			server.AsRoute(server.NewExecuteHandler),
			zap.NewProduction,
		),
		fx.Invoke(func(*http.Server) {}),
	).Run()
}
