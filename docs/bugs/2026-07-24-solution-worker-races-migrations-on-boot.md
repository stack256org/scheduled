# Solution: `worker` container can start before database migrations finish

**Date:** 2026-07-24
**Pairs with:** [2026-07-24-bug-worker-races-migrations-on-boot.md](./2026-07-24-bug-worker-races-migrations-on-boot.md)

## What changed
- **`docker-compose.yml`** — added a `migrate` service (builds from
  `Dockerfile.worker`, runs `["pnpm", "db:migrate"]`, `restart: "no"`, depends
  on `postgres: service_healthy`). Both `web` and `worker` now additionally
  depend on `migrate: condition: service_completed_successfully`.
- **`docker-compose.external-db.yml`** — same shape, minus the `postgres`
  dependency (no bundled database to gate on): `migrate` runs against
  `DATABASE_URL` directly with `restart: on-failure`, so if the external
  database isn't reachable yet it keeps retrying instead of failing
  permanently and blocking `web`/`worker` forever.
- **`Dockerfile.worker`** — now also copies `drizzle.config.ts`, since the
  `migrate` service (built from this same image) needs it for
  `pnpm db:migrate` (`drizzle-kit migrate --config=drizzle.config.ts`).
- **`Dockerfile`** (web image) — migration now happens exclusively in the
  `migrate` service, so the web runner stage no longer needs `drizzle-kit`,
  `drizzle.config.ts`, or `db/migrations` at runtime. Removed the extra
  `pnpm install --frozen-lockfile --prod` layer, the `db/` copy, and
  `docker/entrypoint.sh` — the image now relies purely on `.next/standalone`'s
  own self-contained `node_modules` and starts with a plain `CMD ["node", "server.js"]`.
- **`docker/entrypoint.sh`** — deleted (no longer referenced anywhere).
- Updated every doc that described the old migrate-on-boot behavior:
  `SELF-HOSTING.md`, `PROJECT_REVIEW.md`, `ENVIRONMENT.md`,
  `docs/project-structure.md`, `docs/self-hosting/installation.md`,
  `docs/self-hosting/upgrade.md`.

## Why this fixes the root cause
Migrations are now a single, ordered step every dependent service explicitly
waits on (`service_completed_successfully`), instead of being implicitly tied
to whichever container happens to boot first. `worker` can no longer start
ahead of a completed migration — Compose won't create the `worker` container
until `migrate` has exited 0. This also removes the possibility of multiple
replicas racing to run migrations concurrently, since `migrate` is a single
one-shot service rather than logic embedded in every `web` replica's boot.

## How verified
- `npx tsc --noEmit` — clean.
- Both compose files parse as valid YAML (`python3 -c "import yaml; ..."`),
  with the expected service sets: `postgres, migrate, web, worker` (bundled)
  and `migrate, web, worker` (external-db).
- Confirmed no remaining references to `docker/entrypoint.sh` or
  "migrate-on-boot" anywhere in the repo (`grep -rn` across `*.md`,
  `Dockerfile*`, `*.yml`).
- Docker itself was unavailable in this environment, so `docker compose up -d`
  was not run end-to-end — flagged in `SELF-HOSTING.md`/`ENVIRONMENT.md` as
  still needing a real verification pass.
