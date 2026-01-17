package storage

import (
	"database/sql"

	"github.com/ethan-mdev/central-auth/storage"
)

// ExtendedUserRepository wraps the central-auth UserRepository
// and adds service-specific methods
type ExtendedUserRepository struct {
	storage.UserRepository
	db *sql.DB
}

func NewExtendedUserRepository(repo storage.UserRepository, db *sql.DB) *ExtendedUserRepository {
	return &ExtendedUserRepository{
		UserRepository: repo,
		db:             db,
	}
}

type GameCredentials struct {
	Username      string
	ApiKey        string
	GameAccountID int
}

// GetProfileByID fetches user profile used mainly on the forum for displaying user information, or profile pic for launcher etc.
func (r *ExtendedUserRepository) GetProfileByID(userID string) (map[string]interface{}, error) {
	var id, username, role string
	var profileImage sql.NullString
	var createdAt string

	err := r.db.QueryRow(`
		SELECT id, username, role, profile_image, created_at 
		FROM users 
		WHERE id = $1
	`, userID).Scan(&id, &username, &role, &profileImage, &createdAt)

	if err != nil {
		return nil, err
	}

	return map[string]interface{}{
		"user_id":       id,
		"username":      username,
		"role":          role,
		"profile_image": profileImage.String,
		"created_at":    createdAt,
	}, nil
}

// UpdateProfileImage updates just the profile_image field
func (r *ExtendedUserRepository) UpdateProfileImage(userID, profileImage string) error {
	_, err := r.db.Exec(
		"UPDATE users SET profile_image = $1, updated_at = CURRENT_TIMESTAMP WHERE id = $2",
		profileImage,
		userID,
	)
	return err
}

// Fetches the user's game credentials
func (r *ExtendedUserRepository) GetGameCredentials(userID string) (*GameCredentials, error) {
	var username string
	var gameAccountID sql.NullInt64
	var gameApiKey sql.NullString

	err := r.db.QueryRow(`
		SELECT username, game_account_id, game_api_key
		FROM users
		WHERE id = $1
	`, userID).Scan(&username, &gameAccountID, &gameApiKey)

	if err != nil {
		return nil, err
	}

	// game account not linked - return nil without an error
	if !gameAccountID.Valid || !gameApiKey.Valid {
		return nil, nil
	}

	return &GameCredentials{
		Username:      username,
		ApiKey:        gameApiKey.String,
		GameAccountID: int(gameAccountID.Int64),
	}, nil
}

// Checks if a users account is linked to a game account
func (r *ExtendedUserRepository) IsGameLinked(userID string) (bool, error) {
	var gameAccountID sql.NullInt64

	err := r.db.QueryRow(`
		SELECT game_account_id FROM users WHERE id = $1
	`, userID).Scan(&gameAccountID)

	if err != nil {
		return false, err
	}

	return gameAccountID.Valid, nil
}

// LinkGameAccount stores the game account ID and API key after verification
func (r *ExtendedUserRepository) LinkGameAccount(userID string, gameAccountID int, apiKey string) error {
	_, err := r.db.Exec(`
        UPDATE users 
        SET game_account_id = $1, game_api_key = $2, updated_at = CURRENT_TIMESTAMP 
        WHERE id = $3
    `, gameAccountID, apiKey, userID)
	return err
}

// GetUsernameByID fetches just the username
func (r *ExtendedUserRepository) GetUsernameByID(userID string) (string, error) {
	var username string
	err := r.db.QueryRow(`SELECT username FROM users WHERE id = $1`, userID).Scan(&username)
	return username, err
}

// UpdateRole updates a user's role (admin function)
func (r *ExtendedUserRepository) UpdateRole(userID, role string) error {
	_, err := r.db.Exec(
		"UPDATE users SET role = $1, updated_at = CURRENT_TIMESTAMP WHERE id = $2",
		role,
		userID,
	)
	return err
}

