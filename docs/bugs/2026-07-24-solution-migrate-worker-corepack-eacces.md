# Solution: `migrate`/`worker` containers crash with `EACCES` trying to write Corepack's cache

**Date:** 2026-07-24
**Pairs with:** [2026-07-24-bug-migrate-worker-corepack-eacces.md](./2026-07-24-bug-migrate-worker-corepack-eacces.md)

## What changed
[Dockerfile.worker](../../Dockerfile.worker)'s `runner` stage now sets a
fixed, shared `COREPACK_HOME` and fully prepares the pinned pnpm release into
it at build time, before the non-root `app` user exists:

```dockerfile
ENV COREPACK_HOME=/opt/corepack

COPY package.json pnpm-lock.yaml pnpm-workspace.yaml tsconfig.json drizzle.config.ts ./
RUN corepack enable \
  && corepack prepare --activate \
  && chmod -R a+rX "$COREPACK_HOME"
```

`corepack prepare --activate` (no version argument) reads the exact pin from
`package.json`'s `"packageManager"` field, resolves and downloads that release
now (build time, root, real network access), and activates it as the default
— so a later `pnpm` invocation never needs to re-resolve or re-fetch anything.
`chmod -R a+rX` makes that shared cache directory readable by any user,
including the non-root `app` user created afterward — the same kind of
read access `node_modules` already needs from `app`, not a special-case
workaround.

`CMD` reverted to `["pnpm", "worker:start"]`, and both compose files'
`migrate` service reverted to `command: ["pnpm", "db:migrate"]`.

### Superseded first attempt
An earlier version of this fix sidestepped the problem instead of fixing it —
it called the underlying binaries directly (`node_modules/.bin/tsx`,
`node_modules/.bin/drizzle-kit`) and never invoked `pnpm` at runtime at all.
That did resolve the `EACCES` crash, but left `pnpm` completely absent from
the runtime image (`which pnpm` found nothing), which doesn't satisfy the
actual requirement: `pnpm` needs to be a genuinely usable tool in the image
(for ad-hoc `docker compose run --rm migrate pnpm <anything>` debugging, and
so the image doesn't silently diverge from what `package.json`'s scripts
promise). The `COREPACK_HOME` fix above replaces that attempt.

## Why this fixes the root cause
The original crash wasn't caused by Corepack downloading things — it was
caused by Corepack caching those downloads under `$COREPACK_HOME`, which
defaults to a path under the *invoking user's* `$HOME`. That default is fine
when the same user prepares and later runs pnpm, but breaks the moment a
different, homeless, non-root user (`app`) tries to invoke `pnpm` against a
cache that was populated by `root` in a completely different build stage's
filesystem. Overriding `COREPACK_HOME` to a fixed path — and populating it
*before* switching to `app` — removes the user-dependency entirely: every
user in the final image reads from the same, already-fully-resolved location.
No network access is ever attempted at runtime, and no per-user permission
workaround is needed — the directory is simply readable, like any other
build artifact baked into the image.

## How verified
- `npx tsc --noEmit` — clean.
- Both compose files parse as valid YAML; `migrate`'s `command` confirmed via
  `yaml.safe_load` to be `["pnpm", "db:migrate"]` again.
- Docker itself was unavailable in this environment, so `docker run --rm
  schduled-worker which pnpm` and `docker compose run --rm migrate pnpm
  db:migrate` were not re-verified live here — same standing caveat as the
  other 2026-07-24 Docker bug docs. The self-hoster who reported this should
  rebuild and confirm both commands succeed.
