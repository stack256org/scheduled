# Solution: Release #1 fails at "Require a changelog entry for a release"

Paired bug report: [2026-08-24-bug-release-missing-changelog-section.md](./2026-08-24-bug-release-missing-changelog-section.md)

## What changed

- [CHANGELOG.md](../../CHANGELOG.md): added a `## [0.1.0] - 2026-08-24`
  section under a now-empty `## [Unreleased]`, containing the existing
  "initial self-hosted release" notes that had been sitting under
  `[Unreleased]`. Rewrote the stale intro paragraph ("This project doesn't
  yet follow semantic versioning... everything lives under
  **[Unreleased]**") to describe the real, now-active convention: each
  `## [<version>]` section corresponds to a tagged release cut by
  `.github/workflows/release.yml`.
- `.github/workflows/release.yml`, step **Extract the changelog section**:
  changed the `awk` stop condition from `index($0, "## [") == 1` to
  `index($0, "## ") == 1`, so it also stops at the `## Earlier history`
  footer heading, not only at another version heading. Previously nothing
  after `## [0.1.0]` would ever stop the extractor, so the entire "Earlier
  history" footer would have been appended to the GitHub Release body for
  whatever the newest release was — this was latent (never exercised)
  because no release had ever gotten past the changelog gate before.
- [README.md](../../README.md): regenerated via `node
  scripts/sync-readme.mjs` (the generated quick-start block now switches
  from "no tagged release yet" prose to a version-pinned `docker pull`
  block for `0.1.0`, per the gate that script already enforces — see
  [2026-08-24-solution-ghcr-owner-mismatch.md](./2026-08-24-solution-ghcr-owner-mismatch.md)).

## Why this fixes the root cause

The release workflow's gate (`grep -q "^## \[$version\]" CHANGELOG.md`)
now finds a real `## [0.1.0]` section, so **Require a changelog entry for a
release** passes and the pipeline proceeds to build/publish/tag. The awk
fix ensures the GitHub Release body created from that section is just the
0.1.0 notes, not the notes plus an unrelated footer.

## How it was verified

- `node scripts/sync-readme.mjs --check` → failed first (`README.md is out
  of date for version 0.1.0`), confirming the CHANGELOG.md change was
  correctly detected; then `node scripts/sync-readme.mjs` (no `--check`)
  regenerated it and the check re-run passed: `README.md is in step with
  package.json (0.1.0)`.
- Manually traced the release job's `grep -q "^## \[0.1.0\]"
  CHANGELOG.md` against the new file — matches.
- Manually traced the fixed `awk` extractor against the new CHANGELOG.md:
  starts at `## [0.1.0] - 2026-08-24`, now correctly stops at `## Earlier
  history` instead of running to end of file.
- `pnpm typecheck` was attempted but the local `tsc` process ran out of
  heap (pre-existing environment limit, unrelated — this change touched no
  TypeScript files, only `CHANGELOG.md`, `README.md`, and `release.yml`).
