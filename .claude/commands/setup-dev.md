---
description: Set up the local OpenMario environment (Docker Postgres + Meilisearch, .env, schema)
---

Set up this repo for local development. Follow AGENTS.md; do not hand-write a
compose file or `.env`.

1. Check Docker is installed **and running** (`docker info`) and Bun is installed.
   If either is missing, stop and tell the user how to install it.
2. If a `.env` already exists, check that `DATABASE_URL` and `MEILI_HOST` are
   localhost **without printing secret values**. If they are not, stop and tell
   the user to move that file aside; never continue against a remote service.
3. Run `bun run dev:setup` and fix any failure it reports (port already in use →
   change `POSTGRES_PORT` / `MEILI_PORT` in `.env`, keep `DATABASE_URL` /
   `MEILI_HOST` consistent).
4. Verify: `docker compose -f docker-compose.dev.yml ps` shows both services
   healthy, and `curl -s localhost:7700/health` returns `{"status":"available"}`.
5. Tell the user the database is empty and that a maintainer can provide a
   sanitized dump for `bun run dev:setup -- --restore <file> --seed-search`.
6. Offer to start `bun run dev`, and report the URLs.
