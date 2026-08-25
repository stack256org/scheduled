# Solution: first-admin race condition and non-atomic role promotion

**Fixed:** 2026-07-14

**Files changed:** `app/actions/setup.ts`

**What changed:** After `auth.api.signUpEmail()` creates the account, the role promotion now runs inside a `db.transaction()` that:
1. Re-checks whether any *other* user row exists (`ne(user.id, adminId)`).
2. If another user already exists, deletes the just-created account and returns "An admin account already exists. Refresh and sign in instead." instead of leaving two admins.
3. Otherwise promotes the account to `ADMIN_ROLE` inside the same transaction.

The whole transaction is wrapped in a `try/catch`: if the transaction throws for any reason (not just the "already exists" case), the just-created user is deleted in the `catch` block, so `hasAnyUser()` goes back to `false` and `/setup` stays retryable instead of permanently gating with a stranded non-admin account.

**Why this fixes the root cause:** The re-check-then-promote-or-rollback sequence is now atomic within a single transaction, closing the common double-submit race and making the promotion step all-or-nothing — a failure can no longer leave a half-finished state behind.

**Known residual limitation:** This is not a database-level guarantee (e.g. no partial unique index enforcing "at most one admin row"), so a theoretical race remains if two transactions start at the exact same instant under READ COMMITTED isolation. This is an accepted tradeoff for a first-run bootstrap endpoint that's only ever hit by a human during initial deployment — a full fix would require a schema-level constraint, which is out of scope for this pass.

**How it was verified:** `tsc --noEmit` clean. Not live-tested against actual concurrent requests (would require wiping the user table, which the user declined to test live) — verified by code review of the transaction logic instead.
