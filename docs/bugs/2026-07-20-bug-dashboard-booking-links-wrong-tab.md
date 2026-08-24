# Bug: Clicking a cancelled booking on the dashboard opens the Upcoming tab

## What's broken
On `/dashboard`, the "Recent Bookings" card lists bookings with their real
status (e.g. "Cancelled"). Clicking a cancelled row navigates to `/bookings`,
but the page always opens on the **Upcoming** tab — the clicked booking is
nowhere to be seen unless the user manually switches to the Cancelled tab.
The same problem affects the "Upcoming Meetings" card too (any click just
goes to the generic upcoming list).

## Where
`app/(app)/dashboard/page.tsx` — the `upcomingMeetings.map(...)` and
`recentBookings.map(...)` rows in the two dashboard cards.

## How it was found
User reported: clicking a cancelled booking under "Recent Bookings" on the
dashboard lands on a page showing upcoming meetings instead.

## Root cause
Every row `<Link>` in both dashboard cards was hardcoded to `href="/bookings"`
— it never carried the specific booking's id or status. `/bookings`
(`app/(app)/bookings/page.tsx`) defaults its `tab` to `'upcoming'` unless a
`?tab=` or `?highlight=<id>` query param says otherwise, so any dashboard
click landed on the Upcoming tab regardless of the clicked booking's actual
status.

The bookings list page already has a `?highlight=<bookingId>` mechanism
(built for notification links) that looks up the booking's status server-side
and resolves the correct tab (`pending` / `cancelled` / `upcoming` / `past`),
plus a client-side `BookingHighlighter` that scrolls to and flashes the
matching row (`id="booking-<id>"`). The dashboard links just weren't using it.
