package handlers

import (
	"encoding/json"
	"net/http"

	"github.com/ethan-mdev/authentication-server/storage"
)

type AdminHandler struct {
	Users *storage.ExtendedUserRepository
}

// ListUsers returns all users (admin only)
// GET /admin/users
func (h *AdminHandler) ListUsers() http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		// TODO: Implement pagination
		users, err := h.Users.ListAll()
		if err != nil {
			http.Error(w, "Failed to fetch users", http.StatusInternalServerError)
			return
		}

		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(users)
	}
}

// UpdateUserRole allows admins to change user roles
// PUT /admin/users/{userId}/role
func (h *AdminHandler) UpdateUserRole() http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		userId := r.PathValue("userId")

		var req struct {
			Role string `json:"role"`
		}

		if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
			http.Error(w, "Invalid request body", http.StatusBadRequest)
			return
		}

		// Validate role
		validRoles := map[string]bool{"user": true, "moderator": true, "admin": true}
		if !validRoles[req.Role] {
			http.Error(w, "Invalid role", http.StatusBadRequest)
			return
		}

		if err := h.Users.UpdateRole(userId, req.Role); err != nil {
			http.Error(w, "Failed to update role", http.StatusInternalServerError)
			return
		}

		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(map[string]string{
			"message": "Role updated successfully",
		})
	}
}
