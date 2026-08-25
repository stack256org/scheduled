# Bug: stale `hasPassword` state in PasswordCard

**Found:** 2026-07-14, during a review pass on the setup-wizard/password-management branch before committing.

**Where:** `components/profile/password-card.tsx`, used on both `/orbit/settings` and `/profile/security`.

**What's broken:** `PasswordCard` decides whether to render "Set a Password" (no current-password field) or "Change Password" (current + new + confirm) based on a `hasPassword` prop passed once from the server. After a successful "Set a Password" submission, nothing updated that prop or refetched it — the component stayed in "Set a Password" mode.

**How it was found:** During review, a fresh agent flagged it as a plausible bug. Reproduced live: created a test account with no password, loaded `/profile/security`, submitted "Set a Password" successfully, then without reloading the page tried to submit the form again — the UI still showed "Set a Password" (no current-password field) and calling `setPasswordAction` a second time hit the server-side guard, returning "A password is already set. Use Change password instead." with no visible reason why, since the UI never switched modes.

**Root cause:** `hasPassword` was only ever read from the initial server-rendered prop, never updated client-side after a successful "set" call.
