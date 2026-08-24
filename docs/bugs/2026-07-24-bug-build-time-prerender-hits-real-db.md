# Bug: Docker build fails prerendering `/login` — connects to a database that doesn't exist at build time

**Date:** 2026-07-24
**Area:** Docker image build (`Dockerfile`, `web` builder stage)
**Files:**
- [app/(auth)/login/page.tsx](../../app/(auth)/login/page.tsx)
- [app/post-auth/page.tsx](../../app/post-auth/page.tsx)
- [app/setup/page.tsx](../../app/setup/page.tsx)
- [app/(landing)/page.tsx](../../app/(landing)/page.tsx)
- [lib/setup.ts](../../lib/setup.ts)
- [lib/settings/sign-in-methods.ts](../../lib/settings/sign-in-methods.ts)

## Symptom
After fixing an earlier build-time OOM, a self-hoster's `docker compose up -d --build` got further — compiled successfully, finished Next's internal type-check — then failed during "Generating static pages" with:

```
Error occurred prerendering page "/login". Read more: https://nextjs.org/docs/messages/prerender-error
Error: Failed query: select "id" from "user" limit $1
[cause]: Error: connect ECONNREFUSED 127.0.0.1:5432
```

## How reproduced
Reported directly from the self-hoster's server output (`docker compose up -d --build`), reproduced by static trace of the Next.js build pipeline:
1. `app/(auth)/login/page.tsx`'s `LoginPage` component calls `await redirectToSetupIfNeeded()` and `await getEffectiveSignInMethods()` unconditionally at the top of the function body.
2. Neither call reads `cookies()`/`headers()`/`searchParams` first, and the page had no `export const dynamic`. Next.js's App Router therefore has no signal that this route needs per-request rendering, so `next build` attempts to statically prerender it at build time.
3. `redirectToSetupIfNeeded()` (`lib/setup.ts`) calls `hasAnyUser()`, which runs `db.select(...).from(user)...` — a real Postgres query. `getEffectiveSignInMethods()` (`lib/settings/sign-in-methods.ts`) does the same against `appSetting`.
4. The `Dockerfile`'s `builder` stage only sets a placeholder `DATABASE_URL="postgresql://build:build@localhost:5432/build"` (needed to satisfy `lib/env.ts`'s build-time validation — see the `2026-07-24-bug-docker-build-fails-missing-env-placeholders` pair) — nothing is actually listening on `localhost:5432` inside the builder container, so the query fails with `ECONNREFUSED`, and Next aborts the whole build on the first prerender error.

## Root cause
Three other pages have the exact same shape — `app/post-auth/page.tsx`, `app/setup/page.tsx`, and `app/(landing)/page.tsx` (the marketing homepage at `/`) all unconditionally call `redirectToSetupIfNeeded()` / `hasAnyUser()` at the top of their Server Component, per `lib/setup.ts`'s own doc comment: "Call at the top of every unauthenticated entry-point page (landing, login, post-auth)." None of the four had `export const dynamic`, so all four were eligible for the same build-time prerender-against-a-fake-database failure — `/login` simply happened to be first in Next's build order.

Pages under `app/(app)/**` and `app/(onboarding)/**` don't have this problem: they gate on `requireSession()`/`requireAdmin()` (`lib/authz.ts`), which call `headers()` internally — Next.js auto-detects that as a dynamic API and implicitly forces those routes dynamic without needing an explicit export. `app/(booking)/**` pages are dynamic-segment routes (`[username]`, `[token]`, etc.) with no `generateStaticParams`, so Next doesn't eagerly prerender them at build time either. The four fixed pages were the only ones doing an *unconditional, un-signaled* DB read from an otherwise "pure" Server Component.
