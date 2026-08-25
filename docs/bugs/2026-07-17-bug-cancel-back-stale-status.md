# Bug: Cancelled meeting status is stale after navigating back

## What's broken
After cancelling a meeting and clicking "Go Back", the previous page (e.g. the
booking detail page) still shows the old, non-cancelled status. The updated
status only appears after a manual browser refresh.

## Where
- `app/(booking)/cancel/[token]/cancel-client.tsx` — the cancel flow / "Go Back" button
- Reached from `app/(app)/bookings/[id]/page.tsx:325` ("Cancel booking" link → `/cancel/[token]`)

## How it was found
User reported: after cancelling a meeting and navigating back to the previous
page, the page does not refresh automatically and shows the stale status.

## Root cause
The cancellation is performed with a client-side `fetch()` to
`/api/bookings/cancel`. Nothing invalidates the Next.js App Router **Router
Cache**. The "Go Back" button calls `router.back()`, which serves the previous
route from the client-side Router Cache — the cached RSC payload still reflects
the pre-cancellation (non-cancelled) state. Because no `router.refresh()` (or
server-action `revalidatePath`) runs after the mutation, the cache is never
invalidated, so the destination page renders stale data until a hard refresh.
