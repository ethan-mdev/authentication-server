# Authentication Server

A personal authentication backend using RS256 JWT signing, built with [central-auth](https://github.com/ethan-mdev/central-auth).

## What it does

- Issues RS256 signed JWTs for login/register
- Exposes JWKS at `/.well-known/jwks.json` for other services to validate tokens
- Handles refresh token rotation and logout
- Bridges authentication to a legacy game database (MySQL) that uses MD5 password hashing
- Manages game account linking and API key generation for launcher authentication

## Architecture

| Database | Purpose |
|----------|---------|
| PostgreSQL | User auth, bcrypt passwords, API keys (plaintext), account linking |
| MySQL (Accounts) | Legacy game accounts, MD5 hashed API keys |
| MySQL (Characters) | Character data lookups for dashboard |

## Services using this

- [community-hub](https://github.com/ethan-mdev/community-hub) - Forum
- [player-portal](https://github.com/ethan-mdev/player-portal) - Dashboard
- [game-launcher](https://github.com/ethan-mdev/game-launcher) - Retrieves credentials for game client login