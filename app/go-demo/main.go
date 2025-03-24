// main.go
package main

import (
	"fmt"
	"example_pkg/internal/api"
	"net/http"
)

func main() {
	fmt.Println("Starting Go Server...")

	// Register API handlers
	http.HandleFunc("/api/query", api.QueryHandler)
	http.HandleFunc("/api/insert", api.InsertHandler)

	// Start the server
	port := 8080
	address := fmt.Sprintf(":%d", port)
	fmt.Printf("Server is listening on port %d...\n", port)
	err := http.ListenAndServe(address, nil)
	if err != nil {
		fmt.Println("Error starting server:", err)
	}
}
