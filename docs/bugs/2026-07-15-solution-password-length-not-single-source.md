# Solution: password min/max length duplicated instead of one source of truth

**Fixed:** 2026-07-15

**Files changed:**
- `config/platform.ts` — added `MIN_PASSWORD_LENGTH = 8` and `MAX_PASSWORD_LENGTH = 128` as the single shared constants (this file was already the established client-safe home for cross-cutting constants like `ADMIN_ROLE`/`PRODUCT_NAME`, since it has zero server-only dependencies and is safe to import from both client and server code).
- `lib/auth.ts` — `emailAndPassword` now explicitly sets `minPasswordLength: MIN_PASSWORD_LENGTH, maxPasswordLength: MAX_PASSWORD_LENGTH`, so Better Auth's actual enforcement is driven by the same constants instead of an unstated library default.
- `components/profile/password-card.tsx`, `app/setup/setup-wizard.tsx`, `app/actions/setup.ts`, `app/(auth)/reset-password/_components/reset-password-form.tsx`, `app/(auth)/_components/auth-form.tsx`, `lib/auth-errors.ts` — all now import `MIN_PASSWORD_LENGTH`/`MAX_PASSWORD_LENGTH` from `config/platform.ts` instead of hardcoding `8`/`128`. Also added the previously-missing max-length client-side check to `setup-wizard.tsx`, `setup.ts`, and `reset-password-form.tsx`, which only validated the minimum before.

**Why this fixes the root cause:** There is now exactly one place to change password length policy. Better Auth's server-side enforcement and every client-side validation message read from the same two constants, so they cannot drift out of sync the way they could before (where matching values were coincidental, not enforced).

**How it was verified:** Live, not just typechecked. Hit `/api/auth/sign-up/email` directly with a 6-character password (rejected: `PASSWORD_TOO_SHORT`), a 129-character password (rejected: `PASSWORD_TOO_LONG`), and a valid 8-character password (accepted, `200`) — proving Better Auth is now genuinely enforcing the explicit config, not just coincidentally matching what the UI expects. `tsc --noEmit` clean, all 23 existing tests still pass. Test accounts cleaned up after verification.
