# Solution: password UI doesn't account for password auth being disabled

**Fixed:** 2026-07-14

**Files changed:** `components/profile/password-card.tsx`, `app/(orbit)/orbit/settings/page.tsx`, `app/(app)/profile/security/page.tsx`

**What changed:** `PasswordCard` now takes a required `passwordAuthEnabled: boolean` prop. When `false`, it renders an informational card instead of the form:
- If the account already has a password: "Password sign-in is disabled on this instance. Contact your administrator to re-enable it before changing your password."
- If not: "Password sign-in is disabled on this instance. Use a magic link or Google to sign in."

Both call sites pass the existing env-derived value through: the Orbit settings page already computed `passwordAuthEnabled` locally for its health-check display, so it's just reused; the user-facing security page imports `passwordAuthEnabled` from `lib/auth.ts`.

**Why this fixes the root cause:** The form can no longer be submitted against a disabled `emailAndPassword` plugin — the UI now reflects the actual deployment configuration instead of assuming password auth is always available.

**How it was verified:** `tsc --noEmit` clean. Verified by code inspection of the conditional branch rather than a live click-through, since `NEXT_PUBLIC_PASSWORD_AUTH_ENABLED` is inlined at build time and testing the `false` state would require restarting the dev server with a different `.env` value.
