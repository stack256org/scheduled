# Docker Guide

Official docs: [Docker](https://docs.docker.com/) · [Docker Compose](https://docs.docker.com/compose/)

## Images

Two images are built from this repo:

| Image | Dockerfile | Published as | Purpose |
|---|---|---|---|
| `web` | `Dockerfile` | `ghcr.io/stack256org/schduled` | The Next.js server (`output: 'standalone'`) — serves traffic once the database is migrated |
| `worker` | `Dockerfile.worker` | `ghcr.io/stack256org/schduled-worker` | The background job processor (pg-boss) — emails, reminders, calendar sync |

Both run as a non-root `app` user, share the same `.env`, and connect to the
same PostgreSQL database — that's the only thing they share. No shared
filesystem is required between them (local file storage, if used, only
needs to be on the `web` container).

## Three compose files — pick one

| File | Images | Bundled Postgres | Use when |
|---|---|---|---|
| `docker-compose.yml` | **pulled** from `ghcr.io/stack256org/schduled` and `schduled-worker` | yes | Recommended default — no local build, works on a small VPS |
| `docker-compose.external-db.yml` | pulled | no | You already have a Postgres (managed service or your own) |
| `docker-compose.build.yml` | **built** from `Dockerfile` / `Dockerfile.worker` on your machine | yes | You changed the code, or no published image is available yet |

Only one of the three is ever run at a time.

## `docker-compose.yml` (pull, recommended)

```yaml
services:
  postgres:      # PostgreSQL 16, persisted to the postgres-data volume
  init-uploads:  # one-shot: fixes uploads volume ownership, then exits
  migrate:       # pulled worker image, command overridden to run migrations once
  web:           # pulled web image — the Next.js server
  worker:        # pulled worker image — the background job processor
```

It's intentionally **minimal** — no bundled reverse proxy, no bundled
object storage. Self-hosters are expected to bring their own TLS-terminating
proxy (Caddy/Traefik/nginx) and choose their own storage backend (local
volume, or an S3-compatible bucket via `STORAGE_DRIVER=s3`).

```bash
docker compose up -d              # pull + start everything; migrate runs first
docker compose logs -f migrate    # confirm migrations applied cleanly
docker compose logs -f web worker # tail logs
docker compose ps                 # check health status
docker compose down                # stop (keeps volumes)
```

**This repo hasn't cut its first tagged release yet** (see
[`CHANGELOG.md`](../../CHANGELOG.md) and
[`.github/workflows/release.yml`](../../.github/workflows/release.yml)) — the
`latest` tag won't exist until it has. Until then, pull the rolling `main`
build instead:
```bash
IMAGE_TAG=main docker compose up -d
```
Once a version is tagged, pin it in production (`IMAGE_TAG=1.0.0`) rather
than tracking `latest`, since `latest` moves on every release.

Migrations are not run by the `web` or `worker` images themselves — a
dedicated `migrate` service (the worker image, with its command overridden)
runs the migrator once and must exit successfully before `web`/`worker` start
(`depends_on: migrate: condition: service_completed_successfully`).

### `docker-compose.external-db.yml` — bring your own Postgres

If you already have a Postgres database (a managed service like Supabase,
Neon, or RDS, or an instance you run yourself), use this file instead — it
also pulls the published images, but runs only `init-uploads`, `migrate`,
`web`, and `worker`, no local `postgres` service or `postgres-data` volume:

```bash
docker compose -f docker-compose.external-db.yml up -d
```

Point `DATABASE_URL` at your database in `.env`; `POSTGRES_USER` /
`POSTGRES_PASSWORD` / `POSTGRES_DB` don't apply here (see "Path A2 — External
Postgres" in the [Installation guide](./installation.md)). Everything else on
this page — images, volumes, healthchecks for `web` and `worker`, resource
sizing — applies the same way; only the `postgres` service and its rows below
don't exist in this file.

### `docker-compose.build.yml` — build from source

Most self-hosters do **not** need this file — it compiles the whole app on
your machine, which on a small server is slow and memory-hungry. Use it if
you've changed the code, or the published images aren't public yet:

```bash
docker compose -f docker-compose.build.yml up -d
```

Same services and volumes as `docker-compose.yml`, but `migrate`/`web`/
`worker` are each built locally from `Dockerfile`/`Dockerfile.worker` instead
of pulled. Rebuild after pulling new code with
`docker compose -f docker-compose.build.yml build`.

### Volumes

| Volume | Used by | Purpose |
|---|---|---|
| `postgres-data` | `postgres` | Database files — this is your actual data. Back it up. **Bundled compose files only** — doesn't exist in `docker-compose.external-db.yml`, since your database lives outside Compose entirely. |
| `uploads` | `web`, `init-uploads` | Avatar/logo uploads, **only when `STORAGE_DRIVER=local`** (the default). Not used at all if `STORAGE_DRIVER=s3`. |

`init-uploads` is a one-shot service that runs before `migrate`/`web`/`worker`
and `chown`s the `uploads` volume to the app's non-root uid (1001), then
exits. It exists so a volume created before an image update went non-root
doesn't silently start failing uploads with `EACCES` — on a fresh volume it's
a no-op, so it's safe to run on every `up`.

