# Bug: `worker` container can start before database migrations finish

**Date:** 2026-07-24
**Area:** Docker Compose startup ordering (`docker-compose.yml`, `docker-compose.external-db.yml`)
**Files:**
- [docker-compose.yml](../../docker-compose.yml)
- [docker-compose.external-db.yml](../../docker-compose.external-db.yml)
- [docker/entrypoint.sh](../../docker/entrypoint.sh) (removed)

## Symptom
On a fresh deploy or a deploy that adds new migrations, the `worker` container
could start and begin querying the database before migrations had finished
applying — since migrations only ran inside the `web` container's entrypoint,
and `worker` only waited on `postgres: service_healthy`, not on `web`
finishing its migration step.

## How reproduced
Not run against real Docker (unavailable in this environment), confirmed by
reading the compose dependency graph:
- `web`'s old `docker/entrypoint.sh` ran `pnpm db:migrate` before `exec`-ing
  `node server.js` — migrations were tied to `web`'s boot, not a separate,
  ordered step.
- `worker`'s `depends_on` only listed `postgres: condition: service_healthy`.
  Nothing gated `worker` on `web` completing its migration step, so on a
  fresh `docker compose up -d`, `worker` could start querying tables that
  `web`'s entrypoint hadn't created/altered yet. `restart: unless-stopped`
  would eventually recover it after a crash-loop, but that's a noisy,
  non-deterministic first boot rather than a guaranteed-correct one.

## Root cause
Migrations were coupled to the `web` container's own boot sequence instead of
being a distinct, ordered step that every service depending on the schema
waits on. A comparable project (Kanbanica) avoids this with a dedicated
`migrate` service that both `app` and `worker` gate on via
`depends_on: migrate: condition: service_completed_successfully` — Schduled
had no equivalent gate for `worker`.
