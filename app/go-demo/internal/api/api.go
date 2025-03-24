// internal/api/api.go
package api

import (
	"encoding/json"
	"net/http"
	"example_pkg/internal/pkg"
)

type Response struct {
	Message string `json:"message"`
}

// QueryHandler handles GET requests to /api/query
func QueryHandler(w http.ResponseWriter, r *http.Request) {
	result := pkg.QueryFunction()
	response := Response{Message: result}

	respondWithJSON(w, http.StatusOK, response)
}

// InsertHandler handles POST requests to /api/insert
func InsertHandler(w http.ResponseWriter, r *http.Request) {
	result := pkg.InsertFunction()
	response := Response{Message: result}

	respondWithJSON(w, http.StatusOK, response)
}

func respondWithJSON(w http.ResponseWriter, statusCode int, data interface{}) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(statusCode)

	json.NewEncoder(w).Encode(data)
}
