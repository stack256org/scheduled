# Bug: in-memory-only rate limiter breaks under multiple web replicas

**Found:** 2026-07-15, flagged in `PROJECT_REVIEW.md`'s Security Audit and Biggest Weaknesses sections (the limitation was actually already self-documented in the code as a known tradeoff, but never resolved).

**Where:** `lib/api/helpers.ts`, `checkRateLimit()`.

**What's broken:** Rate-limit buckets were stored in a plain in-process `Map`, with a comment reading "Single-instance only. Sufficient for MVP; swap to Redis/Upstash for multi-node." Every web replica in a horizontally-scaled deployment would enforce its own independent counters — so a configured "10 requests/minute" limit would actually allow `10 × (number of replicas)` requests per minute in aggregate, since no replica knows what any other replica has counted.

**How it was found:** Self-documented in the code's own comment, and independently confirmed via a full codebase review (`PROJECT_REVIEW.md` §14, §17, §25).

**Root cause:** The rate limiter was built as a quick in-memory MVP shortcut with the multi-instance gap explicitly deferred, and never revisited.
