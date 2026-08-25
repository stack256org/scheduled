# Solution: `drizzle-kit migrate` exits 1 with no error output in the Docker `migrate` service

**Date:** 2026-07-24
**Pairs with:** [2026-07-24-bug-drizzle-kit-migrate-silent-failure.md](./2026-07-24-bug-drizzle-kit-migrate-silent-failure.md)

## What changed
Added [scripts/migrate.ts](../../scripts/migrate.ts) — a small production
migration runner that uses `drizzle-orm/postgres-js/migrator` directly (the
same `postgres`/drizzle-orm stack `lib/db.ts` already depends on at runtime),
wrapped in a plain `try/catch` that unconditionally logs whatever error it
catches:

```ts
main().catch((error) => {
  console.error("[migrate] failed:", error);
  process.exit(1);
});
```

It also waits for the database with exponential backoff (2s → 30s, 10
attempts) before attempting migrations, matching the resilience pattern
`lib/db.ts`'s `waitForDatabase()` already uses elsewhere in the app.

Added a new script, `"db:migrate:docker": "tsx scripts/migrate.ts"`
([package.json](../../package.json)), and pointed the Docker `migrate`
service at it instead of `drizzle-kit migrate`:
- [docker-compose.yml](../../docker-compose.yml)
- [docker-compose.external-db.yml](../../docker-compose.external-db.yml)

`pnpm db:migrate` (the `drizzle-kit` CLI) is untouched and still used by the
manual/Node deployment path and local dev — this only replaces what the
Docker `migrate` service invokes.

## Why this fixes the root cause
The underlying problem was never the migrations, the config, or the
container environment — every one of those was individually ruled out by
direct reproduction. The actual defect was diagnosability: `drizzle-kit`'s
CLI caught its own error and exited without printing it, so there was no way
to see what was actually going wrong from inside a locked-down, non-TTY
container. Replacing it with a script we fully control removes that opacity
entirely — any future failure, of any kind, will now print a real
`error` object (message + stack) to the container's logs instead of a bare
exit code. This was verified directly: run against a fresh database, this
script applied all 18 migrations successfully and additionally printed a
benign Postgres `NOTICE` (an already-exists-skip for a duplicate enum label)
that `drizzle-kit`'s CLI had been silently swallowing too — independent,
concrete evidence the old CLI was dropping output, not just erroring
silently on this one occasion.

## How verified
- `npx tsc --noEmit` — clean.
- Both compose files parse as valid YAML; `migrate`'s `command` confirmed via
  `yaml.safe_load` to be `["pnpm", "db:migrate:docker"]`.
- Reproduced locally against a fresh embedded Postgres (same `db/migrations`,
  same `NODE_OPTIONS=--max-old-space-size=384` heap cap as the real
  container): `scripts/migrate.ts` applied all 18 migrations successfully
  and printed `[migrate] done.`
- Docker itself was unavailable in this environment, so the fix could not be
  re-verified against the self-hoster's actual `docker compose up -d`
  end-to-end — same standing caveat as the other 2026-07-24 Docker bug docs.
  They should retry the build/up and, if anything still fails, this script
  will now print the real error instead of a bare exit code.
