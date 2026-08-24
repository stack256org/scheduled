# Solution: stale `hasPassword` state in PasswordCard

**Fixed:** 2026-07-14

**Files changed:** `components/profile/password-card.tsx`

**What changed:** `hasPassword` is now tracked in local component state (`useState`, seeded from the `hasPassword` prop, renamed to `initialHasPassword`), instead of being read directly from the prop on every render. After a successful `setPasswordAction` call, the handler now calls `setHasPassword(true)` before showing the success toast.

**Why this fixes the root cause:** The component no longer depends on a page reload (or a fresh server render) to know it just gained a password — the state flip happens immediately client-side, right where the success is already handled, so the form's mode (`Set a Password` vs `Change Password`) and the visibility of the "Current password" field update in the same render pass as the toast.

**How it was verified:** Live, not just typechecked. Created a temp account, forced `hasPassword = false` by nulling its `account.password` column while keeping a valid signed session cookie, then drove `/profile/security` with Playwright:
1. Confirmed initial state: "Set a Password" heading, no `#current-password` field.
2. Submitted "Set a Password" — got the "Password set" toast.
3. Without any reload: heading immediately read "Change Password" and `#current-password` became visible.
4. Used the just-set password to submit a real "Change password" — got the "Password changed" toast, confirming the new mode was fully functional, not just cosmetically switched.

`tsc --noEmit` clean. Temp test account deleted after verification.
