package main

import (
	"database/sql"
	"log"
	"net/http"
	"time"

	"github.com/ethan-mdev/authentication-server/config"
	"github.com/ethan-mdev/authentication-server/handlers"
	localstore "github.com/ethan-mdev/authentication-server/storage"

	_ "github.com/lib/pq"
	"github.com/rs/cors"

	authhttp "github.com/ethan-mdev/central-auth/http"
	"github.com/ethan-mdev/central-auth/jwt"
	"github.com/ethan-mdev/central-auth/middleware"
	"github.com/ethan-mdev/central-auth/password"
	"github.com/ethan-mdev/central-auth/storage"
	"github.com/ethan-mdev/central-auth/tokens"
)

func main() {
	// Load configuration
	cfg, err := config.Load()
	if err != nil {
		log.Fatalf("failed to load config: %v", err)
	}

	// Load database
	db, err := sql.Open("postgres", cfg.DatabaseURL)
	if err != nil {
		log.Fatalf("failed to open database: %v", err)
	}
	defer db.Close()

	// Test connection
	if err := db.Ping(); err != nil {
		log.Fatalf("failed to ping database: %v", err)
	}

	log.Println("Connected to database successfully")

	// Initialize repositories
	baseUsers := storage.NewPostgresUserRepository(db)
	// Note: We manage schema via init.sql, not CreateTable()
	// This allows us to add custom columns like profile_image

	// Wrap with extended functionality
	users := localstore.NewExtendedUserRepository(baseUsers, db)

	refreshTokens := tokens.NewPostgresRefreshRepository(db)
	// Note: We manage schema via init.sql, not CreateTable()

	// JWT
	privateKey, err := jwt.LoadPrivateKey([]byte(cfg.JWTPrivateKey))
	if err != nil {
		log.Fatalf("failed to load private key: %v", err)
	}

	jwtManager, err := jwt.NewManager(jwt.Config{
		Algorithm:  "RS256",
		PrivateKey: privateKey,
		KeyID:      "key-1",
	})
	if err != nil {
		log.Fatalf("failed to create jwt manager: %v", err)
	}

	// Handler (uses base user repository)
	authHandler := &authhttp.AuthHandler{
		Users:         baseUsers,
		RefreshTokens: refreshTokens,
		Hash:          password.Default(),
		JWT:           jwtManager,
		AccessExpiry:  15 * time.Minute,
		RefreshExpiry: 7 * 24 * time.Hour,
	}

	// Profile handler
	profileHandler := &handlers.ProfileHandler{
		Users: users,
	}

	// Admin handler
	adminHandler := &handlers.AdminHandler{
		Users: users,
	}

	mux := http.NewServeMux()

	// Public routes
	mux.HandleFunc("POST /register", authHandler.Register())
	mux.HandleFunc("POST /login", authHandler.Login())
	mux.HandleFunc("POST /refresh", authHandler.RefreshToken())
	mux.HandleFunc("POST /logout", authHandler.Logout())
	mux.HandleFunc("GET /profile/{userId}", profileHandler.GetProfile())

	// Protected routes
	mux.Handle("POST /change-password", middleware.Auth(jwtManager, authHandler.ChangePassword()))
	mux.Handle("PUT /profile", middleware.Auth(jwtManager, profileHandler.UpdateProfile()))

	// Admin routes
	mux.Handle("GET /admin/users", middleware.Auth(jwtManager, adminHandler.ListUsers()))
	mux.Handle("PUT /admin/users/{userId}/role", middleware.Auth(jwtManager, adminHandler.UpdateUserRole()))

	// JWKS endpoint for other services to get the public key
	mux.HandleFunc("GET /.well-known/jwks.json", func(w http.ResponseWriter, r *http.Request) {
		jwks, _ := jwtManager.JWKS()
		w.Header().Set("Content-Type", "application/json")
		w.Write(jwks)
	})

	// Health check
	mux.HandleFunc("GET /health", func(w http.ResponseWriter, r *http.Request) {
		w.Write([]byte("ok"))
	})

	// CORS
	c := cors.New(cors.Options{
		AllowedOrigins:   cfg.AllowedOrigins,
		AllowedMethods:   []string{"GET", "POST", "PUT", "DELETE", "OPTIONS"},
		AllowedHeaders:   []string{"Authorization", "Content-Type"},
		AllowCredentials: true,
	})

	log.Printf("Auth service running on :%s\n", cfg.Port)
	log.Fatal(http.ListenAndServe(":"+cfg.Port, c.Handler(mux)))
}
