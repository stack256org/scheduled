# Solution: Docker build fails prerendering `/login` — connects to a database that doesn't exist at build time

**Date:** 2026-07-24
**Pairs with:** [2026-07-24-bug-build-time-prerender-hits-real-db.md](./2026-07-24-bug-build-time-prerender-hits-real-db.md)

## What changed
Added `export const dynamic = "force-dynamic";` to all 4 pages that
unconditionally call the DB-touching setup/sign-in-method guards:
- [app/(auth)/login/page.tsx](../../app/(auth)/login/page.tsx)
- [app/post-auth/page.tsx](../../app/post-auth/page.tsx)
- [app/setup/page.tsx](../../app/setup/page.tsx)
- [app/(landing)/page.tsx](../../app/(landing)/page.tsx)

Verified (via a full sweep of every `page.tsx`/`layout.tsx` outside
`app/(app)/**`, plus spot checks inside it) that no other route has the same
unsignaled-unconditional-DB-call shape — see the investigation notes below.

## Why this fixes the root cause
`export const dynamic = "force-dynamic"` tells Next.js this route must always
render per-request, never be statically generated. That's also the *correct*
semantic behavior for these four pages regardless of the build failure: each
one gates on live, can-change-at-any-time state (has any user signed up yet,
what sign-in methods are currently enabled) — none of them should ever be
served from a build-time snapshot even if the build itself weren't an issue.
With this export, `next build` skips attempting to prerender them, so it
never tries to open a database connection during the build — only at actual
request time, when a real `DATABASE_URL` (from `env_file: .env`) is available.

## How verified
- `npx tsc --noEmit` — clean.
- Full-repo sweep confirmed no other Server Component page has an
  unconditional database call that isn't already covered by either an
  existing `export const dynamic`, a `cookies()`/`headers()`/`searchParams`
  read that auto-forces dynamic rendering (`(app)/**`, `(onboarding)/**`,
  `(booking)/confirmed`), or a dynamic route segment with no
  `generateStaticParams` (`(booking)/**`'s `[username]`/`[token]` routes,
  which Next doesn't eagerly prerender regardless).
- Docker itself was unavailable in this environment, so `docker compose up -d
  --build` was not re-run end-to-end here — this was fixed directly from the
  self-hoster's own build output and reasoning about Next.js's prerendering
  rules; they should retry the build to confirm it now gets past static page
  generation.