The volume name is pinned in every compose file (`name: schduled_uploads`),
so it's always `schduled_uploads` regardless of your clone directory name.
Confirm with:
```bash
docker volume ls | grep uploads
```
The [Backup](./backup.md) and [Restore](./restore.md) guides' example
commands use this exact name.

### Healthchecks

- `postgres`: `pg_isready`, so `web`/`worker` don't start against a
  not-yet-ready database. **Bundled compose file only** — with
  `docker-compose.external-db.yml` there's no local database to gate on, so
  `web`/`worker` start immediately and rely on `restart: unless-stopped` to
  retry if your external database isn't reachable yet.
- `web`: hits its own `/api/health` endpoint, which does a real `SELECT 1`
  against Postgres — not just "is the process alive."
- `worker`: has a `HEALTHCHECK` in `Dockerfile.worker` that checks a
  heartbeat file the worker writes every 15 seconds
  (`scripts/worker.ts`) — this catches a wedged event loop that a plain
  "is the process running" check would miss.

## Building images directly (without compose)

```bash
docker build -t schduled-web -f Dockerfile .
docker build -t schduled-worker -f Dockerfile.worker .
```

To embed the git commit in `/api/version`:
```bash
docker build \
  --build-arg GIT_SHA=$(git rev-parse --short HEAD) \
  -t schduled-web -f Dockerfile .
```
`.git` itself is excluded from the build context (`.dockerignore`), so the
SHA has to be passed explicitly — it isn't read from inside the image.

## Where published images come from

`.github/workflows/release.yml` builds and pushes both images
(`linux/amd64` + `linux/arm64`) to GitHub Container Registry on every push to
`main` that passes CI:

- Every push publishes `ghcr.io/stack256org/schduled:main`,
  `ghcr.io/stack256org/schduled-worker:main`, and matching
  `sha-<short>` tags.
- A push where `package.json`'s `version` has no matching `v<version>` git
  tag yet is treated as a release: it additionally publishes the version
  ladder (`X`, `X.Y`, `X.Y.Z`, `latest`), creates the `v<version>` tag, and
  opens a GitHub Release using the matching `## [<version>]` section of
  [`CHANGELOG.md`](../../CHANGELOG.md) — required, or the release step fails.
- A separate `verify-public` job checks, anonymously, that a signed-out
  `docker pull` would actually succeed — GHCR packages default to **private**
  on their first publish even in a public repo, and that job is what catches
  it if nobody has flipped the visibility toggle yet (Repository → Packages →
  pick the package → Package settings → Change visibility → Public).

So cutting a release is: bump `version` in `package.json`, add the matching
`## [x.y.z]` section to `CHANGELOG.md`, commit, push to `main`. Nothing to
tag by hand.

## Resource sizing

Rough starting point for a small instance (a handful of users, low booking
volume). Scale up if you see OOM restarts or slow response times.

| Container | RAM | CPU | Notes |
|---|---|---|---|
| `web` | 512MB–1GB | 0.5–1 vCPU | `NODE_OPTIONS=--max-old-space-size=768` caps the heap so an OOM is a clean restart, not a silent kill |
| `worker` | 256–512MB | 0.25–0.5 vCPU | Lighter — no HTTP serving, just job processing. Heap capped at 384MB. |
| `postgres` | 512MB–2GB | 0.5–1 vCPU | Depends on data volume; the default `shared_buffers` etc. are fine for a small instance. Bundled compose file only — not applicable to `docker-compose.external-db.yml`, where sizing is your database provider's concern. |
| Disk | 10GB+ | — | Postgres data + uploads (if `STORAGE_DRIVER=local`) — grows with booking history and avatar count |

If you deploy on a memory-limited host (many VPS/PaaS platforms enforce a
hard container memory limit), make sure `NODE_OPTIONS`'s
`--max-old-space-size` value is comfortably *below* that limit, not above
it — V8's heap is only part of a Node process's total memory footprint.

### `sharp` and native builds

Avatar uploads are processed with `sharp`, a native (libvips-based)
dependency. The web `Dockerfile`'s builder stage runs a full `pnpm install`
(not `--prod`) specifically so `sharp` can pull whatever native binary or
build toolchain it needs for your target platform. If you're building on
**ARM64** (Raspberry Pi, Apple Silicon dev machines targeting ARM), expect a
slower first build while `sharp` fetches/builds ARM binaries — this is
normal, not a bug.

## Updating containers

See [Upgrade](./upgrade.md) for the full procedure (back up first). Short
version:

**Pulling published images** (`docker-compose.yml` /
`docker-compose.external-db.yml`):
```bash
docker compose pull
docker compose up -d
```

**Building from source** (`docker-compose.build.yml`):
```bash
git pull
docker compose -f docker-compose.build.yml build
docker compose -f docker-compose.build.yml up -d
```

Either way, migrations run automatically via the dedicated `migrate`
service, which `web`/`worker` wait on before starting.
