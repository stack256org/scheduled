# Bug: Docker/GHCR docs pointed at an owner that publishes nothing

**Where:** [README.md](../../README.md), [SELF-HOSTING.md](../../SELF-HOSTING.md),
[CHANGELOG.md](../../CHANGELOG.md), [docker-compose.yml](../../docker-compose.yml),
[docker-compose.external-db.yml](../../docker-compose.external-db.yml),
[docs/self-hosting/docker.md](../self-hosting/docker.md),
[docs/self-hosting/installation.md](../self-hosting/installation.md)

## What's broken

Every docker-related reference (GHCR image paths and `raw.githubusercontent.com`
curl commands) hardcoded the GitHub owner `sahajtavethiya96`, e.g.
`ghcr.io/sahajtavethiya96/schduled`. That owner matches neither git remote:

- `origin` → `rajdhokai0928/scheduled`
- `upstream` → `stack256org/scheduled`

`.github/workflows/release.yml` derives the image owner dynamically from
whichever repo actually runs the workflow (`GITHUB_REPOSITORY_OWNER`), so no
build was ever going to land under `sahajtavethiya96` regardless. Every
`docker pull` / `curl` command a self-hoster copied from these docs would 404
against a nonexistent namespace.

## How it was found

Comparing `scheduled`'s CI/Docker/release setup against the sibling `docket`
project (same stack, same org) at the user's request. `docket` has a
`pnpm docs:check` CI step (`scripts/sync-readme.mjs`) specifically built to
prevent this class of drift — its own commit history describes an identical
incident (a stale tag ladder in `docket`'s README that no release had
actually published). `scheduled` had no equivalent guard and, as it turned
out, the exact same failure mode already live in seven files.

## Root cause

`sahajtavethiya96` appears to be an unedited placeholder from wherever these
files were originally scaffolded/generated — it was never replaced with a
real owner (`origin` or `upstream`) once the repo was set up, and nothing in
CI checked it.
