# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Vuln Bank** is an intentionally vulnerable banking web application for security training and CTF challenges. All vulnerabilities are by design. This should **never** be deployed to an internet-facing production environment.

## Running the Application

**Docker (recommended):**
```bash
docker-compose up --build
```
App runs on port 5000 (also mapped to 80). PostgreSQL starts on port 5432.

**Local setup:**
```bash
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
mkdir -p static/uploads
# Edit .env: set DB_HOST=localhost
python3 app.py
```

**Database** initializes automatically on first startup via `init_db()` in `database.py`. Default admin credentials: `admin` / `admin123` (account `ADMIN001`).

**Environment variables** — copy `.env.example` to `.env`. Key vars:
- `DB_HOST=db` (use `localhost` for local dev, `db` for Docker)
- `DEEPSEEK_API_KEY` — optional; AI chat falls back to mock mode if absent

## Architecture

**Stack:** Flask 2.0.1 + PostgreSQL 13 + Vanilla JS frontend. No test framework configured.

**Key files:**
- `app.py` — Monolithic Flask app (~2065 lines); all routes and business logic
- `auth.py` — JWT authentication (intentionally weak: `secret123` key, accepts `none` algorithm, no expiration)
- `database.py` — PostgreSQL connection pool (min 1, max 10); `init_db()` creates schema and seeds default data
- `ai_agent_deepseek.py` — AI customer support agent (DeepSeek API with mock fallback)
- `static/dashboard.js` — Frontend logic; JWT stored in `localStorage` (intentional XSS vector)
- `static/openapi.json` — Full API spec; browsable at `http://localhost:5000/api/docs`

**Authentication flow:** JWT tokens accepted from Authorization header, query params, form data, or cookies. No token expiration or revocation.

**Database schema tables:** `users`, `transactions`, `loans`, `virtual_cards`, `card_transactions`, `bill_categories`, `billers`, `bill_payments`. Passwords and card numbers stored in plaintext by design.

## Intentional Vulnerabilities (Do Not Fix)

The following are deliberate teaching vulnerabilities — do not remediate them:

| Category | Examples |
|----------|---------|
| Injection | SQL injection in `/login` and `/api/billers/by-category/<id>` |
| Broken Auth | JWT accepts `none` algorithm; weak 3-4 digit OTP reset |
| BOLA | `/check_balance/<account_number>`, `/transactions/<account_number>` — no ownership check |
| Mass Assignment | `/register`, `/api/virtual-cards/<id>/update-limit` |
| File Upload | No type/size validation; path traversal; SSRF via `/upload_profile_picture_url` |
| Information Disclosure | `/debug/users` exposes all users; detailed error messages |
| AI/LLM | Prompt injection via `/api/ai/chat`; system info at `/api/ai/system-info` |
| SSRF | Internal mock endpoints at `/internal/secret`, `/internal/config.json`, `/latest/meta-data/*` |

**Hidden admin panel:** `/sup3r_s3cr3t_admin`

## API Versioning

Password reset has three intentionally different versions (`/api/v1/`, `/api/v2/`, `/api/v3/`) — each with different vulnerability characteristics. `v2` uses a 4-digit OTP (added in recent commit); `v1` uses 3-digit.

## AI Agent

`ai_agent_deepseek.py` connects to DeepSeek API. Rate limits: 5 req/3hrs unauthenticated, 10 req/3hrs authenticated. Without a valid API key, it returns mock responses (set `DEEPSEEK_API_KEY=invalid` to force mock mode during development).

## CI/CD

`.github/workflows/deploy.yml` deploys to production via rsync+SSH on push to `main`. The `.env` file is excluded from rsync. No automated tests run in the pipeline.
