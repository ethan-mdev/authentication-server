package main

import (
	"database/sql"
	"log"
	"net/http"
	"os"
	"time"

	"github.com/joho/godotenv"
	"github.com/rs/cors"
	_ "modernc.org/sqlite"

	authhttp "github.com/ethan-mdev/central-auth/http"
	"github.com/ethan-mdev/central-auth/jwt"
	"github.com/ethan-mdev/central-auth/middleware"
	"github.com/ethan-mdev/central-auth/password"
	"github.com/ethan-mdev/central-auth/storage"
	"github.com/ethan-mdev/central-auth/tokens"
)

func main() {
	// Load .env
	godotenv.Load()

	// Load database
	db, err := sql.Open("sqlite", "./auth.db")
	if err != nil {
		log.Fatalf("failed to open database: %v", err)
	}
	defer db.Close()

	// Enable WAL mode (safer & faster)
	db.Exec("PRAGMA journal_mode=WAL;")
	db.Exec("PRAGMA foreign_keys = ON;")

	// Initialize repositories
	users := storage.NewSQLiteUserRepository(db)
	if err := users.CreateTable(); err != nil {
		log.Fatalf("failed to create users table: %v", err)
	}

	refreshTokens := tokens.NewSQLiteRefreshRepository(db)
	if err := refreshTokens.CreateTable(); err != nil {
		log.Fatalf("failed to create refresh_tokens table: %v", err)
	}

	// JWT
	privateKey, err := jwt.LoadPrivateKey([]byte(os.Getenv("JWT_PRIVATE_KEY")))
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

	// Handler
	authHandler := &authhttp.AuthHandler{
		Users:         users,
		RefreshTokens: refreshTokens,
		Hash:          password.Default(),
		JWT:           jwtManager,
		AccessExpiry:  15 * time.Minute,
		RefreshExpiry: 7 * 24 * time.Hour,
	}

	mux := http.NewServeMux()

	// Public routes
	mux.HandleFunc("POST /register", authHandler.Register())
	mux.HandleFunc("POST /login", authHandler.Login())
	mux.HandleFunc("POST /refresh", authHandler.RefreshToken())

	// Protected
	mux.Handle("POST /change-password", middleware.Auth(jwtManager, authHandler.ChangePassword()))

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
		AllowedOrigins: []string{
			"https://dashboard.ethan-mdev.com",
			"https://forum.ethan-mdev.com",
			"https://auth.ethan-mdev.com",
			"http://localhost:5173",
		},
		AllowedMethods:   []string{"GET", "POST", "PUT", "DELETE", "OPTIONS"},
		AllowedHeaders:   []string{"Authorization", "Content-Type"},
		AllowCredentials: true,
	})

	log.Println("Auth service running on :8080")
	log.Fatal(http.ListenAndServe(":8080", c.Handler(mux)))
}
