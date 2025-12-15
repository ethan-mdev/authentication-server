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

// GetProfileByID fetches user profile including profile_image
func (r *ExtendedUserRepository) GetProfileByID(userID string) (map[string]interface{}, error) {
	var id, username, email, role string
	var profileImage sql.NullString
	var createdAt string

	err := r.db.QueryRow(`
		SELECT id, username, email, role, profile_image, created_at 
		FROM users 
		WHERE id = $1
	`, userID).Scan(&id, &username, &email, &role, &profileImage, &createdAt)

	if err != nil {
		return nil, err
	}

	return map[string]interface{}{
		"user_id":       id,
		"username":      username,
		"email":         email,
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
