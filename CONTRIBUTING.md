# Contributing to OpenMario

Contributions made with an AI coding agent are welcome. This repo is set up so an
agent can get you running in a few minutes and keep you on the rails.

## 1. Get running

You need [Docker](https://docs.docker.com/get-docker/) (running) and
[Bun](https://bun.sh).

```bash
git clone https://github.com/OpenMario/OpenMario.git
cd OpenMario
bun run dev:setup     # .env + Postgres + Meilisearch + deps + schema
bun run dev           # http://localhost:5173
```

Using Claude Code? Open the repo and run `/setup-dev`. Using another agent, point
it at [AGENTS.md](AGENTS.md) and say "set up the local environment".

The local database starts empty. Ask a maintainer for a sanitized dump, then:

```bash
bun run dev:setup -- --restore path/to/openmario.dump --seed-search
```

Other handy commands: `bun run dev:down` (stop), `bun run dev:reset` (wipe local
data). The setup refuses to run against any non-localhost database, by design.

## 2. Vibecoding ground rules

- **Describe the outcome, then read the diff.** You own every line you submit,
  whoever or whatever typed it.
- **One concern per PR.** Small PRs get reviewed and merged; sprawling ones
  stall. Tell your agent to stay in scope and not reformat unrelated files.
- **Run it and look at it.** Builds passing is not the same as the feature
  working. For UI changes include a screenshot.
- **Never use or ask for production credentials,** never commit `.env`, dumps,
  or scraped data, and never run `apps/scraper` (it needs a Drexel login).
- **Check your shell** before running any `db:*` or `meili:*` command: an
  exported `DATABASE_URL` overrides `.env` and can point at a real database.
- **Schema changes** go through Drizzle: edit `packages/db/src/schema`, run
  `bun run db:generate`, commit the new migration, never edit old ones.
- **New dependencies** need a reason in the PR description.

## 3. Pull request workflow

```
main        ← production, only updated from staging by a maintainer
 └─ staging ← integration branch; all contributor PRs target this
     └─ feat/your-change
```

1. Sync and branch from `staging`:
   ```bash
   git fetch origin
   git switch -c feat/short-description origin/staging
   ```
   Prefix with `feat/`, `fix/`, or `chore/`.
2. Make your change, then verify:
   ```bash
   bun run fmt
   bun run server:build && bun run client:build
   ```
3. Commit with short imperative messages: `fix: stop empty search crash`.
4. Push and open the PR **against `staging`** (not `main`):
   ```bash
   git push -u origin HEAD
   gh pr create --base staging
   ```
   Fill in the template honestly, especially *How I tested* and *Not verified*.
   Claude Code users can run `/open-pr` to do this with the checks built in.
5. Keep the branch up to date with `staging` and respond to review comments.
   Maintainers squash-merge; a later `staging` → `main` PR ships it.

## 4. Reporting problems

Open a GitHub issue with what you expected, what happened, and how to reproduce
it. For anything involving credentials or a security issue, contact the
maintainer privately instead of filing a public issue.
