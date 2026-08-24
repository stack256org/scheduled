# Bug: Docker image build fails — "Invalid environment variables"

**Date:** 2026-07-24
**Area:** Docker build (`Dockerfile`, builder stage)
**Files:**
- [Dockerfile](../../Dockerfile)
- [lib/env.ts](../../lib/env.ts)
- [middleware.ts](../../middleware.ts)

## Symptom
Running `docker build` (or `docker compose up -d --build`) on the `web` image
fails during the `pnpm build` step with `Invalid environment variables` before
an image is ever produced — the Docker deployment can't get off the ground at
all.

## How reproduced
Not yet run against real Docker (unavailable in this environment — see
`SELF-HOSTING.md`'s "Not yet verified live" note), but confirmed by static
trace:
1. `middleware.ts:2` imports `env` from `lib/env.ts` at module scope.
2. Next.js bundles `middleware.ts` as part of `next build` (it must be
   Edge-compatible and is always compiled), which evaluates that top-level
   import — including `lib/env.ts`'s `envSchema.safeParse(process.env)` call.
3. `lib/env.ts`'s schema requires `DATABASE_URL`, `APP_SECRET`, and
   `NEXT_PUBLIC_APP_URL` unconditionally — `z.string().min(1)` / `z.url()`,
   no `.default()`, no dev/build-phase bypass.
4. The `Dockerfile`'s `builder` stage runs `pnpm build` without setting any of
   those three — `.env` is `.dockerignore`d and never copied in — so
   `safeParse` fails and the module throws, aborting the build.

## Root cause
`lib/env.ts` was written to fail fast and always require real values for
those three fields — a reasonable runtime property, but it also fails during
`next build`, which evaluates modules like `middleware.ts` without any real
runtime environment configured yet. The Dockerfile never accounted for this:
unlike a comparable project (Kanbanica) whose `Dockerfile` sets build-time
placeholder values for exactly this reason, Schduled's builder stage set none.
