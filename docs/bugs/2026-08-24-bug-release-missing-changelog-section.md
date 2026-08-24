# Bug: Release #1 fails at "Require a changelog entry for a release"

## What's broken

`.github/workflows/release.yml`, job **Check for a new version**, step
**Require a changelog entry for a release** — fails every run with:

```
Error: No '## [0.1.0]' section. Every release needs notes; that section
becomes the GitHub Release body.
Error: Process completed with exit code 1.
```

Reported via a screenshot of the failed "Release #1" run (2 errors, 1
warning in the annotations panel; the job fails in 6s at the changelog-gate
step, before any image build starts).

## How it was found

`package.json` carries `"version": "0.1.0"`. The release workflow's `check`
job treats any version with no existing `v<version>` git tag as a new
release, and gates it on `grep -q "^## \[$version\]" CHANGELOG.md`
(release.yml:120). [CHANGELOG.md](../../CHANGELOG.md) only had an
`## [Unreleased]` heading — no `## [0.1.0]` section existed — so the grep,
and the job, failed every time the release workflow ran.

## Root cause

`CHANGELOG.md` was never updated to cut an actual `0.1.0` section. Its intro
text still said "This project doesn't yet follow semantic versioning with
tagged releases... Until then, everything lives under **[Unreleased]**",
which was true early on but was left stale after `package.json`'s version
was bumped to `0.1.0` in anticipation of the first tagged release.

A second, latent bug was found while fixing this: the release job's notes
extractor (release.yml, step **Extract the changelog section**) is an `awk`
script that starts capturing at the `## [<version>]` heading and stops at
the next line starting with `## [`. Because `## Earlier history` (a
footer section, not a version) sits directly below the changelog's only
version section with no other `## [...]` heading between them, the
extractor would never find a stop condition and would append the entire
"Earlier history" footer into the GitHub Release body for whatever is
currently the newest release. This had never fired before because no
release had ever gotten past the changelog gate above.
