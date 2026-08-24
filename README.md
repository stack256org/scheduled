# Schduled

**A smart scheduling platform you host yourself.**

Share a booking link, set your availability, and let invitees pick a time — no
back-and-forth. Runs on your own server, on your own database.

[![CI](https://github.com/stack256org/scheduled/actions/workflows/ci.yml/badge.svg)](https://github.com/stack256org/scheduled/actions/workflows/ci.yml)
[![Release](https://github.com/stack256org/scheduled/actions/workflows/release.yml/badge.svg)](https://github.com/stack256org/scheduled/actions/workflows/release.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

- Next.js App Router UI
- Postgres and Drizzle ORM
- Better Auth — magic-link, email + password, and Google login
- pg-boss background worker queues
- Durable email outbox via SMTP (nodemailer)
- Admin-only screens (users, queue state, email visibility) built into the dashboard, gated by role
- S3/R2-compatible file storage (or local disk)
- Self-hostable — Docker Compose or manual/Node deploy

## Contents

- [Quick start](#quick-start)
- [Running it with Docker](#running-it-with-docker)
- [Deploying somewhere else](#deploying-somewhere-else)
- [Environment variables](#environment-variables)
- [Health checks](#health-checks)
- [Backups](#backups)
- [Roles](#roles)
- [CI & releases](#ci--releases)
- [Documentation](#documentation)
- [Structure](#structure)
- [Contributing](#contributing)
- [License](#license)

---

## Quick start

### Self-hosting (production / your own server)

See **[SELF-HOSTING.md](./SELF-HOSTING.md)** for the full guide, and
**[ENVIRONMENT.md](./ENVIRONMENT.md)** for every environment variable
(what it does, whether it's required, how to obtain it). Quick version:

<!-- BEGIN GENERATED: quick-start -->
```bash
curl -O https://raw.githubusercontent.com/stack256org/scheduled/main/docker-compose.yml
curl -o .env https://raw.githubusercontent.com/stack256org/scheduled/main/.env.docker.example
# set APP_SECRET, APP_URL, and (recommended) INITIAL_ADMIN_EMAIL
IMAGE_TAG=0.1.0 docker compose up -d
```

This pulls prebuilt, published images (multi-arch: Intel + ARM) rather than
building on your server. Pin a version in production, because `latest`
moves with every release — available tags are `latest`, the `0` /
`0.1` / `0.1.0` ladder, `main` (rebuilt on every change, expect
rough edges), and a fixed `sha-<short>` per build:

```bash
docker pull ghcr.io/stack256org/schduled:0.1.0
docker pull ghcr.io/stack256org/schduled-worker:0.1.0
```
<!-- END GENERATED: quick-start -->

<sub>The block above is generated from `package.json`'s `version` (and
whether `CHANGELOG.md` has a matching release section) by
`scripts/sync-readme.mjs`, and CI fails if it drifts — see
[CI & releases](#ci--releases). Run `pnpm docs:sync` after a version bump
rather than editing it by hand.</sub>

Already have a Postgres database (managed service, or your own instance)?
Use `docker compose -f docker-compose.external-db.yml up -d` instead — see
[Running it with Docker](#running-it-with-docker). Changed the code and need
to build locally instead of pulling? Use `docker-compose.build.yml`.

The full guide set lives in [`docs/self-hosting/`](./docs/self-hosting/):
[Installation](./docs/self-hosting/installation.md) ·
[Docker](./docs/self-hosting/docker.md) ·
[Upgrade](./docs/self-hosting/upgrade.md) ·
[Backup](./docs/self-hosting/backup.md) ·
[Restore](./docs/self-hosting/restore.md) ·
[Configuration](./docs/self-hosting/configuration.md) ·
[Integrations](./docs/self-hosting/integrations.md).

### Local development (working on Schduled itself)

```bash
corepack enable
pnpm install
cp .env.example .env
pnpm db:local       # starts a throwaway embedded Postgres — dev only
pnpm db:migrate
pnpm dev            # runs the web app + background worker together
```

Open `http://localhost:3000` — on a fresh (empty) database you're redirected
straight to the **setup wizard** at `/setup`, which creates your admin
account in one step (pick an appearance, set a name/email/password, you're
signed in). No separate promote step needed.

Prefer a magic link, or already have a non-admin account to promote?

```bash
pnpm make:admin you@example.com
```

Without `SMTP_HOST`, `SMTP_USER`, and `SMTP_PASS`, the worker logs emails to
the console instead of sending them.

📖 Full step-by-step walkthrough (with troubleshooting): **[SETUP.md](./SETUP.md)**.

---

## Running it with Docker

Two images are built from this repo and published to GitHub Container
Registry — see [CI & releases](#ci--releases) for how they get there:

| Image | Dockerfile | Published as | Purpose |
|---|---|---|---|
| `web` | `Dockerfile` | `ghcr.io/stack256org/schduled` | The Next.js server (`output: 'standalone'`) — serves traffic once the database is migrated |
| `worker` | `Dockerfile.worker` | `ghcr.io/stack256org/schduled-worker` | The background job processor (pg-boss) — emails, reminders, calendar sync. **Nothing sends without it.** |

Both run as a non-root `app` user and connect to the same Postgres database —
that's the only thing they share. Migrations run in a dedicated one-shot
`migrate` service (the worker image, command overridden) before `web`/`worker`
start, so neither image runs migrations itself.

Three compose files. Pick **one** — they're alternatives, never used together:

| File | Images | Bundled Postgres | Use when |
|---|---|---|---|
| `docker-compose.yml` | **pulled** | yes | **Recommended default.** No local build, works on a small VPS. |
| `docker-compose.external-db.yml` | pulled | no | You already have a Postgres (managed service or your own). |
| `docker-compose.build.yml` | **built locally** from `Dockerfile` / `Dockerfile.worker` | yes | You changed the code, or no published image is available yet. |

```bash
# Recommended default
curl -O https://raw.githubusercontent.com/stack256org/scheduled/main/docker-compose.yml
curl -o .env https://raw.githubusercontent.com/stack256org/scheduled/main/.env.docker.example
# set APP_SECRET, APP_URL, and (recommended) INITIAL_ADMIN_EMAIL
docker compose up -d

# Bring your own Postgres instead
docker compose -f docker-compose.external-db.yml up -d

# Build from source instead of pulling
docker compose -f docker-compose.build.yml up -d
```

Useful day-to-day commands:

```bash
docker compose logs -f migrate      # confirm migrations applied cleanly
docker compose logs -f web worker   # tail logs
docker compose ps                   # check health status
docker compose down                 # stop it. Your data stays.
```

### Volumes

| Volume | Used by | Purpose |
|---|---|---|
| `schduled_postgres_data` | `postgres` | Database files — your actual data. Back it up. **Bundled compose files only** — doesn't exist in `docker-compose.external-db.yml`. |
| `schduled_uploads` | `web` | Avatar/logo uploads, **only when `STORAGE_DRIVER=local`** (the default). Unused if `STORAGE_DRIVER=s3`. |

Both names are pinned literally in every compose file (not derived from your
clone directory), so a deploy tool that doesn't keep the compose project name
stable can't silently create a new, empty volume and orphan your data. They
survive `down`, `pull`, `build`, and `up -d` — only `down -v` destroys them.

### Healthchecks

- `web` hits its own `GET /api/health`, which runs a real query against
  Postgres, not just "is the process alive." See [Health checks](#health-checks).
- `worker` has a `HEALTHCHECK` in `Dockerfile.worker` that checks a heartbeat
  file the worker writes every 15 seconds — this catches a wedged event loop
  a plain "is the process running" check would miss.
- `postgres` (bundled compose files only) uses `pg_isready`, so `web`/`worker`
  don't start against a not-yet-ready database.

### Updating

```bash
docker compose pull
docker compose up -d
```

The `migrate` service applies any database changes before `web`/`worker` come
back — safe to run repeatedly, since it applies only what's new. Back up
first anyway; [docs/self-hosting/backup.md](./docs/self-hosting/backup.md) and
[docs/self-hosting/upgrade.md](./docs/self-hosting/upgrade.md) have the full
procedure.

> **To change the port,** use `HOST_PORT=8080 docker compose up -d`, never
> `PORT` — `env_file: .env` passes every variable into the container, and the
> app itself listens on `PORT` internally, so setting that would also move
> the container's internal bind port and break the health check.

Full reference — resource sizing, building images without Compose, the
`sharp`/native-build note for ARM — in
[docs/self-hosting/docker.md](./docs/self-hosting/docker.md).

---

## Deploying somewhere else

### Anything that runs a container

Coolify, Dokploy, CapRover, Portainer, Kubernetes, Docker Swarm, ECS. Point
them at `ghcr.io/stack256org/schduled` (web) and
`ghcr.io/stack256org/schduled-worker` (worker), and run three services:

| Service | Image | Command | Notes |
|---|---|---|---|
| web | `schduled` | `pnpm start` | Serves on port 3000. Probe `GET /api/health`. |
| worker | `schduled-worker` | `pnpm worker:start` | No web port. **Email and background jobs don't run without it.** |
| migrate | `schduled-worker` | `pnpm db:migrate:docker` | Run once, to completion, before the other two on each deploy. |

On the default `local` storage setting, mount a permanent volume at
`/app/uploads` on the `web` service. S3 and R2 need none.

### A plain server (no Docker)

1. Install Node.js 22+, PostgreSQL 15/16, and pnpm (`corepack enable`).
2. Clone the repository, run `pnpm install`, and set up `.env` — see
   [ENVIRONMENT.md](./ENVIRONMENT.md).
3. Build and migrate:
   ```bash
   pnpm build
   pnpm db:migrate
   ```
4. Keep **two** processes running, with systemd, PM2, or similar:
   ```bash
   pnpm start            # the app on :3000
   pnpm worker:start     # the background worker for email and jobs
   ```
5. Put Nginx or Caddy in front for HTTPS, forwarding to `:3000`.

---

## Environment variables

Only `DATABASE_URL`, `APP_SECRET`, and `APP_URL` are required to boot;
everything else is optional and has a sensible default. Full reference,
including how to obtain each credential and self-hosted alternatives, is in
**[ENVIRONMENT.md](./ENVIRONMENT.md)**; templates are
[`.env.example`](./.env.example) (local dev) and
[`.env.docker.example`](./.env.docker.example) (Docker).

| Variable | Required? | What it does |
|---|---|---|
| `DATABASE_URL` | **Yes** | PostgreSQL connection string. |
| `APP_SECRET` | **Yes** | Random secret used to sign sessions. 32+ characters — `openssl rand -hex 32`. |
| `APP_URL` | **Yes in production** | The public `https://` address of your install. Read live at runtime (not baked into the build), so every email link and OAuth redirect resolves correctly behind a reverse proxy. |
| `INITIAL_ADMIN_EMAIL` | Recommended | Auto-promoted to admin the moment that email signs up. |
| `ALLOW_PUBLIC_SIGNUP` | Recommended | `false` closes public sign-up; `INITIAL_ADMIN_EMAIL` is exempt. |
| `SMTP_HOST` / `SMTP_USER` / `SMTP_PASS` | Optional | Outgoing email. Without it, emails are logged to the worker console instead of sent. |
| `GOOGLE_CLIENT_ID` / `GOOGLE_CLIENT_SECRET` | Optional | Google sign-in and Calendar sync. Requires `ENCRYPT_KEY`. |
| `ZOOM_CLIENT_ID` / `ZOOM_CLIENT_SECRET` | Optional | Zoom video links on bookings. Requires `ENCRYPT_KEY`. |
| `ENCRYPT_KEY` | Conditional | AES key for stored OAuth tokens — required the moment Google or Zoom OAuth is configured. `openssl rand -hex 32`. |
| `STORAGE_DRIVER` | Optional | `local` (default), `s3`, or `r2` — see [ENVIRONMENT.md](./ENVIRONMENT.md) for the matching `S3_*`/`R2_*` variables. |

All of the above (SMTP, Google, Zoom, storage) can also be configured **from
inside the app** instead of environment variables — the setup wizard, or
**Settings → Services** afterward. A value saved there always wins over the
matching env var. See
[docs/self-hosting/integrations.md](./docs/self-hosting/integrations.md).

Config is validated at boot by [`lib/env.ts`](./lib/env.ts); a missing or
invalid required variable makes the app refuse to start and print exactly
which one failed, rather than breaking at runtime.

---

## Health checks

`GET /api/health` needs no authentication and reports whether the app can
reach its database:

```bash
curl http://localhost:3000/api/health
# {"status":"ok"}
```

It returns `503` with `{"status":"error"}` when the database is unreachable,
so load balancers and uptime monitors can use it directly — the underlying
error goes to the server log, never into the response.

`GET /api/version` reports the running build:

```bash
curl http://localhost:3000/api/version
# {"name":"schduled","version":"0.1.0","gitSha":"a1b2c3d"}
```

`gitSha` is `"unknown"` unless the image was built with
`--build-arg GIT_SHA=$(git rev-parse --short HEAD)` — the published images
from [CI & releases](#ci--releases) always set it.

---

## Backups

Backups are not automatic. Back up the **Postgres database** always, and the
`schduled_uploads` **volume** too if you're on the default `local` storage
driver (not needed on S3/R2). Full commands, a cron example, and restore
steps: [docs/self-hosting/backup.md](./docs/self-hosting/backup.md) and
[docs/self-hosting/restore.md](./docs/self-hosting/restore.md).

---

## Roles

| Role | How someone gets it |
|---|---|
| Admin | `INITIAL_ADMIN_EMAIL` on first signup, promoted by another admin, or from the command line. |
| User | Signs up normally (if `ALLOW_PUBLIC_SIGNUP=true`) or is invited. |

To promote someone from the command line:

```bash
# Docker
docker compose run --rm web pnpm make:admin them@example.com

# Running from source
pnpm make:admin them@example.com
```

Admin-only screens (users, audit log, queue state, platform settings) live
under `/settings/*`, gated by `requireAdmin()` — no separate admin panel or
login.

---

## CI & releases

Two workflows, chained so a red build never publishes anything:

**[`.github/workflows/ci.yml`](./.github/workflows/ci.yml)** runs on every
push to `main` and every pull request:

- `build` — typecheck, test, `next build`, and (report-only, not yet
  blocking) lint + dependency audit.
- `migrations` — applies every migration against a fresh database, then
  fails the build if `db/schema` changed without a committed migration
  (`pnpm db:generate`). This is the failure mode that breaks self-hosters
  most often: a schema change with no matching migration means
  `docker compose up` dies in the one-shot `migrate` service on a fresh
  install.

**[`.github/workflows/release.yml`](./.github/workflows/release.yml)** runs
after CI succeeds on `main` (never at the same time as CI, so a build can't
publish from a commit whose tests are still running or already failed):

1. Builds `web` and `worker` — two separate images, since they scale and
   restart independently — for `linux/amd64` **and** `linux/arm64`.
2. Publishes both to `ghcr.io/stack256org/schduled{,-worker}`, tagged
   `main` and `sha-<short>` on every push.
3. If `package.json`'s `version` has no matching `v<version>` git tag yet,
   the push is treated as a **release**: it additionally publishes the
   version ladder (`X`, `X.Y`, `X.Y.Z`, `latest`), creates the `v<version>`
   tag, and opens a GitHub Release using the matching `## [<version>]`
   section of [CHANGELOG.md](./CHANGELOG.md) — required, or the release step
   fails.
4. `verify-public` checks, **signed out**, that a customer could actually
   `docker pull` what was just published — GHCR packages default to private
   on first publish even in a public repo, and this is what turns the run
   red if nobody's flipped the visibility toggle yet.

So cutting a release is: bump `version` in `package.json`, add the matching
`## [x.y.z]` section to `CHANGELOG.md`, commit, push to `main`. Nothing to
tag by hand.

Version and current git commit are exposed at `/api/version` on a running
instance — see [Health checks](#health-checks). **No tagged release exists
yet** — until one does, `docker compose up -d` needs `IMAGE_TAG=main` (see
[Quick start](#quick-start)).

---

## Documentation

The full self-hosting guide set lives in
[`docs/self-hosting/`](./docs/self-hosting/):

| Topic | Document |
|---|---|
| Installation, start to finish | [installation.md](./docs/self-hosting/installation.md) |
| Docker images, compose files, volumes | [docker.md](./docs/self-hosting/docker.md) |
| Upgrading an existing install | [upgrade.md](./docs/self-hosting/upgrade.md) |
| Backing up | [backup.md](./docs/self-hosting/backup.md) |
| Restoring | [restore.md](./docs/self-hosting/restore.md) |
| Every configuration option | [configuration.md](./docs/self-hosting/configuration.md) |
| SMTP / Google / Zoom / storage from the app | [integrations.md](./docs/self-hosting/integrations.md) |

See also [docs/project-structure.md](./docs/project-structure.md) for the
full project layout, and [SETUP.md](./SETUP.md) for local development.

---

## Structure

- `app/` — public landing, auth, user dashboard (including admin-only settings tabs), booking pages, and API routes
- `db/schema/` — all database table definitions
- `lib/auth.ts` — Better Auth configuration (magic link, password, Google OAuth)
- `lib/email/` — persists outbound email before enqueueing work
- `lib/worker/` — pg-boss queues and job handlers
- `components/` — shared UI kit and scaffold shell
- `docs/self-hosting/` — the self-hosting guide set
- `scripts/sync-readme.mjs` — keeps this file's [Quick start](#quick-start) block in step with `package.json`'s version (`pnpm docs:check` / `docs:sync`)

See [docs/project-structure.md](./docs/project-structure.md) for the full
project layout.

---

## Contributing

See [CONTRIBUTING.md](./CONTRIBUTING.md) for coding conventions and the PR
checklist before submitting changes, [CODE_OF_CONDUCT.md](./CODE_OF_CONDUCT.md)
for community expectations, and [SECURITY.md](./SECURITY.md) to report a
vulnerability rather than opening a public issue.

---

## License

MIT — see [LICENSE](./LICENSE) for details.
