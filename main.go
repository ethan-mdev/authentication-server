package main

import (
	"context"
	"database/sql"
	"log"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/ethan-mdev/authentication-server/config"
	"github.com/ethan-mdev/authentication-server/handlers"
	localstore "github.com/ethan-mdev/authentication-server/storage"

	_ "github.com/lib/pq"
	_ "github.com/microsoft/go-mssqldb"
	"github.com/rs/cors"

	authhttp "github.com/ethan-mdev/central-auth/http"
	"github.com/ethan-mdev/central-auth/jwt"
	"github.com/ethan-mdev/central-auth/middleware"
	"github.com/ethan-mdev/central-auth/password"
	"github.com/ethan-mdev/central-auth/storage"
	"github.com/ethan-mdev/central-auth/tokens"
)

func main() {
	cfg, err := config.Load()
	if err != nil {
		log.Fatalf("failed to load config: %v", err)
	}

	// PostgreSQL (auth)
	db, err := sql.Open("postgres", cfg.DatabaseURL)
	if err != nil {
		log.Fatalf("failed to open database: %v", err)
	}
	defer db.Close()

	if err := db.Ping(); err != nil {
		log.Fatalf("failed to ping database: %v", err)
	}
	log.Println("Connected to authentication database successfully")

	// SQL Server (game accounts)
	gameAccountDB, err := sql.Open("sqlserver", cfg.GameAccountDBURL)
	if err != nil {
		log.Fatalf("failed to open game account database: %v", err)
	}
	defer gameAccountDB.Close()

	if err := gameAccountDB.Ping(); err != nil {
		log.Fatalf("failed to ping game account database: %v", err)
	}
	log.Println("Connected to game account database successfully")

	// SQL Server (game characters)
	gameCharacterDB, err := sql.Open("sqlserver", cfg.GameCharacterDBURL)
	if err != nil {
		log.Fatalf("failed to open game character database: %v", err)
	}
	defer gameCharacterDB.Close()

	if err := gameCharacterDB.Ping(); err != nil {
		log.Fatalf("failed to ping game character database: %v", err)
	}
	log.Println("Connected to game character database successfully")

	// Initialize repositories
	baseUsers := storage.NewPostgresUserRepository(db)
	users := localstore.NewExtendedUserRepository(baseUsers, db)
	refreshTokens := tokens.NewPostgresRefreshRepository(db)

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

	// Handlers
	authHandler := &authhttp.AuthHandler{
		Users:         baseUsers,
		RefreshTokens: refreshTokens,
		Hash:          password.Default(),
		JWT:           jwtManager,
		AccessExpiry:  15 * time.Minute,
		RefreshExpiry: 7 * 24 * time.Hour,
	}

	profileHandler := &handlers.ProfileHandler{
		Users: users,
	}

	gameHandler := handlers.NewGameHandler(users, gameAccountDB, gameCharacterDB)

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

	// Game routes
	mux.Handle("GET /game/credentials", middleware.Auth(jwtManager, http.HandlerFunc(gameHandler.GetCredentials)))
	mux.Handle("GET /game/characters", middleware.Auth(jwtManager, http.HandlerFunc(gameHandler.GetCharacters)))
	mux.Handle("POST /game/verify", middleware.Auth(jwtManager, http.HandlerFunc(gameHandler.Verify)))

	// Admin routes
	mux.Handle("GET /admin/users",
		middleware.Auth(jwtManager,
			middleware.RequireRole("admin")(adminHandler.ListUsers()),
		),
	)
	mux.Handle("PUT /admin/users/{userId}/role",
		middleware.Auth(jwtManager,
			middleware.RequireRole("admin")(adminHandler.UpdateUserRole()),
		),
	)

	// JWKS endpoint
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

	server := &http.Server{
		Addr:         ":" + cfg.Port,
		Handler:      c.Handler(mux),
		ReadTimeout:  15 * time.Second,
		WriteTimeout: 15 * time.Second,
		IdleTimeout:  60 * time.Second,
	}

	go func() {
		log.Printf("Server running on :%s", cfg.Port)
		if err := server.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			log.Fatalf("Server failed to start: %v", err)
		}
	}()

	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit

	log.Println("Shutting down server...")

	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	if err := server.Shutdown(ctx); err != nil {
		log.Fatalf("Server forced to shutdown: %v", err)
	}

	log.Println("Server exited")
}
