# OpenMario — guide for AI coding agents

OpenMario is a Drexel co-op salary, course, and professor explorer. This file is
the source of truth for any agent (Claude Code, Cursor, Copilot, Codex…) working
in this repo. Humans: see [CONTRIBUTING.md](CONTRIBUTING.md).

## Stack

Bun workspaces + Turborepo monorepo, TypeScript throughout.

| Path | What it is |
|------|-----------|
| `apps/client` | React + Vite frontend (TanStack Router) |
| `apps/server` | Bun + Hono API, oRPC contracts, better-auth |
| `apps/mcp` | MCP server that exposes search tools |
| `apps/scraper` | Drexel TMS scraper (needs a Drexel login — **do not run**) |
| `packages/db` | Drizzle schema + migrations (`packages/db/drizzle/migrations`) |
| `packages/contracts` | Shared oRPC/zod contracts between client and server |
| `packages/meilisearch` | Search index definitions and seeding |

Postgres (Drizzle) is the source of truth. Meilisearch is a derived search index
rebuilt from Postgres. Neo4j appears in old config but is not used by the code.

## Set up the local environment

Run exactly this; do not hand-write a compose file or `.env`:

```bash
bun run dev:setup
```

It creates `.env` from `.env.dev.example` (with generated secrets), starts
Postgres + Meilisearch via `docker-compose.dev.yml`, installs dependencies, and
builds the schema from `packages/db/src/schema` with `drizzle-kit push` (the
migration history cannot bootstrap an empty database). It is safe to re-run. Then `bun run dev`.

- **It refuses to run if `.env` points at a non-localhost database or search
  host.** Never override that. If it triggers, tell the user and have them move
  their `.env` aside.
- Stop: `bun run dev:down`. Wipe all local data: `bun run dev:reset`.
- The local DB starts **empty**. Data comes from a maintainer-provided sanitized
  dump: `bun run dev:setup -- --restore path/to.dump --seed-search`. Never
  scrape, and never ask for production credentials.

Prerequisites: Docker (running) and Bun ≥ 1.4.

## Everyday commands

```bash
bun run dev                 # client + server + mcp (needs .env)
bun run server:build        # bundle the API — must pass before a PR
bun run client:build        # vite build + tsc — must pass before a PR
bun run fmt                 # biome format (3-space indent, single quotes, semicolons)
bun run db:generate         # after editing packages/db/src/schema → creates a migration
bun run db:push             # sync the local DB to packages/db/src/schema
bun run meili:seed          # rebuild search indexes from Postgres
```

## Rules

**Safety**
- **Shell variables beat `.env`.** Bun's `--env-file` will not override a
  `DATABASE_URL`/`MEILI_HOST` already exported in your shell. Before any
  `db:*` or `meili:*` command, confirm those are unset or localhost. `dev:setup`
  clears them for you; other commands do not.
- Only ever touch the local stack. Never read, print, or commit `.env` or any
  credentials; never point commands at a remote database or Meilisearch.
- Do not run anything in `apps/scraper`, `db:push`, or `meili:seed` unless
  `DATABASE_URL`/`MEILI_HOST` are localhost.
- Do not edit `prod.*.dockerfile` or the root `docker-compose.yml` unless the
  task is explicitly about deployment — they ship to production.

**Code**
- Match the surrounding code: Biome formatting, no new dependencies without a
  reason stated in the PR.
- Schema changes go through Drizzle: edit `packages/db/src/schema`, run
  `bun run db:generate`, commit the generated migration. Never edit applied
  migration files.
- API shape lives in `packages/contracts`; change the contract first, then the
  server router and client call sites.
- Keep changes small and focused: one concern per PR. No drive-by refactors or
  formatting churn in files you are not changing.
- Do not add comments that restate the code. Explain *why* only.

**Before you say "done"**
1. `bun run fmt`
2. `bun run server:build` and `bun run client:build` pass (run whichever apps
   you touched, plus `apps/mcp` build if you changed shared packages).
3. You actually ran the feature in `bun run dev` and looked at it, or you say
   plainly that you could not.

## Pull requests

Follow [CONTRIBUTING.md](CONTRIBUTING.md): branch off `staging`, open the PR
**into `staging`** (never `main`), fill in the PR template, and state what you
did and did not verify. Do not push, merge, or open a PR unless the user asked.
