# syntax=docker/dockerfile:1

# ── Schduled — one image, three roles ─────────────────────────────────────────
# The same image runs the web app, the background worker, and the one-shot
# migration job; compose picks the role with `command:`
#
#   pnpm start               → the Next.js server
#   pnpm worker:start        → the pg-boss worker
#   pnpm db:migrate:docker   → apply migrations, then exit
#
# With NO command, scripts/docker-entrypoint.sh picks the role from
# SCHDULED_ROLE instead, defaulting to "all": migrate, then web server AND
# worker supervised in the one container. That is for platforms that deploy a
# registry image once and have no `command:` to set (Dokploy, Coolify, CapRover,
# a bare `docker run`) — without it such a deployment gets the web server alone:
# no migrations and no worker, so no email, reminder or calendar sync ever runs.
#
# That is why this image ships the real source tree and a real node_modules
# instead of Next's `output: "standalone"` bundle (and why there is no longer a
# separate worker image). The worker runs TypeScript through tsx,
# scripts/migrate.ts reads db/migrations off disk at runtime, and the admin
# recovery script (scripts/make-admin.ts) has to be callable inside a running
# container. A standalone build contains none of that, and needed a second image
# plus a hand-maintained copy of sharp's native libvips to work around its
# file-tracer. One image, no tracer.
#
# Runtime node_modules is a --prod install, so devDependencies stay out. tsx,
# drizzle-orm, drizzle-kit and next are all production dependencies.

FROM node:22-bookworm-slim AS base

ENV COREPACK_ENABLE_DOWNLOAD_PROMPT=0
# Corepack's default cache ($HOME/.cache/node/corepack) is per-user, and the
# non-root `app` user below has no home directory, so a `pnpm` call as `app`
# would try to download pnpm into a path it can't create (EACCES). Pinning
# COREPACK_HOME to a shared path and running `corepack prepare --activate` here,
# as root with network access, bakes the exact pnpm version from package.json's
# `packageManager` field into the image — `pnpm` never touches the network again.
ENV COREPACK_HOME=/opt/corepack
WORKDIR /app
COPY package.json ./
# The corepack bundled with node:22 images predates pnpm 12's binary layout and
# cannot launch it, so install a corepack that can before activating pnpm.
RUN npm install -g corepack@0.36.0 \
  && corepack enable \
  && corepack prepare --activate \
  && chmod -R a+rX "$COREPACK_HOME"


# ── Full dependency tree (devDependencies included) — build only ──────────────
FROM base AS deps

# pnpm-workspace.yaml is required here, not optional: pnpm 11 reads its
# `allowBuilds` allowlist from that file. Without it in the build context no
# package may run a postinstall script — including sharp, which needs one to
# place its libvips binary.
COPY pnpm-lock.yaml pnpm-workspace.yaml ./
RUN pnpm install --frozen-lockfile


# ── Production-only dependency tree — shipped to the runner ───────────────────
FROM base AS prod-deps

COPY pnpm-lock.yaml pnpm-workspace.yaml ./
RUN pnpm install --frozen-lockfile --prod


FROM base AS build

ENV NEXT_TELEMETRY_DISABLED=1
ENV NODE_OPTIONS="--max-old-space-size=6144"

# Placeholders so build-time env validation (lib/env.ts) passes. middleware.ts
# imports `env` eagerly, and Next.js bundles middleware during `next build` —
# without these, the build throws "Invalid environment variables" before it
# ever produces an image. `next build` also forces NODE_ENV=production
# internally (regardless of what's set here), which is why APP_URL needs a
# placeholder too: lib/env.ts requires it whenever NODE_ENV is "production".
#
# DATABASE_URL, APP_SECRET, and APP_URL are all safe to placeholder here
# because none of them are read at build time in any way that matters — they
# are NOT NEXT_PUBLIC_-prefixed, so Next.js never inlines them into the
# compiled bundle. They're read live from process.env at container runtime
# instead, so env_file/.env supplies the real values when the container
# starts and one built image works for any domain/database (see
# docker-compose.yml). Do NOT put the real production domain here.
#
# NEXT_PUBLIC_APP_URL is different and must stay a harmless placeholder only
# — Next.js inlines NEXT_PUBLIC_* vars into the compiled bundle (client AND
# server chunks) at `next build` time, so whatever is set here would stay
# frozen in the image forever. Nothing in the app actually reads it anymore;
# it's kept only because lib/env.ts still accepts it for backward
# compatibility with older .env files.
ENV DATABASE_URL="postgresql://build:build@localhost:5432/build"
ENV APP_SECRET="build-time-placeholder-value-000000000000"
ENV APP_URL="http://localhost:3000"
ENV NEXT_PUBLIC_APP_URL="http://localhost:3000"

