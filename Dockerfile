# big-AGI for Railway: the official big-AGI image plus Caddy as a small login gateway.
# Caddy listens on $PORT (public), asks for a username and password, and proxies to
# big-AGI on 127.0.0.1:3000, which is never reachable from outside the container.

# Caddy binary only (static Go build)
FROM caddy:2.11.9-alpine@sha256:003a97808e781aa9f7e75cc2f43d34d461099031faf5e20faefb9f61126836f0 AS caddy

# Official big-AGI image, pinned by version and digest
FROM ghcr.io/enricoros/big-agi:v2.1.3@sha256:9932746ce1c5545a4ec494b7c9c28ca8f1d6067c4d1b3715547ab98fb9e54285

COPY --from=caddy /usr/bin/caddy /usr/local/bin/caddy
COPY Caddyfile /etc/railway/Caddyfile
COPY start.sh /usr/local/bin/railway-start

ENV CHECKPOINT_DISABLE=1 \
    PRISMA_HIDE_UPDATE_MESSAGE=1 \
    XDG_CONFIG_HOME=/tmp/caddy-config \
    XDG_DATA_HOME=/tmp/caddy-data

EXPOSE 8080
CMD ["/usr/local/bin/railway-start"]
