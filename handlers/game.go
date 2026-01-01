package handlers

import (
	"crypto/md5"
	"crypto/rand"
	"database/sql"
	"encoding/hex"
	"encoding/json"
	"net/http"

	"github.com/ethan-mdev/authentication-server/storage"
)

type GameHandler struct {
	userRepo    *storage.ExtendedUserRepository
	accountDB   *sql.DB // MySQL - accounts
	characterDB *sql.DB // MySQL - characters
}

func NewGameHandler(userRepo *storage.ExtendedUserRepository, accountDB, characterDB *sql.DB) *GameHandler {
	return &GameHandler{
		userRepo:    userRepo,
		accountDB:   accountDB,
		characterDB: characterDB,
	}
}

func (h *GameHandler) GetCredentials(w http.ResponseWriter, r *http.Request) {
	userID := r.Context().Value("user_id").(string)

	creds, err := h.userRepo.GetGameCredentials(userID)
	if err != nil {
		http.Error(w, "Failed to fetch credentials", http.StatusInternalServerError)
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
	userID := r.Context().Value("user_id").(string)

	creds, err := h.userRepo.GetGameCredentials(userID)
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
	// TODO: Query MySQL game database for characters
}

func (h *GameHandler) Verify(w http.ResponseWriter, r *http.Request) {
	userID := r.Context().Value("user_id").(string)

	// Check if already linked
	linked, err := h.userRepo.IsGameLinked(userID)
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

	// TODO: Validate verification token (email/Discord)
	// For now, we'll skip token validation

	// Get username for game account
	username, err := h.userRepo.GetUsernameByID(userID)
	if err != nil {
		http.Error(w, "Failed to get username", http.StatusInternalServerError)
		return
	}

	// Generate API key
	apiKey, err := generateApiKey(32)
	if err != nil {
		http.Error(w, "Failed to generate API key", http.StatusInternalServerError)
		return
	}

	// MD5 hash for game database
	md5Hash := md5Hash(apiKey)

	// Create account in database
	var gameAccountID int
	err = h.accountDB.QueryRow(`CALL create_account(?, ?)`, username, md5Hash).Scan(&gameAccountID)
	if err != nil {
		http.Error(w, "Failed to create game account", http.StatusInternalServerError)
		return
	}

	// Link in PostgreSQL
	err = h.userRepo.LinkGameAccount(userID, gameAccountID, apiKey)
	if err != nil {
		// TODO: Consider rolling back the MySQL account creation
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

// Game DB uses md5 hash as password, so we'll just hash our api key for the database
func md5Hash(text string) string {
	hash := md5.Sum([]byte(text))
	return hex.EncodeToString(hash[:])
}
