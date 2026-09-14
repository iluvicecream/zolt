package main

import (
	"flag"
	"fmt"
	"log"
	"net/http"
	"time"

	"github.com/iluvicecream/zolt/server"
)

var (
	port = flag.Int("port", 8080, "Port for the HTTP server to listen on.")
)

func main() {
	flag.Parse()
	srv := server.New()

	httpServer := &http.Server{
		Addr:         fmt.Sprintf(":%d", *port),
		Handler:      srv,
		ReadTimeout:  10 * time.Second,
		WriteTimeout: 10 * time.Second,
	}

	log.Printf("Starting server on :%d...", *port)
	if err := httpServer.ListenAndServe(); err != nil && err != http.ErrServerClosed {
		log.Fatalf("Server failed: %v", err)
	}
}
