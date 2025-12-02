# Authentication Server

A personal authentication backend using RS256 JWT signing, built with [central-auth](https://github.com/ethan-mdev/central-auth).

## What it does

- Issues RS256 signed JWTs for login/register
- Exposes JWKS at `/.well-known/jwks.json` for other services to validate tokens
- Handles refresh token rotation and logout

## Setup

### 1. Generate RSA Key

```bash
openssl genrsa -out private.pem 2048
```

### 2. Add to `.env`

```env
JWT_PRIVATE_KEY="-----BEGIN RSA PRIVATE KEY-----
...
-----END RSA PRIVATE KEY-----"
```

### 3. Run

```bash
go run main.go
```

## Services using this

- [community-hub](https://github.com/ethan-mdev/community-hub) - Forum
- [dashboard](https://github.com/ethan-mdev/player-portal) - Dashboard