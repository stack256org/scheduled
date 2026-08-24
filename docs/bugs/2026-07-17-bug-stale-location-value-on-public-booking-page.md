# Bug: stale locationValue could leak onto the public booking page for the wrong location type

**Found:** 2026-07-17, during a self-review pass before committing the location-display feature added earlier in the same session (public booking page location preview + Google Calendar native location field).

**Where:** `app/(booking)/[username]/[eventSlug]/_components/booking-calendar.tsx` — the newly-added pre-booking location block rendered whenever `eventType.locationValue` was truthy, with no check on `eventType.locationType`.

**What's broken:** `app/(app)/event-types/_components/tab-location.tsx`'s location-type selector calls `field.onChange(opt.value)` when a host switches location type, but never clears the `locationValue` field. `app/actions/event-types.ts` then saves whatever is in `data.locationValue` verbatim (`data.locationValue?.trim() || null`), regardless of the newly-selected type. So a host who sets a Custom location link or an In-person address, then switches the event type to Zoom/Google Meet/phone, ends up with a DB row where `locationType = 'zoom'` but `locationValue` still holds the old address/link. The new location-preview block displayed that stale value on the public booking page as if it were the meeting location for the video/phone type.

**How it was found:** Traced by re-reading the new display condition (`{eventType.locationValue && (...)}`) against how `locationValue` is actually written on save — `bookings/page.tsx`'s pre-existing `joinUrl` logic already guards this same class of value with an explicit `locationType` whitelist, which the new code didn't mirror. Confirmed reachable by inspecting the type-switch handler and the save action, which showed no clearing step anywhere in the chain.

**Root cause:** The location-value field is never reset when its owning location type changes, so any code trusting `locationValue` alone (without also checking `locationType`) can render leftover data from a previous, unrelated location type.
