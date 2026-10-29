#!/usr/bin/env bash
# One-command local setup: .env, Postgres + Meilisearch, dependencies, schema.
#
#   bun run dev:setup                     # fresh setup (safe to re-run)
#   bun run dev:setup -- --restore FILE   # also load a pg_dump (.dump) into local Postgres
#   bun run dev:setup -- --seed-search    # also (re)build the Meilisearch indexes
#
# It refuses to touch any database or search host that is not on localhost.
set -euo pipefail

cd "$(dirname "$0")/.."
COMPOSE=(docker compose -f docker-compose.dev.yml)
RESTORE_FILE=""
SEED_SEARCH=0

while [ $# -gt 0 ]; do
  case "$1" in
    --restore) RESTORE_FILE="${2:?--restore needs a file}"; shift 2 ;;
    --seed-search) SEED_SEARCH=1; shift ;;
    *) echo "Unknown option: $1" >&2; exit 2 ;;
  esac
done

need() { command -v "$1" >/dev/null || { echo "Missing '$1'. $2" >&2; exit 1; }; }
need docker "Install Docker Desktop: https://docs.docker.com/get-docker/"
need bun "Install Bun: https://bun.sh"
need openssl "Install openssl."
docker info >/dev/null 2>&1 || { echo "Docker is installed but not running. Start it and retry." >&2; exit 1; }

secret() { openssl rand -hex 32; }

if [ ! -f .env ]; then
  echo "→ Creating .env from .env.dev.example"
  sed -e "s|MEILI_MASTER_KEY=__GENERATED__|MEILI_MASTER_KEY=$(secret)|" \
      -e "s|BETTER_AUTH_SECRET=__GENERATED__|BETTER_AUTH_SECRET=$(secret)|" \
      .env.dev.example > .env
else
  echo "→ Keeping existing .env"
fi

# Safety: Bun does not let --env-file override variables already exported in
# your shell, so a leftover DATABASE_URL could silently point commands at a real
# database. Clear every variable .env defines so the file is the only source.
for key in $(grep -E '^[A-Za-z_][A-Za-z0-9_]*=' .env | cut -d= -f1); do
  unset "$key"
done

# Never run schema changes / seeds against anything but a local stack.
get() { grep -E "^$1=" .env | head -1 | cut -d= -f2- | tr -d '"'; }
is_local() {
  local rest="${1#*://}"      # drop scheme
  rest="${rest##*@}"          # drop user:password@
  local host="${rest%%[:/]*}" # drop :port and /path
  [ "$host" = localhost ] || [ "$host" = 127.0.0.1 ]
}
for key in DATABASE_URL MEILI_HOST; do
  if ! is_local "$(get "$key")"; then
    echo "✗ $key in .env does not point at localhost." >&2
    echo "  Refusing to continue so a shared/production service is never modified." >&2
    echo "  Move that file aside (mv .env .env.backup) and run this again." >&2
    exit 1
  fi
done

echo "→ Starting Postgres + Meilisearch"
"${COMPOSE[@]}" up -d --wait

echo "→ Installing dependencies"
bun install

if [ -n "$RESTORE_FILE" ]; then
  [ -f "$RESTORE_FILE" ] || { echo "No such file: $RESTORE_FILE" >&2; exit 1; }
  echo "→ Restoring $RESTORE_FILE into local Postgres"
  "${COMPOSE[@]}" exec -T postgres sh -c \
    'pg_restore --no-owner --clean --if-exists -U "$POSTGRES_USER" -d "$POSTGRES_DB"' \
    < "$RESTORE_FILE" || echo "  (pg_restore reported warnings — usually harmless)"
else
  echo "→ Creating database schema"
  # The migration history can't bootstrap an empty database (0000 is an
  # introspection snapshot), so build the schema straight from the Drizzle code.
  bun run db:push -- --force
fi

if [ "$SEED_SEARCH" = 1 ]; then
  echo "→ Building Meilisearch indexes"
  bun run meili:seed
fi

cat <<'EOF'

✓ Local environment ready.

  bun run dev        start client + server + mcp
  Frontend           http://localhost:5173
  API                http://localhost:3000/api
  Meilisearch        http://localhost:7700

The database starts empty. Load the sanitized dump from the private
OpenMario/backup repo (ask a maintainer for access if needed):
  gh repo clone OpenMario/backup ../openmario-backup -- --depth 1
  bun run dev:setup -- --restore ../openmario-backup/openmario-sanitized-20261024.dump --seed-search
EOF
