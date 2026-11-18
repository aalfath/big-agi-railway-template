#!/bin/sh
# Start script for big-AGI on Railway.
# 1. Hash the gateway password (only the bcrypt hash reaches Caddy's config).
# 2. If Postgres is configured, create or update the Chat Link Sharing table
#    with upstream's documented "prisma db push" (no-op when it already exists).
# 3. Run big-AGI on 127.0.0.1:3000 and Caddy on $PORT; stop if either exits.
set -eu

export PORT="${PORT:-8080}"
export BASIC_AUTH_USERNAME="${BASIC_AUTH_USERNAME:-admin}"
if [ -z "${BASIC_AUTH_PASSWORD:-}" ]; then
  echo "[railway] BASIC_AUTH_PASSWORD is empty. Set it on the service; refusing to start without a login." >&2
  exit 1
fi
case "$BASIC_AUTH_USERNAME" in
  *[[:space:]]*) echo "[railway] BASIC_AUTH_USERNAME must not contain spaces." >&2; exit 1 ;;
esac
mkdir -p "$XDG_CONFIG_HOME" "$XDG_DATA_HOME"
BASIC_AUTH_HASH="$(caddy hash-password --plaintext "$BASIC_AUTH_PASSWORD")"
export BASIC_AUTH_HASH
unset BASIC_AUTH_PASSWORD

cd /app
if [ -n "${POSTGRES_PRISMA_URL:-}" ]; then
  export POSTGRES_URL_NON_POOLING="${POSTGRES_URL_NON_POOLING:-$POSTGRES_PRISMA_URL}"
  i=1
  until node node_modules/prisma/build/index.js db push --skip-generate --schema src/server/prisma/schema.prisma; do
    if [ "$i" -ge 10 ]; then
      echo "[railway] WARNING: could not prepare the database; chat link sharing will not work until it is reachable." >&2
      break
    fi
    i=$((i + 1))
    sleep 5
  done
fi

node_modules/.bin/next start -H 127.0.0.1 -p 3000 &
NEXT_PID=$!
caddy run --config /etc/railway/Caddyfile --adapter caddyfile &
CADDY_PID=$!

trap 'kill -TERM "$NEXT_PID" "$CADDY_PID" 2>/dev/null' TERM INT
set +e
wait -n
status=$?
kill -TERM "$NEXT_PID" "$CADDY_PID" 2>/dev/null
wait
echo "[railway] a process exited (status $status); stopping so Railway restarts the service." >&2
exit "$status"
