# Solution: in-memory-only rate limiter breaks under multiple web replicas

**Fixed:** 2026-07-15

**Files changed:**
- `db/schema/platform.ts` — new `rateLimitBucket` table (`rate_limit_bucket`: `key` PK, `count`, `resetAt`, indexed on `resetAt`), plus a previously-missing index on `idempotency_key.expires_at` added at the same time since it was flagged in the same review pass.
- `db/migrations/0015_talented_hiroim.sql` — generated + applied migration for the above.
- `lib/api/helpers.ts` — `checkRateLimit()` is now `async` and Postgres-backed: a single atomic `INSERT ... ON CONFLICT (key) DO UPDATE` upsert either resets the bucket to `count=1` (if the window has expired) or increments it, returning the new count in one round trip. Postgres serializes concurrent upserts on the same primary key, so this is race-free even under concurrent requests from different replicas — something an in-memory `Map` could never provide. Includes a 1%-probability opportunistic cleanup of stale rows (no dedicated cron needed; harmless if it runs on multiple replicas at once).
- All 13 call sites across `app/api/**/route.ts` updated to `await checkRateLimit(...)`.

**Why chosen over Redis/Upstash:** This app deliberately has zero other infrastructure dependencies beyond Postgres (pg-boss for the job queue instead of a separate broker, no Redis anywhere). Adding Redis just for rate limiting would introduce a new operational dependency for every self-hoster running this project, when Postgres — which every deployment already has — solves the same correctness problem.

**How it was verified:** Live, not just typechecked. Hit `/api/newsletter` (5/min limit) 7 times in a row: first 5 returned `200`, the next 2 returned `429`. Confirmed the `rate_limit_bucket` row was created with the expected shape. Also covered by new automated tests (`lib/api/rate-limit.test.ts`) run against the real dev database: basic limit enforcement, independent buckets per key, window-expiry reset, and — the actual point of moving this to Postgres — that 10 concurrent hits on the same key with a limit of 5 correctly allow exactly 5, not more (proving the atomic upsert prevents the race an in-memory or naive read-then-write implementation would have under concurrency). `tsc --noEmit` clean. Test data cleaned up after verification.
