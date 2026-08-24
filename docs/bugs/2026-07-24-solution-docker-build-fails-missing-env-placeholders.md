# Solution: Docker image build fails — "Invalid environment variables"

**Date:** 2026-07-24
**Pairs with:** [2026-07-24-bug-docker-build-fails-missing-env-placeholders.md](./2026-07-24-bug-docker-build-fails-missing-env-placeholders.md)

## What changed
[Dockerfile:20-28](../../Dockerfile#L20-L28) — the `builder` stage now sets
placeholder values for the 3 unconditionally-required env fields before
running `pnpm build`:

```dockerfile
ENV DATABASE_URL="postgresql://build:build@localhost:5432/build"
ENV APP_SECRET="build-time-placeholder-value-000000000000"
ENV NEXT_PUBLIC_APP_URL="http://localhost:3000"
```

These are exactly the 3 fields confirmed (by scanning every top-level field
declaration in `lib/env.ts`'s schema) to lack a `.default()` or `.optional()`.
Every other field is either optional, defaulted, or only conditionally
required (`superRefine` — e.g. `ENCRYPT_KEY` only when Google/Zoom OAuth vars
are set, neither of which appears at build time).

## Why this fixes the root cause
The placeholders satisfy `lib/env.ts`'s Zod schema during `next build`, so
`middleware.ts`'s eager import no longer throws and the build completes. They
are **never used at runtime** — `docker-compose.yml`'s `web`/`worker`/`migrate`
services all set `env_file: .env`, which supplies the real values when the
container actually starts. This is also why one built image can serve any
domain/database without a rebuild: nothing deployment-specific is baked in,
only inert placeholders that get fully overridden at container start.

## How verified
- `npx tsc --noEmit` — clean.
- Confirmed via `node -e` that `z.url()` accepts the placeholder
  `http://localhost:3000`.
- Confirmed via a full scan of `lib/env.ts`'s schema fields that no other
  field is unconditionally required, so no fourth placeholder is needed.
- Docker itself was unavailable in this environment, so `docker build` was
  not run end-to-end — flagged in `SELF-HOSTING.md`/`ENVIRONMENT.md` as still
  needing a real `docker compose up -d --build` verification pass.
