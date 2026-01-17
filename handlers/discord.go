package handlers

import (
	"bytes"
	"crypto/md5"
	"crypto/rand"
	"database/sql"
	"encoding/hex"
	"encoding/json"
	"log/slog"
	"net/http"
	"time"

	"github.com/ethan-mdev/authentication-server/storage"
	"github.com/ethan-mdev/central-auth/middleware"
)

type DiscordHandler struct {
	userRepo        *storage.ExtendedUserRepository
	accountDB       *sql.DB
	botSharedSecret string
	botWebhookURL   string
}

func NewDiscordHandler(userRepo *storage.ExtendedUserRepository, accountDB *sql.DB, botSharedSecret, botWebhookURL string) *DiscordHandler {
	return &DiscordHandler{
		userRepo:        userRepo,
		accountDB:       accountDB,
		botSharedSecret: botSharedSecret,
		botWebhookURL:   botWebhookURL,
	}
}

type CreateVerificationRequest struct {
	Token            string `json:"token"`
	DiscordID        string `json:"discord_id"`
	DiscordUsername  string `json:"discord_username"`
	ExpiresInMinutes int    `json:"expires_in_minutes"`
}

// CreateVerificationToken - called by Discord bot to create verification tokens
func (h *DiscordHandler) CreateVerificationToken(w http.ResponseWriter, r *http.Request) {
	// Verify request is from bot
	botSecret := r.Header.Get("X-Bot-Secret")
	if botSecret != h.botSharedSecret {
		http.Error(w, "Unauthorized", http.StatusUnauthorized)
		return
	}

	var req CreateVerificationRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, "Invalid request body", http.StatusBadRequest)
		return
	}

	if req.Token == "" || req.DiscordID == "" || req.DiscordUsername == "" {
		http.Error(w, "Missing required fields", http.StatusBadRequest)
		return
	}

	if req.ExpiresInMinutes <= 0 {
		req.ExpiresInMinutes = 15 // Default to 15 minutes
	}

	expiresAt := time.Now().Add(time.Duration(req.ExpiresInMinutes) * time.Minute)

	err := h.userRepo.CreateDiscordVerification(req.Token, req.DiscordID, req.DiscordUsername, expiresAt)
	if err != nil {
		slog.Error("Failed to create discord verification token", "error", err)
		http.Error(w, "Internal server error", http.StatusInternalServerError)
		return
	}

	slog.Info("verification token created", "discord_id", req.DiscordID, "expires_at", expiresAt)

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]bool{"success": true})
}

func (h *DiscordHandler) CompleteDiscordVerification(w http.ResponseWriter, r *http.Request) {
	token := r.URL.Query().Get("token")
	if token == "" {
		http.Error(w, "Missing token", http.StatusBadRequest)
		return
	}

	claims, ok := middleware.GetClaims(r.Context())
	if !ok {
		http.Error(w, "Unauthorized", http.StatusUnauthorized)
		return
	}

	verification, err := h.userRepo.GetDiscordVerification(token)
	if err != nil {
		if err == sql.ErrNoRows {
			http.Error(w, "Invalid token", http.StatusBadRequest)
			return
		}
		slog.Error("Failed to query discord verification", "error", err)
		http.Error(w, "Internal server error", http.StatusInternalServerError)
		return
	}

	if verification.Used {
		http.Error(w, "Token already used", http.StatusBadRequest)
		return
	}

	expiresAt, err := time.Parse(time.RFC3339, verification.ExpiresAt)
	if err != nil {
		// Try alternate format for PostgreSQL timestamp
		expiresAt, err = time.Parse("2006-01-02 15:04:05.999999-07", verification.ExpiresAt)
		if err != nil {
			slog.Error("Failed to parse expiry time", "error", err, "value", verification.ExpiresAt)
			http.Error(w, "Internal server error", http.StatusInternalServerError)
			return
		}
	}

	if time.Now().After(expiresAt) {
		http.Error(w, "Token expired", http.StatusBadRequest)
		return
	}

	linked, err := h.userRepo.IsGameLinked(claims.UserID)
	if err != nil {
		http.Error(w, "Internal server error", http.StatusInternalServerError)
		return
	}
	if linked {
		http.Error(w, "Game account already linked", http.StatusBadRequest)
		return
	}

	username := verification.DiscordUsername

	// Generate API key
	apiKey, err := generateApiKey(16)
	if err != nil {
		http.Error(w, "Failed to generate API key", http.StatusInternalServerError)
		return
	}

	md5Hash := md5Hash(apiKey)

	// Create game account
	var gameAccountID int
	err = h.accountDB.QueryRow(createAccountSQL, username, md5Hash).Scan(&gameAccountID)
	if err != nil {
		slog.Error("failed to create game account", "error", err)
		http.Error(w, "Failed to create game account: "+err.Error(), http.StatusInternalServerError)
		return
	}

	// Link everything in PostgreSQL (including Discord info)
	err = h.userRepo.LinkDiscordAndGameAccount(claims.UserID, gameAccountID, apiKey, verification.DiscordID, verification.DiscordUsername)
	if err != nil {
		slog.Error("failed to link accounts", "error", err)
		http.Error(w, "Failed to link accounts", http.StatusInternalServerError)
		return
	}

	// Mark token as used
	err = h.userRepo.MarkDiscordVerificationUsed(token, claims.UserID)
	if err != nil {
		slog.Error("failed to mark token as used", "error", err)
	}

	slog.Info("discord verification complete", "user_id", claims.UserID, "discord_id", verification.DiscordID, "game_account_id", gameAccountID)

	// Notify Discord bot (non-blocking)
	go h.notifyDiscordBot(verification.DiscordID, username, gameAccountID)

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"success":         true,
		"message":         "Game account created and Discord verified",
		"game_account_id": gameAccountID,
		"discord_linked":  true,
	})
}

func (h *DiscordHandler) notifyDiscordBot(discordID, username string, gameAccountID int) error {
	if h.botWebhookURL == "" {
		slog.Warn("bot webhook URL not configured, skipping notification")
		return nil
	}

	payload := map[string]interface{}{
		"discord_id":      discordID,
		"username":        username,
		"game_account_id": gameAccountID,
		"timestamp":       time.Now().Unix(),
	}

	jsonData, _ := json.Marshal(payload)

	req, err := http.NewRequest("POST", h.botWebhookURL, bytes.NewBuffer(jsonData))
	if err != nil {
		slog.Error("failed to create bot notification request", "error", err)
		return err
	}

	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("X-Bot-Secret", h.botSharedSecret)

	client := &http.Client{Timeout: 10 * time.Second}
	resp, err := client.Do(req)
	if err != nil {
		slog.Error("failed to send bot notification", "error", err)
		return err
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		slog.Error("bot notification failed", "status", resp.StatusCode)
		return nil
	}

	slog.Info("bot notified successfully", "discord_id", discordID)
	return nil
}

func md5Hash(text string) string {
	hash := md5.Sum([]byte(text))
	return hex.EncodeToString(hash[:])
}

func generateApiKey(length int) (string, error) {
	bytes := make([]byte, length/2)
	if _, err := rand.Read(bytes); err != nil {
		return "", err
	}
	return hex.EncodeToString(bytes), nil
}
