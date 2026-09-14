package main

import (
	"fmt"
	"log"
	"net/http"

	"time"

	"github.com/iluvicecream/zolt/configSchema"
	"github.com/iluvicecream/zolt/server"
	"go.uber.org/config"
)

func main() {
	// Load Cfg From config.yaml in current working dir
	provider, err := config.NewYAML(config.File(fmt.Sprintf("%s/config.yaml", "./")))
	if err != nil {
		log.Fatalf("Failed to load config: %v", err)
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

	log.Printf("Starting server on :%d...", cfg.Port)
	if err := httpServer.ListenAndServe(); err != nil && err != http.ErrServerClosed {
		log.Fatalf("Server failed: %v", err)
	}
}
