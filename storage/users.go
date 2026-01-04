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
