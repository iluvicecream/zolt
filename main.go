package main

import (
	"fmt"
	"net/http"

	"time"

	"github.com/iluvicecream/zolt/configSchema"
	"github.com/iluvicecream/zolt/server"
	"go.uber.org/config"
	"go.uber.org/zap"
)

func main() {
	logger, _ := zap.NewProduction()
	defer logger.Sync()
	sugar := logger.Sugar()

	// Load Cfg From config.yaml in current working dir
	provider, err := config.NewYAML(config.File(fmt.Sprintf("%s/config.yaml", "./")))
	if err != nil {
		sugar.Fatalf("Error loading config: %v", err)
	}

	var cfg configSchema.ConfigSchema
	provider.Get("server").Populate(&cfg)

	srv := server.New()

	httpServer := &http.Server{
		Addr:         fmt.Sprintf(":%d", cfg.Port),
		Handler:      srv,
		ReadTimeout:  10 * time.Second,
		WriteTimeout: 10 * time.Second,
	}

	sugar.Infof("Listening on :%d", cfg.Port)
	if err := httpServer.ListenAndServe(); err != nil && err != http.ErrServerClosed {
		sugar.Fatalf("Server failed to listen: %v", err)
	}
}
