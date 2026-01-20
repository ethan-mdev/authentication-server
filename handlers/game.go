package handlers

import (
	"database/sql"
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
	addItemSQL         = queries.Load("game/add_item_to_account.sql")
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

	// DOCKER-DEMO BRANCH: Always return mock characters
	mockChars := []Character{
		{CharNo: 1, Name: "DemoWarrior", Level: 65, Playtime: 1200, Money: 5000000, ClassID: 1},
		{CharNo: 2, Name: "DemoMage", Level: 45, Playtime: 800, Money: 2500000, ClassID: 2},
		{CharNo: 3, Name: "DemoCleric", Level: 50, Playtime: 950, Money: 3200000, ClassID: 3},
	}
	slog.Debug("returning mock characters", "user_id", claims.UserID, "count", len(mockChars))
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(mockChars)
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

	// DOCKER-DEMO BRANCH: Always return success
	slog.Info("mock unstuck character", "user_id", claims.UserID, "character", req.CharacterName)
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]string{
		"message": req.CharacterName + " has been moved to town.",
	})
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

	// DOCKER-DEMO BRANCH: Skip actual item delivery to game account
	slog.Info("mock item delivery", "user_id", claims.UserID, "item_id", req.ItemID, "contents", len(contents))

	// Purchase item (deduct balance and record purchase - this still happens)
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

type RedeemVoucherRequest struct {
	Code string `json:"code"`
}

func (h *GameHandler) RedeemVoucher(w http.ResponseWriter, r *http.Request) {
	claims, ok := middleware.GetClaims(r.Context())
	if !ok {
		http.Error(w, "Unauthorized", http.StatusUnauthorized)
		return
	}

	var req RedeemVoucherRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, "Invalid request body", http.StatusBadRequest)
		return
	}

	if req.Code == "" {
		http.Error(w, "Voucher code required", http.StatusBadRequest)
		return
	}

	// Verify game account linked
	creds, err := h.userRepo.GetGameCredentials(claims.UserID)
	if err != nil || creds == nil {
		slog.Error("failed to fetch credentials", "error", err, "user_id", claims.UserID)
		http.Error(w, "No game account linked", http.StatusForbidden)
		return
	}

	// Get voucher details
	voucher, err := h.userRepo.GetVoucherByCode(req.Code)
	if err == sql.ErrNoRows {
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusNotFound)
		json.NewEncoder(w).Encode(map[string]string{
			"error": "Invalid voucher code",
		})
		return
	}
	if err != nil {
		slog.Error("failed to get voucher", "error", err, "code", req.Code)
		http.Error(w, "Failed to get voucher details", http.StatusInternalServerError)
		return
	}

	voucherID := voucher["id"].(int)

	// Check if already redeemed
	redeemed, err := h.userRepo.IsVoucherRedeemed(claims.UserID, voucherID)
	if err != nil {
		slog.Error("failed to check redemption status", "error", err)
		http.Error(w, "Failed to check voucher status", http.StatusInternalServerError)
		return
	}

	if redeemed {
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusConflict)
		json.NewEncoder(w).Encode(map[string]string{
			"error": "Voucher already redeemed",
		})
		return
	}

	// Check if voucher has reached max total redemptions
	if maxTotal := voucher["max_total_redemptions"]; maxTotal != nil {
		maxTotalRedemptions := maxTotal.(int)
		totalRedemptions, err := h.userRepo.GetTotalRedemptionCount(voucherID)
		if err != nil {
			slog.Error("failed to get total redemption count", "error", err)
			http.Error(w, "Failed to check voucher availability", http.StatusInternalServerError)
			return
		}

		if totalRedemptions >= maxTotalRedemptions {
			w.Header().Set("Content-Type", "application/json")
			w.WriteHeader(http.StatusGone)
			json.NewEncoder(w).Encode(map[string]string{
				"error": "Voucher has reached maximum redemptions",
			})
			return
		}
	}

	// Get voucher contents
	contents, err := h.userRepo.GetVoucherContents(voucherID)
	if err != nil {
		slog.Error("failed to get voucher contents", "error", err, "voucher_id", voucherID)
		http.Error(w, "Failed to get voucher contents", http.StatusInternalServerError)
		return
	}

	if len(contents) == 0 {
		http.Error(w, "Voucher has no contents configured", http.StatusInternalServerError)
		return
	}

	// DOCKER-DEMO BRANCH: Skip actual item delivery to game account
	slog.Info("mock voucher delivery", "user_id", claims.UserID, "voucher_id", voucherID, "contents", len(contents))

	// Mark voucher as redeemed (this still happens)
	err = h.userRepo.MarkVoucherRedeemed(claims.UserID, voucherID)
	if err != nil {
		slog.Error("failed to mark voucher as redeemed", "error", err, "user_id", claims.UserID, "voucher_id", voucherID)
		http.Error(w, "Failed to complete redemption", http.StatusInternalServerError)
		return
	}

	slog.Info("voucher redeemed", "user_id", claims.UserID, "voucher_code", req.Code, "voucher_id", voucherID)

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"success": true,
		"message": "Voucher redeemed successfully! Items have been added to your account.",
	})
}
