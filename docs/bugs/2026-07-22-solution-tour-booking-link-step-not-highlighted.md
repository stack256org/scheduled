# Solution: Guided tour "Share Your Booking Link" step shows a plain dimmed modal, nothing highlighted

**Date:** 2026-07-22
**Pairs with:** [2026-07-22-bug-tour-booking-link-step-not-highlighted.md](./2026-07-22-bug-tour-booking-link-step-not-highlighted.md)

## What changed

**[app/(app)/event-types/_components/event-type-card.tsx](../../app/(app)/event-types/_components/event-type-card.tsx)**
- Added `data-tour="booking-link"` to the per-meeting-type "Copy link" button, in
  both the list-row layout (line ~458) and the grid-card layout (line ~331). This
  is the most relevant booking-link affordance visible on the Meeting Types page,
  where the tour's target previously didn't exist at all.

No changes were needed in `guided-tour.tsx` — `document.querySelector` already
picks up the first element matching `[data-tour="booking-link"]` in the current
page's DOM, so whichever page is showing (Dashboard or Meeting Types) now has a
matching target for step 4.

## Why this fixes the root cause
The tour's spotlight only renders a highlight ring when it can find its target
element in the current page's DOM. Step 4 previously only had a target on the
Dashboard; visiting step 4 from Meeting Types found nothing, so it silently fell
back to an unhighlighted, centered/dimmed card. Giving the copy-link button on
the Meeting Types page the same `data-tour="booking-link"` marker means the
step's target resolves on that page too, so the spotlight ring and anchored
tooltip now appear around the actual clickable link icon the copy explains.

## How verified
- `npx tsc --noEmit` — clean.
- Confirmed via code inspection that `useSpotlight`'s `document.querySelector('[data-tour="booking-link"]')`
  now resolves on the Meeting Types page (both list and grid view) as well as the
  Dashboard, since exactly one matching element is mounted per page.
