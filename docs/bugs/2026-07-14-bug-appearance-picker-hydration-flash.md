# Bug: appearance picker hydration flash

**Found:** 2026-07-14, during a review pass on the setup-wizard/password-management branch before committing.

**Where:** `app/(orbit)/orbit/settings/_components/appearance-card.tsx` and `app/setup/setup-wizard.tsx`.

**What's broken:** Both components read `next-themes`' `useTheme()` directly to decide which Light/Dark/System option shows as selected. `next-themes` can't know the real stored theme until it mounts client-side, so on first paint `theme` is `undefined` (falling back to "system"), then flips to the actual value once mounted — visible as the selected-option highlight jumping between options right after load.

**How it was found:** Flagged by a fresh reviewer agent examining the diff before commit; this is a documented `next-themes` behavior, not something caught via a runtime error.

**Root cause:** Reading `theme` straight from `useTheme()` without gating the "which option is selected" UI on whether the component has actually mounted client-side.