// ListAll returns all users (admin function)
func (r *ExtendedUserRepository) ListAll() ([]map[string]interface{}, error) {
	rows, err := r.db.Query(`
		SELECT id, username, email, role, profile_image, balance, created_at 
		FROM users 
		ORDER BY created_at DESC
	`)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var users []map[string]interface{}
	for rows.Next() {
		var id, username, email, role string
		var profileImage sql.NullString
		var balance int
		var createdAt string

		if err := rows.Scan(&id, &username, &email, &role, &profileImage, &balance, &createdAt); err != nil {
			return nil, err
		}

		users = append(users, map[string]interface{}{
			"id":            id,
			"username":      username,
			"email":         email,
			"role":          role,
			"profile_image": profileImage.String,
			"balance":       balance,
			"created_at":    createdAt,
		})
	}

	return users, nil
}

// GetItemByID fetches an item from the dashboard.items table
func (r *ExtendedUserRepository) GetItemByID(itemID int) (map[string]interface{}, error) {
	var id, price int
	var name, itemType string
	var description, image sql.NullString

	err := r.db.QueryRow(`
		SELECT id, name, description, type, price, image
		FROM dashboard.items
		WHERE id = $1
	`, itemID).Scan(&id, &name, &description, &itemType, &price, &image)

	if err != nil {
		return nil, err
	}

	return map[string]interface{}{
		"id":          id,
		"name":        name,
		"description": description.String,
		"type":        itemType,
		"price":       price,
		"image":       image.String,
	}, nil
}

