package config

import (
	"os"

	"github.com/joho/godotenv"
)

type Config struct {
	JWTPrivateKey  string
	DatabaseURL    string
	Port           string
	AllowedOrigins []string
}

func Load() (*Config, error) {
	// Load .env file
	godotenv.Load()

	return &Config{
		JWTPrivateKey: os.Getenv("JWT_PRIVATE_KEY"),
		DatabaseURL:   getEnv("DATABASE_URL", "postgres://postgres:password@localhost:5432/postgres?sslmode=disable"),
		Port:          getEnv("PORT", "8080"),
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

func getEnv(key, fallback string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return fallback
}
