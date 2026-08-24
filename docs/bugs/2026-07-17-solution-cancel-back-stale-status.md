# Solution: Cancelled meeting status is stale after navigating back

## What changed
- `app/(booking)/cancel/[token]/cancel-client.tsx` — after a successful
  cancellation, call `router.refresh()` (immediately after `setDone(true)` in
  `handleCancel`).

```ts
setDone(true);
router.refresh();
```

## Why this fixes the root cause
The cancellation runs as a client-side `fetch()` to `/api/bookings/cancel`,
which does not touch Next.js's App Router Router Cache. `router.refresh()`
invalidates the entire Router Cache and refetches Server Components. Once
invalidated, the subsequent `router.back()` (from the "Go Back" button) can no
longer serve the previous route from the stale cache — it refetches, so the
booking detail page renders the updated `cancelled` status without a manual
browser refresh.

The `useRouter()` instance was already imported and in scope, so no new imports
were needed.

## How it was verified
- `npx tsc --noEmit` passes clean.
- Flow reasoning: cancel → `router.refresh()` invalidates Router Cache →
  "Go Back" → `router.back()` refetches the previous route → cancelled status
  shown immediately.
