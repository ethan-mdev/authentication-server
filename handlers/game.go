package handlers

import (
	"crypto/md5"
	"crypto/rand"
	"database/sql"
	"encoding/hex"
	"encoding/json"
	"net/http"

	"github.com/ethan-mdev/authentication-server/queries"
	"github.com/ethan-mdev/authentication-server/storage"
	"github.com/ethan-mdev/central-auth/middleware"
)

var (
	createAccountSQL = queries.Load("game/create_account.sql")
)

type GameHandler struct {
	userRepo    *storage.ExtendedUserRepository
	accountDB   *sql.DB
	characterDB *sql.DB
}

func NewGameHandler(userRepo *storage.ExtendedUserRepository, accountDB, characterDB *sql.DB) *GameHandler {
	return &GameHandler{
		userRepo:    userRepo,
		accountDB:   accountDB,
		characterDB: characterDB,
	}
}

func (h *GameHandler) GetCredentials(w http.ResponseWriter, r *http.Request) {
	claims, ok := middleware.GetClaims(r.Context())
	if !ok {
		http.Error(w, "Unauthorized", http.StatusUnauthorized)
		return
	}

	creds, err := h.userRepo.GetGameCredentials(claims.UserID)
	if err != nil {
		http.Error(w, "Failed to fetch credentials", http.StatusInternalServerError)
		return
	}

	if creds == nil {
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusForbidden)
		json.NewEncoder(w).Encode(map[string]string{
			"error":   "account_not_linked",
			"message": "Please verify your account to create a game account",
		})
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"username":        creds.Username,
		"api_key":         creds.ApiKey,
		"game_account_id": creds.GameAccountID,
	})
}

func (h *GameHandler) GetCharacters(w http.ResponseWriter, r *http.Request) {
	claims, ok := middleware.GetClaims(r.Context())
	if !ok {
		http.Error(w, "Unauthorized", http.StatusUnauthorized)
		return
	}

	creds, err := h.userRepo.GetGameCredentials(claims.UserID)
	if err != nil {
		http.Error(w, "Failed to fetch credentials", http.StatusInternalServerError)
		return
	}

	if creds == nil {
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusForbidden)
		json.NewEncoder(w).Encode(map[string]string{
			"error":   "account_not_linked",
			"message": "No game account linked",
		})
		return
	}

	// TODO: Query SQL Server character database
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode([]interface{}{})
}

func (h *GameHandler) Verify(w http.ResponseWriter, r *http.Request) {
	claims, ok := middleware.GetClaims(r.Context())
	if !ok {
		http.Error(w, "Unauthorized", http.StatusUnauthorized)
		return
	}

	// Check if already linked
	linked, err := h.userRepo.IsGameLinked(claims.UserID)
	if err != nil {
		http.Error(w, "Failed to check link status", http.StatusInternalServerError)
		return
	}
	if linked {
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusBadRequest)
		json.NewEncoder(w).Encode(map[string]string{
			"error":   "already_linked",
			"message": "Game account already linked",
		})
		return
	}

	// Get username for game account
	username, err := h.userRepo.GetUsernameByID(claims.UserID)
	if err != nil {
		http.Error(w, "Failed to get username", http.StatusInternalServerError)
		return
	}

	// Generate API key
	apiKey, err := generateApiKey(16)
	if err != nil {
		http.Error(w, "Failed to generate API key", http.StatusInternalServerError)
		return
	}

	// MD5 hash for game database
	md5Hash := md5Hash(apiKey)

	// Create account in SQL Server
	var gameAccountID int
	err = h.accountDB.QueryRow(createAccountSQL, username, md5Hash).Scan(&gameAccountID)
	if err != nil {
		http.Error(w, "Failed to create game account: "+err.Error(), http.StatusInternalServerError)
		return
	}

	// Link in PostgreSQL
	err = h.userRepo.LinkGameAccount(claims.UserID, gameAccountID, apiKey)
	if err != nil {
		http.Error(w, "Failed to link game account", http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"success":         true,
		"message":         "Game account created",
		"game_account_id": gameAccountID,
	})
}

func generateApiKey(length int) (string, error) {
	bytes := make([]byte, length/2)
	if _, err := rand.Read(bytes); err != nil {
		return "", err
	}
	return hex.EncodeToString(bytes), nil
}

func md5Hash(text string) string {
	hash := md5.Sum([]byte(text))
	return hex.EncodeToString(hash[:])
}
