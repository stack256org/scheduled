# Bug: `drizzle-kit migrate` exits 1 with no error output in the Docker `migrate` service

**Date:** 2026-07-24
**Area:** Docker `migrate` service (`docker-compose.yml`, `docker-compose.external-db.yml`)
**Files:**
- [scripts/migrate.ts](../../scripts/migrate.ts) (new)
- [package.json](../../package.json)
- [docker-compose.yml](../../docker-compose.yml)
- [docker-compose.external-db.yml](../../docker-compose.external-db.yml)

## Symptom
After fixing the earlier build OOM, the prerender-hits-a-fake-database issue,
and the Corepack `EACCES` crash, the `migrate` service still failed on every
attempt:

```
$ drizzle-kit migrate --config=drizzle.config.ts
Reading config file '/app/drizzle.config.ts'
Using 'pg' driver for database querying
[⣷] applying migrations...[ELIFECYCLE] Command failed with exit code 1.
```

No error message, stack trace, or SQL detail — just the spinner dying and
pnpm's own generic wrapper line.

## How reproduced
Extensively diagnosed directly on the self-hoster's server plus local
reproduction against a fresh embedded Postgres:
- `dmesg`/`journalctl -k` showed no OOM kill.
- Running `migrate` in isolation (before `web`/`worker` even started) still
  failed — rules out resource contention from concurrent builds.
- `id` confirmed the expected non-root `app` user; disk had 11G free;
  migration files were readable (`cat` succeeded); a local reproduction here
  with the exact same `db/migrations`, `drizzle.config.ts`, drizzle-kit
  version, and `NODE_OPTIONS=--max-old-space-size=384` heap cap **succeeded
  cleanly** — ruling out the migrations' SQL content, config, missing
  `meta/*_snapshot.json` files, and the heap cap itself.
- Redirecting output to a plain file (not a pipe) produced the exact same
  silence — ruling out a stdout-buffering/`process.exit()`-before-flush race.
- The reported exit code was consistently `1` (not `137`/`139`/etc.), which
  rules out a signal-based kill (SIGKILL/SIGSEGV) — this is a deliberate,
  voluntary `process.exit(1)` somewhere inside drizzle-kit's own code, after
  catching whatever error occurred, without ever logging it.

## Root cause
`drizzle-kit@0.31.10`'s `migrate` CLI command swallows the underlying error
on failure in this environment — the exact internal cause wasn't fully
isolated (all external explanations were ruled out one by one), but the
practical conclusion is the same either way: an opaque third-party CLI with
no verbose/debug flag and no reliable way to surface its own errors is not
suitable for a production migration step where diagnosability matters. A
comparable project (Kanbanica) had already solved this exact class of
problem by running its own thin migration script against `drizzle-orm`'s
migrator directly instead of going through `drizzle-kit`'s CLI.
