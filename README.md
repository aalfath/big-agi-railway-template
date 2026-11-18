[![Deploy on Railway](https://railway.com/button.svg)](https://railway.com/new/template/big-agi?utm_medium=integration&utm_source=button&utm_campaign=big-agi)

# Big-AGI on Railway

This repo is the source of the [Big-AGI Railway template](https://railway.com/deploy/big-agi). It deploys:

| Service | What it runs | Data |
|---|---|---|
| **Big-AGI** | Official image `ghcr.io/enricoros/big-agi:v2.1.3` (pinned by digest), with Caddy 2.11.9 in front as a login gateway | none on disk |
| **Postgres** | Railway's Postgres, with a volume | shared chat links |

big-AGI has no login of its own. Here only Caddy listens on the public port: every page and every API route asks for a username and password before anything reaches big-AGI, which listens on `127.0.0.1:3000` inside the container. Only `/healthz` (Railway's health check), the PWA manifest and the icons answer without the login.

## Variables

| Variable | Default | Notes |
|---|---|---|
| `BASIC_AUTH_USERNAME` | `admin` | Gateway username (no spaces) |
| `BASIC_AUTH_PASSWORD` | `${{secret(32)}}` | Generated at deploy; change it any time and redeploy. Only its bcrypt hash reaches Caddy |
| `POSTGRES_PRISMA_URL`, `POSTGRES_URL_NON_POOLING` | `${{Postgres.DATABASE_URL}}` | Enables Chat Link Sharing; the table is created on boot with `prisma db push` |
| `PORT` | `8080` | Public port (Caddy) |

Optional, add them on the Big-AGI service if you want server-side model keys shared by everyone who has the login: `OPENAI_API_KEY`, `ANTHROPIC_API_KEY`, `GEMINI_API_KEY`, `OPENROUTER_API_KEY`, `OLLAMA_API_HOST` and the others in [upstream's list](https://github.com/enricoros/big-AGI/blob/v2.1.3/docs/environment-variables.md). Without them, each user adds keys in the app; those keys, the chats and the settings stay in that user's browser.

## Files

- `Dockerfile`: the pinned big-AGI image, plus the Caddy binary from the pinned `caddy:2.11.9-alpine` image
- `Caddyfile`: the gateway (health check, public static files, basic auth, reverse proxy with streaming)
- `start.sh`: hashes the password, prepares the database, runs big-AGI and Caddy, and exits if either stops so Railway restarts the service
- `compose.test.yml`: local test only (`docker compose -f compose.test.yml up --build`, then open http://localhost:8080 as `admin` / `localtestpassword`)

## Updates

Projects deployed from the template build from this repo's `main` branch. When we bump the pinned version here, Railway shows an "update available" notice in your project, and you choose when to apply it. Read [CHANGELOG.md](CHANGELOG.md) first: breaking changes are listed at the top of each entry. Chats live in browsers, so updates never touch them; export them from big-AGI if you want a backup.

Big-AGI is MIT licensed, by [Enrico Ros](https://github.com/enricoros/big-AGI). This wrapper is not affiliated with the big-AGI project.
