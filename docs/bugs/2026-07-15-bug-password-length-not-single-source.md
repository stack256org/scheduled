# Bug: password min/max length duplicated instead of one source of truth

**Found:** 2026-07-15, flagged in `PROJECT_REVIEW.md`'s Authentication & Authorization section ("Security weaknesses worth noting").

**Where:** `lib/auth.ts` (Better Auth config) and 5 separate UI/action call sites.

**What's broken:** `lib/auth.ts`'s `emailAndPassword` block never set `minPasswordLength`/`maxPasswordLength` explicitly — it silently relied on Better Auth's library defaults (8/128). Meanwhile, `components/profile/password-card.tsx` hardcoded its own `MIN_PASSWORD_LENGTH = 8` constant with a comment claiming it "must match `emailAndPassword.minPasswordLength` in lib/auth.ts" — a config value that didn't actually exist. Four more places independently hardcoded the same `8`/`128` values with no shared source: `app/setup/setup-wizard.tsx`, `app/actions/setup.ts`, `app/(auth)/reset-password/_components/reset-password-form.tsx`, `app/(auth)/_components/auth-form.tsx`, and the error-message text in `lib/auth-errors.ts`.

**How it was found:** Flagged during a full codebase review (`PROJECT_REVIEW.md` §9); confirmed by grepping for every `MIN_PASSWORD_LENGTH`/`password.length`/`minLength={8}` occurrence in the codebase.

**Root cause:** No single constant existed for password length policy — every call site guessed the same two numbers independently, with nothing enforcing they'd stay in sync if either one ever changed.
