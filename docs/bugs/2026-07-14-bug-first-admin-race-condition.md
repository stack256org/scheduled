# Bug: first-admin race condition and non-atomic role promotion

**Found:** 2026-07-14, during a review pass on the setup-wizard/password-management branch before committing.

**Where:** `app/actions/setup.ts`, `createFirstAdmin()`.

**What's broken:** Two issues in the same function, both stemming from the "check no user exists, then create one" flow not being atomic:

1. **Race condition:** The check for `existing` users and the subsequent `signUpEmail` + role-promotion were not wrapped in a transaction or lock. Two concurrent submissions of the setup wizard (double form-submit, two browser tabs) could both pass the "no user exists" check before either finished, resulting in two separate accounts both promoted to `ADMIN_ROLE` — violating the project's "only one admin" invariant, with no UI to demote one afterward.
2. **Non-atomic promotion:** The `db.update(user).set({ role: ADMIN_ROLE })` call ran as a separate step after `auth.api.signUpEmail()` had already committed the user row. If that update failed for any reason (e.g. a transient DB error), the account would be left behind as a non-admin `user`, and `hasAnyUser()` would now return `true` — permanently redirecting `/setup` to `/login` with no admin ever created and no way to recover except manual DB surgery.

**How it was found:** Flagged by a fresh reviewer agent examining the diff before commit; confirmed by reading the code (no transaction wrapping the check-then-insert-then-update sequence).

**Root cause:** The "first admin" bootstrap logic assumed single-request execution and treated `signUpEmail` + role update as independent, non-rollback-able steps.
