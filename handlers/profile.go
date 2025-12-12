package handlers

import (
	"encoding/json"
	"net/http"

	"github.com/ethan-mdev/authentication-server/storage"
	"github.com/ethan-mdev/central-auth/middleware"
)

type ProfileHandler struct {
	Users *storage.ExtendedUserRepository
}

// GetProfile returns public user profile information
// GET /profile/{userId}
func (h *ProfileHandler) GetProfile() http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		userId := r.PathValue("userId")

		// Use the extended method that returns full profile data
		profile, err := h.Users.GetProfileByID(userId)
		if err != nil {
			http.Error(w, "User not found", http.StatusNotFound)
			return
		}

		// Return public profile data
		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(profile)
	}
}

// UpdateProfile allows authenticated users to update their profile
// PUT /profile (requires auth)
func (h *ProfileHandler) UpdateProfile() http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		// Get claims from auth middleware
		claims, ok := middleware.GetClaims(r.Context())
		if !ok {
			http.Error(w, "Unauthorized", http.StatusUnauthorized)
			return
		}

		var req struct {
			ProfileImage string `json:"profile_image"`
		}

		if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
			http.Error(w, "Invalid request body", http.StatusBadRequest)
			return
		}

		// TODO: Validate profile image (must be one of the allowed avatars)

		if err := h.Users.UpdateProfileImage(claims.UserID, req.ProfileImage); err != nil {
			http.Error(w, "Failed to update profile", http.StatusInternalServerError)
			return
		}

		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(map[string]string{
			"message": "Profile updated successfully",
		})
	}
}
