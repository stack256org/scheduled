# Solution: appearance picker hydration flash

**Fixed:** 2026-07-14

**Files changed:** `app/(orbit)/orbit/settings/_components/appearance-card.tsx`, `app/setup/setup-wizard.tsx`

**What changed:** Both components now track a `mounted` boolean (`useState(false)`, flipped to `true` in a `useEffect` on mount). The "is this option selected" check is gated on `mounted &&` before comparing against `theme`, so no option renders as selected until after the client has actually resolved the real stored value.

**Why this fixes the root cause:** The visual selection state no longer renders a guess (`"system"` default) and then jump to the real value — it renders nothing-selected until the real value is known, then renders correctly once, with no flash.

**How it was verified:** `tsc --noEmit` clean. Not re-screenshotted specifically for the flash (it's a sub-100ms visual artifact, hard to capture meaningfully in a static screenshot) — verified by code review of the standard `next-themes`-recommended mounted-guard pattern.