// GetItemContents returns the game goods this item contains (for bundles)
func (r *ExtendedUserRepository) GetItemContents(itemID int) ([]map[string]int, error) {
	rows, err := r.db.Query(`
		SELECT game_goods_no, quantity
		FROM dashboard.item_contents
		WHERE item_id = $1
		ORDER BY id
	`, itemID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var contents []map[string]int
	for rows.Next() {
		var goodsNo, quantity int
		if err := rows.Scan(&goodsNo, &quantity); err != nil {
			return nil, err
		}
		contents = append(contents, map[string]int{
			"game_goods_no": goodsNo,
			"quantity":      quantity,
		})
	}

	return contents, rows.Err()
}

// PurchaseItem handles the entire purchase transaction atomically
func (r *ExtendedUserRepository) PurchaseItem(userID string, itemID, quantity int) (newBalance int, err error) {
	// Start transaction
	tx, err := r.db.Begin()
	if err != nil {
		return 0, err
	}
	defer tx.Rollback()

	// Get item price
	var price int
	err = tx.QueryRow(`SELECT price FROM dashboard.items WHERE id = $1`, itemID).Scan(&price)
	if err != nil {
		return 0, err
	}

	totalCost := price * quantity

	// Check and deduct balance
	err = tx.QueryRow(`
		UPDATE users 
		SET balance = balance - $1 
		WHERE id = $2 AND balance >= $1
		RETURNING balance
	`, totalCost, userID).Scan(&newBalance)

	if err == sql.ErrNoRows {
		return 0, sql.ErrNoRows // Insufficient balance
	}
	if err != nil {
		return 0, err
	}

	// Record purchase
	_, err = tx.Exec(`
		INSERT INTO dashboard.item_mall_purchases (user_id, item_id, quantity, price_paid)
		VALUES ($1, $2, $3, $4)
	`, userID, itemID, quantity, totalCost)

	if err != nil {
		return 0, err
	}

	// Commit transaction
	if err = tx.Commit(); err != nil {
		return 0, err
	}

	return newBalance, nil
}

// GetVoucherByCode fetches voucher details by code
func (r *ExtendedUserRepository) GetVoucherByCode(code string) (map[string]interface{}, error) {
	var id int
	var voucherCode, description string
	var maxTotalRedemptions sql.NullInt64

	err := r.db.QueryRow(`
		SELECT id, code, description, max_total_redemptions
		FROM dashboard.vouchers
		WHERE code = $1
	`, code).Scan(&id, &voucherCode, &description, &maxTotalRedemptions)

	if err != nil {
		return nil, err
	}

	var maxTotal interface{}
	if maxTotalRedemptions.Valid {
		maxTotal = int(maxTotalRedemptions.Int64)
	} else {
		maxTotal = nil
	}

	return map[string]interface{}{
		"id":                    id,
		"code":                  voucherCode,
		"description":           description,
		"max_total_redemptions": maxTotal,
	}, nil
}

// GetVoucherContents returns the game goods this voucher contains
func (r *ExtendedUserRepository) GetVoucherContents(voucherID int) ([]map[string]int, error) {
	rows, err := r.db.Query(`
		SELECT game_goods_no, quantity
		FROM dashboard.voucher_contents
		WHERE voucher_id = $1
		ORDER BY id
	`, voucherID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var contents []map[string]int
	for rows.Next() {
		var goodsNo, quantity int
		if err := rows.Scan(&goodsNo, &quantity); err != nil {
			return nil, err
		}
		contents = append(contents, map[string]int{
			"game_goods_no": goodsNo,
			"quantity":      quantity,
		})
	}

	return contents, rows.Err()
}

// IsVoucherRedeemed checks if a user has already redeemed a voucher
func (r *ExtendedUserRepository) IsVoucherRedeemed(userID string, voucherID int) (bool, error) {
	var count int
	err := r.db.QueryRow(`
		SELECT COUNT(*) 
		FROM dashboard.voucher_redemptions 
		WHERE user_id = $1 AND voucher_id = $2
	`, userID, voucherID).Scan(&count)

	if err != nil {
		return false, err
	}

	return count > 0, nil
}

// MarkVoucherRedeemed records that a user has redeemed a voucher
func (r *ExtendedUserRepository) MarkVoucherRedeemed(userID string, voucherID int) error {
	_, err := r.db.Exec(`
		INSERT INTO dashboard.voucher_redemptions (user_id, voucher_id)
		VALUES ($1, $2)
	`, userID, voucherID)
	return err
}

// GetTotalRedemptionCount returns total number of times a voucher has been redeemed
func (r *ExtendedUserRepository) GetTotalRedemptionCount(voucherID int) (int, error) {
	var count int
	err := r.db.QueryRow(`
		SELECT COUNT(*) 
		FROM dashboard.voucher_redemptions 
		WHERE voucher_id = $1
	`, voucherID).Scan(&count)
	return count, err
}

// Discord Verification Methods

type DiscordVerification struct {
	DiscordID       string
	DiscordUsername string
	ExpiresAt       string
	Used            bool
}

// CreateDiscordVerification stores a new verification token
func (r *ExtendedUserRepository) CreateDiscordVerification(token, discordID, discordUsername string, expiresAt interface{}) error {
	_, err := r.db.Exec(`
		INSERT INTO public.discord_verifications (token, discord_id, discord_username, expires_at, used)
		VALUES ($1, $2, $3, $4, false)
	`, token, discordID, discordUsername, expiresAt)
	return err
}

// GetDiscordVerification fetches a verification by token
func (r *ExtendedUserRepository) GetDiscordVerification(token string) (*DiscordVerification, error) {
	var v DiscordVerification
	var expiresAt string
	err := r.db.QueryRow(`
		SELECT discord_id, discord_username, expires_at, used
		FROM public.discord_verifications
		WHERE token = $1
	`, token).Scan(&v.DiscordID, &v.DiscordUsername, &expiresAt, &v.Used)

	if err != nil {
		return nil, err
	}
	v.ExpiresAt = expiresAt
	return &v, nil
}

// MarkDiscordVerificationUsed marks a token as used
func (r *ExtendedUserRepository) MarkDiscordVerificationUsed(token, userID string) error {
	_, err := r.db.Exec(`
		UPDATE public.discord_verifications
		SET used = true, used_at = NOW(), used_by = $1
		WHERE token = $2
	`, userID, token)
	return err
}

// LinkDiscordAndGameAccount links both Discord and game account to a user
func (r *ExtendedUserRepository) LinkDiscordAndGameAccount(userID string, gameAccountID int, apiKey, discordID, discordUsername string) error {
	_, err := r.db.Exec(`
		UPDATE public.users
		SET game_account_id = $1,
		    game_api_key = $2,
		    discord_id = $3,
		    discord_username = $4,
		    updated_at = CURRENT_TIMESTAMP
		WHERE id = $5
	`, gameAccountID, apiKey, discordID, discordUsername, userID)
	return err
}
