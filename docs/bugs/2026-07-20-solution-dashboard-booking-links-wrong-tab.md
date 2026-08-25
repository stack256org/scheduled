# Solution: Clicking a cancelled booking on the dashboard opens the Upcoming tab

## What changed
`app/(app)/dashboard/page.tsx` — both dashboard card links now pass the
booking id via the existing `?highlight=` param instead of linking to the
bare `/bookings` URL:

```tsx
// Upcoming Meetings card
<Link key={m.id} href={`/bookings?highlight=${m.id}`}>

// Recent Bookings card
<Link key={b.id} href={`/bookings?highlight=${b.id}`}>
```

## Why this fixes the root cause
`app/(app)/bookings/page.tsx` already resolves the correct tab from
`?highlight=<id>` by looking up that booking's status (`pending` →
`pending` tab, `cancelled`/`rescheduled` → `cancelled` tab, future
`confirmed` → `upcoming`, past → `past`) whenever no explicit `?tab=` is
present. `BookingHighlighter` then scrolls to and briefly rings the matching
row (`id="booking-<id>"`). Passing the id from the dashboard reuses this
existing, already-tested mechanism (previously only reachable from
notification links) instead of adding new logic — a cancelled booking now
opens directly on the Cancelled tab with that row highlighted.

## How it was verified
- `npx tsc --noEmit` passes clean.
- Confirmed `app/(app)/bookings/page.tsx` renders `<BookingHighlighter />`
  and that its rows carry `id={`booking-${b.id}`}`, so the id passed from the
  dashboard resolves to both the correct tab and the correct highlighted row.
