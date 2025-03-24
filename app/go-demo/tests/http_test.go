// tests/http_test.go
package tests

import (
	"net/http"
	"testing"
)

func TestQueryAPI(t *testing.T) {
	resp, err := http.Get("http://localhost:8080/api/query")
	if err != nil {
		t.Fatal(err)
	}
	defer resp.Body.Close()

	// Check if the status code is as expected
	if resp.StatusCode != http.StatusOK {
		t.Errorf("Expected status code %d, but got %d", http.StatusOK, resp.StatusCode)
	}

	// You can add more assertions based on the expected response
}

func TestInsertAPI(t *testing.T) {
	// Similar to the query test
}
