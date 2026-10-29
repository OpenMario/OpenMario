---
description: Check the current branch and open a pull request into staging using the project template
---

Prepare and open a PR following CONTRIBUTING.md.

1. Confirm the branch is not `main` or `staging` and is named
   `feat/…`, `fix/…`, or `chore/…`. If it is on `staging`/`main`, create a branch
   first. Make sure the diff contains only this change (no `.env`, dumps, or
   unrelated formatting churn).
2. Run `bun run fmt`, then the builds for every app you touched
   (`bun run server:build`, `bun run client:build`, mcp if shared packages
   changed). If something fails, fix it or say so in the PR.
3. If the schema changed, confirm a generated migration is committed.
4. Commit with a short imperative message (`fix: …`, `feat: …`, `chore: …`).
5. Show the user the title and body you will use, filled from
   `.github/pull_request_template.md`, with honest "How I tested" and "Not
   verified" sections. Wait for their OK.
6. Only then push and run `gh pr create --base staging`.
