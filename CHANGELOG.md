# Changelog

All notable changes to this project are documented here.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project follows [Semantic Versioning](https://semver.org/). Every
`## [<version>]` section below corresponds to a tagged GitHub Release; see
`.github/workflows/release.yml`.

## [Unreleased]

## [0.2.0] - 2026-10-21

### Changed

- **One image instead of two.** The web server, the worker and the migration job now
  run from the single `ghcr.io/stack256org/schduled` image; `Dockerfile.worker` and the
  `schduled-worker` image are gone. The image ships the full source and a production
  `node_modules` instead of Next's `standalone` bundle (the worker needs `tsx`, and
  migrations need `db/migrations`, on disk). The compose files run the same image three
  times with a different `command:`. New releases are no longer published as
  `schduled-worker`; existing tags stay pullable.
- `scripts/migrate.ts` takes a `pg_advisory_lock`, so two overlapping deploys queue instead
  of racing to apply the same migration.
- **Dependencies updated** to current stable releases, including Next.js 16.4, React 19.3,
  TypeScript 7, `googleapis` 186, `motion` 14, `files-sdk` 3 and `nodemailer` 10. `better-auth`
  stays on the 1.6 line (1.7 needs an account-schema migration). Package manager is now
  pnpm 12.14.0; the `Dockerfile` installs corepack 0.36 so it can activate it.

### Fixed

- Dev console error "Encountered a script tag while rendering React component" from the
  theme provider.

### Documentation

- New "File storage and uploads" section in `docs/self-hosting/installation.md`: which
  deployments keep uploads automatically (Compose) and which need a volume or S3/R2 set up by
  hand (Dokploy Application, other Docker platforms, manual installs).

### Added

- **Single-container deploys now migrate and run the worker.** With no command, the image
  applies pending migrations, then runs the web server and one worker
  (`scripts/docker-entrypoint.sh`). Previously a platform that runs the image once (Dokploy,
  Coolify, `docker run`) started only the web server, so a release that added a column failed
  with a Server Components render error and no email or reminder ever ran. Pick a role with
  `SCHDULED_ROLE` (`all`/`app`/`worker`/`migrate`); skip migrations with
  `SCHDULED_RUN_MIGRATIONS=false`. Compose users are unaffected: an explicit `command:` passes
  straight through.
- `scripts/healthcheck.mjs`: a role-aware container healthcheck (web, worker heartbeat, or
  both).

### Upgrade notes

- **Compose users:** replace your compose file with the new one (or edit it): `migrate` and
  `worker` now use the `schduled` image, not `schduled-worker`, and `web` needs
  `command: ["pnpm", "start"]`. `SCHDULED_WEB_IMAGE` / `SCHDULED_WORKER_IMAGE` are replaced by
  a single `SCHDULED_IMAGE`.
- **Platform deployments:** if you set the command to `pnpm start` to work around the missing
  worker, clear it, or the entrypoint (and its auto-migrate) stays bypassed. Mount a volume at
  `/app/uploads` or use S3/R2.

## [0.1.0] - 2026-08-24

Initial self-hosted release.

### Added
- Self-hosted deployment support: `Dockerfile`, `docker-compose.yml`,
  migrate-on-boot entrypoint, `/api/health` (DB-backed) and a worker
  liveness heartbeat, `/api/version`.
- `docker-compose.external-db.yml` — an alternative to `docker-compose.yml`
  for self-hosters who already have a Postgres database (managed service or
  self-run) and don't want Compose to also run one.
- `ALLOW_PUBLIC_SIGNUP` — closes public account creation across all auth
  methods (password, magic link, Google) while exempting
  `INITIAL_ADMIN_EMAIL`, so self-hosted instances can be closed from the
  very first deploy.
- Dedicated "you don't have permission" denial screen on `/login` for
  Google sign-in attempts rejected because `ALLOW_PUBLIC_SIGNUP=false` and
  the account doesn't already exist.
- `NEXT_PUBLIC_PASSWORD_AUTH_ENABLED` and `INITIAL_ADMIN_EMAIL` — email +
  password login and first-run admin bootstrap for deployments without SMTP
  or Google configured yet.
- `NEXT_PUBLIC_LANDING_ENABLED` — optional marketing landing page; `false`
  redirects `/` to `/login` for internal/team deployments.
- S3/R2-compatible file storage driver (previously present but inert).
- `DB_POOL_MAX` and a startup connection retry for Postgres.
- White-labeling: `NEXT_PUBLIC_PRODUCT_NAME`, `NEXT_PUBLIC_SHOW_POWERED_BY`,
  `CONTACT_EMAIL`, `NEXT_PUBLIC_CONTACT_EMAIL`, `PRIVACY_EMAIL`.
- Security headers (CSP, HSTS, X-Frame-Options, Referrer-Policy,
  Permissions-Policy) via `next.config.mjs`.
- CI (GitHub Actions): typecheck + build on every PR; lint and dependency
  audit run informationally; a dedicated `migrations` job fails a PR whose
  schema changes shipped without a generated migration.
- Release pipeline (`.github/workflows/release.yml`): every push to `main`
  that passes CI publishes multi-arch (amd64+arm64) `web` and `worker`
  images to `ghcr.io/stack256org/schduled` and `schduled-worker`; a
  `package.json` version bump with a matching `CHANGELOG.md` section also
  tags a `v<version>` release and version-ladder image tags. A
  `verify-public` job checks the images are actually pullable signed-out.
- `docker-compose.yml` now **pulls** published images by default instead of
  building from source; `docker-compose.build.yml` (renamed from the
  previous `docker-compose.yml`) covers the build-from-source case, and
  `docker-compose.external-db.yml` was switched to pull images too. All
  three gained an `init-uploads` one-shot service that fixes the uploads
  volume's ownership before `migrate`/`web`/`worker` start, and a
  `HOST_PORT` override so the container's internal port can't be
  accidentally moved by `env_file`.
- `.env.docker.example` — a minimal Docker-specific env template (paired
  with the plain `docker-compose.yml` quick start).
- `SELF-HOSTING.md` and `ENVIRONMENT.md` — the self-hosting roadmap and
  full environment-variable reference.

### Changed
- Internal naming cleanup ahead of an eventual public release: the Docker
  container user, a hardcoded personal dev-tunnel origin, and an internal
  job name were renamed/genericized.

## Earlier history

Development before this changelog started is available in the git log —
see `git log --oneline` for the full commit history.
