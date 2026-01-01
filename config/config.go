package config

import (
	"os"

	"github.com/joho/godotenv"
)

type Config struct {
	JWTPrivateKey      string
	DatabaseURL        string // PostgreSQL (auth)
	GameAccountDBURL   string // MySQL (game accounts)
	GameCharacterDBURL string // MySQL (game characters)
	Port               string
	AllowedOrigins     []string
}

func Load() (*Config, error) {
	// Load .env file
	godotenv.Load()

	return &Config{
		JWTPrivateKey:      os.Getenv("JWT_PRIVATE_KEY"),
		DatabaseURL:        os.Getenv("DATABASE_URL"),
		GameAccountDBURL:   os.Getenv("GAME_ACCOUNT_DB_URL"),
		GameCharacterDBURL: os.Getenv("GAME_CHARACTER_DB_URL"),
		Port:               os.Getenv("PORT"),
		AllowedOrigins: []string{
			"https://dashboard.ethan-mdev.com",
			"https://forum.ethan-mdev.com",
			"https://auth.ethan-mdev.com",
			"http://localhost:5173",
			"http://localhost:5174",
			"http://localhost:5175",
		},
	}, nil
}
