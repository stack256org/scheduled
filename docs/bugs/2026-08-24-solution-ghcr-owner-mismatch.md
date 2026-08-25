# Solution: Docker/GHCR docs pointed at an owner that publishes nothing

Paired bug report: [2026-08-24-bug-ghcr-owner-mismatch.md](./2026-08-24-bug-ghcr-owner-mismatch.md)

## What changed

- Replaced every `sahajtavethiya96/Schduled` / `sahajtavethiya96/schduled`
  occurrence with `stack256org/scheduled` / `stack256org/schduled` across
  README.md, SELF-HOSTING.md, CHANGELOG.md, docker-compose.yml,
  docker-compose.external-db.yml, docs/self-hosting/docker.md, and
  docs/self-hosting/installation.md — matching the `upstream` git remote,
  per the user's choice (they're contributing to `stack256org`, the same org
  that owns `docket`). An intermediate pass briefly used `rajdhokai0928`
  (the `origin` fork) before the user corrected the target to `stack256org`.
- Added `LABEL org.opencontainers.image.*` metadata to both `Dockerfile` and
  `Dockerfile.worker` (title, description, url, source, documentation,
  licenses, vendor=`Stack256`), matching `docket`'s Dockerfile, and added
  the matching `org.opencontainers.image.vendor=Stack256` label to
  `release.yml`'s `docker/metadata-action` block, which previously omitted
  it (along with `url`/`source`/`documentation`, which only the Dockerfile
  itself carries). Previously only images built through `release.yml`
  carried any OCI labels at all; a locally built image
  (`docker-compose.build.yml`, or a bare `docker build`) had none.
- Ported `docket`'s drift-guard mechanism: `scripts/sync-readme.mjs` (new),
  `docs:sync` / `docs:check` npm scripts, and a `pnpm docs:check` CI step in
  `.github/workflows/ci.yml` (run before `pnpm install`, since it's a
  dependency-free plain-Node check). It regenerates a
  `<!-- BEGIN/END GENERATED: quick-start -->` block in README.md from
  `package.json`'s version and a single `OWNER_REPO`/`WEB_IMAGE`/
  `WORKER_IMAGE` constant, and — unlike `docket`'s script, which always shows
  a version ladder — only switches from the "no tagged release yet" prose to
  a version-pinned `docker pull` block once `CHANGELOG.md` actually carries a
  matching `## [<version>]` heading, mirroring the same gate
  `release.yml`'s "Require a changelog entry for a release" step enforces.
  This directly targets the failure mode above: the owner now lives in one
  place instead of being duplicated as literal text across seven files.

## Why this fixes the root cause

The docs no longer hand out URLs that 404. And going forward, any owner/repo
drift (or a version-ladder claim for a version that was never actually
tagged) is caught by `pnpm docs:check` in CI rather than shipping silently —
the same protection `docket` already had.

## How it was verified

- `node scripts/sync-readme.mjs --check` → `README.md is in step with
  package.json (0.1.0).`
- `pnpm typecheck` → clean, confirming the Dockerfile/docs-only changes
  didn't touch anything type-checked.
- `grep -rn "sahajtavethiya96"` across the repo → zero remaining matches.
