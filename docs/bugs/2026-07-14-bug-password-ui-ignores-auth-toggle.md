# Bug: password UI doesn't account for password auth being disabled

**Found:** 2026-07-14, during a review pass on the setup-wizard/password-management branch before committing.

**Where:** `components/profile/password-card.tsx` (rendered on both `app/(orbit)/orbit/settings/page.tsx` and `app/(app)/profile/security/page.tsx`).

**What's broken:** `PasswordCard` rendered its "Set a Password" / "Change Password" form unconditionally, with no check against `NEXT_PUBLIC_PASSWORD_AUTH_ENABLED`. That env var directly controls `emailAndPassword.enabled` in `lib/auth.ts`, so when an operator sets it to `false` (a documented, supported deployment mode for magic-link/Google-only instances), Better Auth's `setPassword`/`changePassword` endpoints are disabled entirely — but the form still rendered as if they'd work, only failing with a generic "Something went wrong" error on submit.

**How it was found:** Flagged by a fresh reviewer agent examining the diff before commit; confirmed by reading `lib/auth.ts` (`emailAndPassword: { enabled: passwordAuthEnabled, ... }`).

**Root cause:** The new `PasswordCard` component was built without threading through the one existing env flag that determines whether the underlying Better Auth plugin is even active.
