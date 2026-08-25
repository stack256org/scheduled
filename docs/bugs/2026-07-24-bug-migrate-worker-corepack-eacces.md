# Bug: `migrate`/`worker` containers crash with `EACCES` trying to write Corepack's cache

**Date:** 2026-07-24
**Area:** Docker runtime (`Dockerfile.worker`, `docker-compose.yml`, `docker-compose.external-db.yml`)
**Files:**
- [Dockerfile.worker](../../Dockerfile.worker)
- [docker-compose.yml](../../docker-compose.yml)
- [docker-compose.external-db.yml](../../docker-compose.external-db.yml)

## Symptom
After fixing the earlier build-time OOM and prerender-hits-a-fake-database
issues, `docker compose up -d --build` got past building all images, but the
`migrate` container crashed immediately on start:

```
Error: EACCES: permission denied, mkdir '/home/app/.cache/node/corepack/v1'
    at mkdirSync (node:fs:1370:26)
    at getTemporaryFolder (.../corepack/dist/lib/corepack.cjs:21953:27)
    at download (.../corepack/dist/lib/corepack.cjs:22288:21)
    at installVersion (.../corepack/dist/lib/corepack.cjs:22386:61)
    at async Engine.ensurePackageManager (.../corepack.cjs:22899:32)
```

## How reproduced
Reported directly from a self-hoster's server (`docker compose logs migrate`),
confirmed by reading the image build and the package manager configuration:
1. `package.json` pins `"packageManager": "pnpm@11.6.0"`.
2. `Dockerfile.worker`'s `deps` stage runs `corepack enable && pnpm install
   --frozen-lockfile --prod` — this is BUILD time, running as root (the
   default user before any `USER` directive), so Corepack fetches/caches the
   pinned pnpm version under root's home without issue.
3. The `runner` stage switches to a non-root `app` user
   (`useradd --system ...`, no home directory created), then both
   `docker-compose.yml`'s `migrate` service (`command: ["pnpm",
   "db:migrate"]`) and `Dockerfile.worker`'s own `CMD ["pnpm",
   "worker:start"]` invoke `pnpm` again — at **runtime**, as `app`.
4. `pnpm` on the image's `PATH` is not a real pnpm binary — it's Corepack's
   shim. Every invocation re-checks `package.json`'s `packageManager` pin and,
   if the exact pinned version isn't already prepared for the *current* execu
   tion context, tries to download and cache it into `$COREPACK_HOME`
   (default `~/.cache/node/corepack`). The version cached during build lives
   under root's home in the (discarded) `deps` build stage — it was never
   copied into the runner image, and even if it had been, `app`'s `$HOME`
   doesn't point there. So the runtime shim re-attempts the fetch, tries to
   create `/home/app/.cache/node/corepack/v1`, and fails: that directory
   doesn't exist and `app` has no permission to create it.

## Root cause
Running `pnpm <script>` inside a production container as a non-root user is
inherently fragile with Corepack's lazy-activation model: the package manager
version is prepared per-user, on demand, at invocation time — not baked into
the image in a way that survives a user switch. This is exactly the failure
mode a comparable project (Kanbanica)'s `Dockerfile.worker` already documents
and avoids, by never invoking `pnpm` at runtime at all — it calls the actual
binary (`tsx`) directly from `node_modules/.bin`. Schduled's `Dockerfile.worker`
and the new `migrate` service (added earlier today) both still went through
`pnpm`, reintroducing the exact problem Kanbanica had already solved.
