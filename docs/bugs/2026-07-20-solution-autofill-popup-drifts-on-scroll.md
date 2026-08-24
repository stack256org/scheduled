# Solution: Browser autofill/password suggestion popup drifts when scrolling

## What changed
- Added `components/scaffold/autofill-scroll-fix.tsx` — a small client
  component (`AutofillScrollFix`) that attaches a scroll listener to
  `[data-app-main]` and blurs the currently focused input/select/textarea as
  soon as that container scrolls.
- Wired it into `components/scaffold/app-shell.tsx`, rendered alongside the
  existing `<ScrollReset />` inside `<main data-app-main>`.

```tsx
function onScroll() {
  const active = document.activeElement
  if (
    active instanceof HTMLInputElement ||
    active instanceof HTMLSelectElement ||
    active instanceof HTMLTextAreaElement
  ) {
    active.blur()
  }
}
main.addEventListener('scroll', onScroll, { passive: true })
```

## Why this fixes the root cause
The app scrolls inside `<main data-app-main>` rather than the window, so
Chrome's native form-control popups (autofill, `<select>`) never receive the
scroll signal they use to re-track or close themselves — they stay pinned at
their original screen position while the input moves. Blurring the field the
moment `main` scrolls makes Chrome close the popup itself (the same way it
would on any normal blur), instead of leaving it visually orphaned. This
mirrors the existing `ScrollReset` pattern of a tiny effect-only component
targeting `[data-app-main]`, so it's consistent with how the shell already
handles this non-window scroll container.

## How it was verified
- `npx tsc --noEmit` passes clean.
- Flow reasoning: focusing "Current password" on `/profile/security` opens
  Chrome's suggestion popup; scrolling `main` now blurs the field
  immediately, so the browser closes the popup instead of leaving it
  detached from the input's new position.
