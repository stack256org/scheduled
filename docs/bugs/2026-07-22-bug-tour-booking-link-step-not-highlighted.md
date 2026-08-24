# Bug: Guided tour "Share Your Booking Link" step shows a plain dimmed modal, nothing highlighted

**Date:** 2026-07-22
**Area:** Guided onboarding tour, step 4 of 6
**Files:**
- [components/tour/guided-tour.tsx](../../components/tour/guided-tour.tsx)
- [app/(app)/event-types/_components/event-type-card.tsx](../../app/(app)/event-types/_components/event-type-card.tsx)

## Symptom
When the guided tour reaches step 4 ("Share Your Booking Link") while the user is on
a page other than the Dashboard (e.g. Meeting Types), the card appears as a plain
dimmed overlay with no spotlighted element — it "looks empty" even though the
description talks about a link the user should click.

## How reproduced
1. Trigger the guided tour and advance to step 4 while on the Meeting Types page
   (not the Dashboard).
2. The tour card renders centered with a full dark backdrop; no element on the page
   has the primary-colored highlight ring the other spotlight steps show.

## Root cause
Step 4 in `STEPS` (`guided-tour.tsx`) targets `[data-tour="booking-link"]`
(`guided-tour.tsx:63`). That attribute was only ever placed on the "My Booking
Page" / copy-link buttons in the Dashboard page header
(`app/(app)/dashboard/page.tsx:253,260`). Steps 2, 3, and 5 target sidebar nav
items, which exist in the global layout on every page, so they always resolve.
Step 4's target does not exist outside the Dashboard.

`useSpotlight` (`guided-tour.tsx:91-130`) calls `document.querySelector` for the
target; when it's not found, `rect` stays `null`, `anchored` becomes `false`
(`guided-tour.tsx:224`), and the component falls back to the centered/dimmed
layout (`guided-tour.tsx:364-370`) with no ring drawn around anything — hence the
"empty" look reported when the tour is advanced from a non-Dashboard page.
