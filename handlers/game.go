package handlers

import (
	"crypto/md5"
	"crypto/rand"
	"database/sql"
	"encoding/hex"
	"encoding/json"
	"log/slog"
	"net/http"

	"github.com/ethan-mdev/authentication-server/queries"
	"github.com/ethan-mdev/authentication-server/storage"
	"github.com/ethan-mdev/central-auth/middleware"
)

var (
	createAccountSQL   = queries.Load("game/create_account.sql")
	getCharactersSQL   = queries.Load("game/get_characters.sql")
	unstuckSQL         = queries.Load("game/unstuck.sql")
	verifyCharacterSQL = queries.Load("game/verify_character.sql")
	purchaseItemSQL    = queries.Load("game/purchase_item.sql")
)

type GameHandler struct {
	userRepo    *storage.ExtendedUserRepository
	accountDB   *sql.DB
	characterDB *sql.DB
}

type Character struct {
	CharNo   int    `json:"charNo"`
	Name     string `json:"name"`
	Level    int    `json:"level"`
	Playtime int    `json:"playtime"`
	Money    int64  `json:"money"`
	ClassID  int    `json:"classId"`
}

type UnstuckRequest struct {
	CharacterName string `json:"character_name"`
}

type PurchaseItemRequest struct {
	ItemID int `json:"item_id"`
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
		slog.Error("failed to fetch credentials", "error", err, "user_id", claims.UserID)
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

	rows, err := h.characterDB.Query(getCharactersSQL, creds.GameAccountID)
	if err != nil {
		slog.Error("failed to query characters", "error", err, "game_account_id", creds.GameAccountID)
		http.Error(w, "Failed to fetch characters", http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	characters := []Character{}
	for rows.Next() {
		var c Character
		if err := rows.Scan(&c.CharNo, &c.Name, &c.Level, &c.Playtime, &c.Money, &c.ClassID); err != nil {
			slog.Error("failed to scan character", "error", err)
			continue
		}
		characters = append(characters, c)
	}

	if err := rows.Err(); err != nil {
		slog.Error("error iterating characters", "error", err)
		http.Error(w, "Failed to fetch characters", http.StatusInternalServerError)
		return
	}

	slog.Debug("fetched characters", "user_id", claims.UserID, "count", len(characters))

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(characters)
}

func (h *GameHandler) UnstuckCharacter(w http.ResponseWriter, r *http.Request) {
	claims, ok := middleware.GetClaims(r.Context())
	if !ok {
		http.Error(w, "Unauthorized", http.StatusUnauthorized)
		return
	}

	var req UnstuckRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, "Invalid request body", http.StatusBadRequest)
		return
	}

	if req.CharacterName == "" {
		http.Error(w, "Character name required", http.StatusBadRequest)
		return
	}

	// Get user's game account ID
	creds, err := h.userRepo.GetGameCredentials(claims.UserID)
	if err != nil || creds == nil {
		slog.Error("failed to fetch credentials", "error", err, "user_id", claims.UserID)
		http.Error(w, "No game account linked", http.StatusForbidden)
		return
	}

	// Verify character belongs to user
	var charNo int
	err = h.characterDB.QueryRow(verifyCharacterSQL, req.CharacterName, creds.GameAccountID).Scan(&charNo)
	if err == sql.ErrNoRows {
		http.Error(w, "Character not found", http.StatusNotFound)
		return
	}
	if err != nil {
		slog.Error("failed to verify character", "error", err)
		http.Error(w, "Failed to verify character", http.StatusInternalServerError)
		return
	}

	// Move character to safe location
	_, err = h.characterDB.Exec(unstuckSQL, charNo)
	if err != nil {
		slog.Error("failed to unstuck character", "error", err, "char_no", charNo)
		http.Error(w, "Unstuck operation failed", http.StatusInternalServerError)
		return
	}

	slog.Info("character unstuck", "user_id", claims.UserID, "character", req.CharacterName)

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]string{
		"message": req.CharacterName + " has been moved to town.",
	})
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

func (h *GameHandler) PurchaseItem(w http.ResponseWriter, r *http.Request) {
	claims, ok := middleware.GetClaims(r.Context())
	if !ok {
		http.Error(w, "Unauthorized", http.StatusUnauthorized)
		return
	}

	var req PurchaseItemRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, "Invalid request body", http.StatusBadRequest)
		return
	}

	if req.ItemID <= 0 {
		http.Error(w, "Invalid item ID", http.StatusBadRequest)
		return
	}

	// Verify game account linked
	creds, err := h.userRepo.GetGameCredentials(claims.UserID)
	if err != nil || creds == nil {
		slog.Error("failed to fetch credentials", "error", err, "user_id", claims.UserID)
		http.Error(w, "No game account linked", http.StatusForbidden)
		return
	}

	// Get item details
	item, err := h.userRepo.GetItemByID(req.ItemID)
	if err == sql.ErrNoRows {
		http.Error(w, "Item not found", http.StatusNotFound)
		return
	}
	if err != nil {
		slog.Error("failed to get item", "error", err, "item_id", req.ItemID)
		http.Error(w, "Failed to get item details", http.StatusInternalServerError)
		return
	}

	// Get item contents (what goods to send to game)
	contents, err := h.userRepo.GetItemContents(req.ItemID)
	if err != nil {
		slog.Error("failed to get item contents", "error", err, "item_id", req.ItemID)
		http.Error(w, "Failed to get item contents", http.StatusInternalServerError)
		return
	}

	if len(contents) == 0 {
		http.Error(w, "Item has no contents configured", http.StatusInternalServerError)
		return
	}

	// Add all goods to game account
	for _, content := range contents {
		goodsNo := content["game_goods_no"]
		quantity := content["quantity"]

		var result int
		err = h.accountDB.QueryRow(purchaseItemSQL, creds.GameAccountID, 0, goodsNo, quantity).Scan(&result)
		if err != nil {
			slog.Error("failed to add item to game account", "error", err, "user_id", claims.UserID, "goods_no", goodsNo)
			http.Error(w, "Failed to add item to game account", http.StatusInternalServerError)
			return
		}

		if result != 1 {
			slog.Error("stored procedure failed", "result", result, "goods_no", goodsNo)
			http.Error(w, "Failed to add item to game account", http.StatusInternalServerError)
			return
		}
	}

	// Purchase item (deduct balance and record purchase)
	newBalance, err := h.userRepo.PurchaseItem(claims.UserID, req.ItemID, 1)
	if err == sql.ErrNoRows {
		http.Error(w, "Insufficient balance", http.StatusPaymentRequired)
		return
	}
	if err != nil {
		slog.Error("failed to complete purchase", "error", err, "user_id", claims.UserID)
		http.Error(w, "Failed to complete purchase", http.StatusInternalServerError)
		return
	}

	slog.Info("item purchased", "user_id", claims.UserID, "item_id", req.ItemID, "item_name", item["name"], "new_balance", newBalance)

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"success":     true,
		"message":     "Item purchased successfully",
		"new_balance": newBalance,
	})
}
