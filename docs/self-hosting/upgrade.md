# Upgrade Guide

## Before you upgrade — back up

**Always back up before upgrading.** This isn't a suggestion — it's the
actual rollback mechanism (see "If something breaks" below). See
[Backup](./backup.md) for the exact commands. At minimum:

```bash
pg_dump "$DATABASE_URL" -Fc -f pre-upgrade-$(date +%F).dump
```

## Docker Compose path

**Pulling published images** (`docker-compose.yml` /
`docker-compose.external-db.yml` — the default):
```bash
# optionally pin a version first: set IMAGE_TAG=1.0.1 (or newer) in .env
docker compose pull            # pull the new web + worker images
docker compose up -d           # recreates containers; migrate runs before web/worker start
docker compose logs -f migrate # confirm migrations applied cleanly, exits 0
curl http://localhost:3000/api/health   # confirm {"status":"ok"}
```

**Building from source** (`docker-compose.build.yml`):
```bash
git pull                                          # or update to the new release/tag
docker compose -f docker-compose.build.yml build  # rebuild migrate + web + worker images
docker compose -f docker-compose.build.yml up -d  # recreates containers; migrate runs first
docker compose -f docker-compose.build.yml logs -f migrate
curl http://localhost:3000/api/health   # confirm {"status":"ok"}
```

Either way, migrations run once via a dedicated `migrate` service, which
`web` and `worker` wait on
(`depends_on: migrate: condition: service_completed_successfully`) before
starting — there's no separate manual migration step on this path.

## Manual / Node path

```bash
git pull
pnpm install --frozen-lockfile
pnpm db:migrate
pnpm build
```
Then restart both processes (`systemctl restart schduled-web schduled-worker`
if you followed the [Installation Guide](./installation.md)'s systemd setup,
or restart your process manager of choice).

## Checking what changed

- [`CHANGELOG.md`](../../CHANGELOG.md) — human-readable summary of notable changes.
- `git log --oneline <old-commit>..<new-commit>` — full commit history for the range.
- `/api/version` on the *old* running instance tells you exactly what commit
  you're upgrading from, if you didn't note it down.

## Migrations are forward-only — there is no automated rollback

Drizzle's migration system (`pnpm db:migrate`) applies schema changes
forward only. There is no `db:migrate:down` command and no automated way to
reverse a migration once it's applied.

**If a migration causes a problem, the actual rollback procedure is:**

1. Stop the app (`docker compose down`, or stop the systemd services).
2. Restore the pre-upgrade database backup (see [Restore](./restore.md)):
   ```bash
   pg_restore -d "$DATABASE_URL" --clean --if-exists pre-upgrade-<date>.dump
   ```
3. Redeploy the *previous* image tag / git commit (this is why noting the
   commit or tag you're upgrading *from* matters — check `/api/version`
   before you upgrade, or just note the git SHA).
4. Start the app again.

This is why the backup step above isn't optional — it's the only way back.

## If something breaks after an upgrade

1. Check `docker compose logs web worker` (or your systemd journal) for the
   actual error — most issues surface immediately on boot (migration
   failure, a newly-required env var missing, etc.).
2. Check [`ENVIRONMENT.md`](../../ENVIRONMENT.md) for any new environment
   variables introduced since your version — `lib/env.ts` validates
   everything at boot and will name exactly which variable is missing or
   invalid, and refuse to start rather than fail confusingly later.
3. If it's a database migration problem specifically, follow the rollback
   procedure above.
4. If you're stuck, open an issue with your `/api/version` output (from
   before the upgrade, if you have it) and the relevant log lines.