COPY --from=deps /app/node_modules ./node_modules
COPY . .

RUN pnpm build


FROM base AS runner

ENV NODE_ENV=production
ENV NEXT_TELEMETRY_DISABLED=1
ENV PORT=3000
ENV HOSTNAME=0.0.0.0
# Caps V8's heap so an OOM shows up as a clean, restartable crash instead of
# the container being silently killed by the host's OOM killer. In the default
# "all" role the web server and the worker each get this cap. Raise it if your
# container's memory limit is higher than the default assumption below; the
# compose worker service lowers it to 384 since it serves no traffic.
ENV NODE_OPTIONS=--max-old-space-size=768

# Optional: docker build --build-arg GIT_SHA=$(git rev-parse --short HEAD)
# Surfaced at /api/version. Falls back to "unknown" if not passed.
ARG GIT_SHA=unknown
ENV GIT_SHA=$GIT_SHA

# uid/gid 1001 is deliberate and must not change: the `uploads` volume is
# chowned to it (see `init-uploads` in docker-compose.yml), so a redeploy keeps
# write access.
RUN groupadd --system --gid 1001 app \
  && useradd --system --uid 1001 --gid app app

# --chown on the COPYs rather than a trailing `chown -R`: it avoids duplicating
# the whole tree in an extra layer, and the runtime user genuinely needs write
# access to .next (the image-optimization cache lives at .next/cache).
COPY --chown=app:app . .
COPY --from=prod-deps --chown=app:app /app/node_modules ./node_modules
COPY --from=build --chown=app:app /app/.next ./.next

# The repo tracks shell scripts as mode 644 (no exec bit to inherit), so set it
# here rather than relying on the checkout.
RUN chmod +x /app/scripts/docker-entrypoint.sh

# Pre-create the uploads mount point (STORAGE_DRIVER=local, see
# docker-compose.yml's `uploads` volume) owned by `app` before it exists.
# Without this, /app/uploads doesn't exist in the image, so on first mount
# Docker creates it as root:root — the non-root `app` user below then gets
# EACCES on every upload.
RUN mkdir -p /app/uploads && chown -R app:app /app/uploads

USER app
EXPOSE 3000

# Role-aware (scripts/healthcheck.mjs): the web server's /api/health (a real
# query against Postgres), the worker's heartbeat file, or both in the default
# "all" role. docker-compose.yml overrides this per service.
#
# start-period covers the slowest legitimate boot: in the "all" role the web
# server starts only AFTER migrations have been applied, and the migration step
# waits for the database with backoff.
HEALTHCHECK --interval=30s --timeout=5s --start-period=90s --retries=3 \
  CMD ["node", "scripts/healthcheck.mjs"]

# Every explicit command (the `command:` of each docker-compose service, or
# `docker run <image> bash`) is exec'd verbatim by the entrypoint. "schduled" is
# a sentinel meaning "no command given — read SCHDULED_ROLE, default all". It
# must be a real value, not an empty CMD, or the base image's inherited
# `CMD ["node"]` would take its place.
ENTRYPOINT ["/app/scripts/docker-entrypoint.sh"]
CMD ["schduled"]

# OCI metadata. This is what renders on the GitHub Packages page, and what links
# the package back to this repository.
LABEL org.opencontainers.image.title="Schduled" \
      org.opencontainers.image.description="Self-hosted scheduling platform." \
      org.opencontainers.image.url="https://github.com/stack256org/scheduled" \
      org.opencontainers.image.source="https://github.com/stack256org/scheduled" \
      org.opencontainers.image.documentation="https://github.com/stack256org/scheduled#readme" \
      org.opencontainers.image.licenses="MIT" \
      org.opencontainers.image.vendor="Stack256"
