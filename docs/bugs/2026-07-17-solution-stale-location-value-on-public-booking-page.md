# Solution: stale locationValue could leak onto the public booking page for the wrong location type

**Fixed:** 2026-07-17

**Files changed:**
- `app/(booking)/[username]/[eventSlug]/_components/booking-calendar.tsx` — the location-preview block now requires `(eventType.locationType === 'in_person' || eventType.locationType === 'custom') && eventType.locationValue` before rendering, matching the same location-type whitelist pattern already used by `app/(app)/bookings/page.tsx`'s `joinUrl` logic.

**Why this fixes the root cause:** The underlying `locationValue` field still isn't cleared on type switch (that's a separate, lower-priority cleanup), but every place that reads it now gates on `locationType` first, so stale data for an inactive location type can no longer surface anywhere a user sees it — consistent with how the bookings list already handled this.

**How it was verified:** Live, not just typechecked. Created a disposable test host with a real availability schedule, then two event types: (1) `locationType: 'zoom'` with a `locationValue` deliberately set to a leftover custom address (reproducing the exact stale-data scenario), and (2) `locationType: 'in_person'` with a real address. Loaded both public booking pages in Playwright: the Zoom event type showed only "Zoom" with no address/link visible anywhere in the rendered page (confirmed via `innerText`, not just an HTML grep, since Next.js still serializes the prop into the RSC payload — which is expected and not user-visible), while the in-person event type correctly still displayed its real address. `tsc --noEmit` and the full Vitest suite (23/23) passed after the fix. All test data (user, event types, availability schedule/windows) and temp scripts removed afterward.
