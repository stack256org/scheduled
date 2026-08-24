# Bug: Location step — Continue button dead after switching away from a phone-call option

**Date:** 2026-07-17
**Area:** Event-type builder → Location step
**Files:**
- [app/(app)/event-types/_components/tab-location.tsx](../../app/(app)/event-types/_components/tab-location.tsx)
- [app/(app)/event-types/_components/builder.tsx](../../app/(app)/event-types/_components/builder.tsx)

## Symptom
In meeting (event-type) create/edit, on the Location step: select a "Phone call"
option, then switch to any other location type (Google Meet, Zoom, In-person,
Custom, etc.). The "Booking Form" continue button then does nothing — it silently
fails to advance to the next step.

## How reproduced
1. Create a meeting type, go to the Location tab.
2. Click "Phone call (they call)".
3. Without typing a phone number, click another option (e.g. Google Meet).
4. Click "Booking Form" (Next). Nothing happens.

## Root cause
`PhoneInput` auto-fills a **dial-code-only** value on mount (e.g. `"+91 "`) into the
`hostPhoneNumber` form field when "Phone call (they call)" is selected and no prior
number exists ([tab-location.tsx](../../app/(app)/event-types/_components/tab-location.tsx), the `PhoneInput` mount effect).

Switching the location type only changes `locationType`
([tab-location.tsx:306](../../app/(app)/event-types/_components/tab-location.tsx#L306)) —
nothing clears `hostPhoneNumber`. The stale `"+91 "` stays in form state.

The Location step's Next handler runs
`form.trigger(["locationType", "locationValue", "hostPhoneNumber"])`
([builder.tsx:190](../../app/(app)/event-types/_components/builder.tsx#L190)),
validating `hostPhoneNumber` **unconditionally** regardless of the selected type. The
field's zod refine ([builder.tsx:86-93](../../app/(app)/event-types/_components/builder.tsx#L86-L93))
rejects a non-empty malformed value: `"+91 "` trims to `"+91"` (3 chars), failing the
`/^\+[1-9][\d\s\-().]{5,20}$/` pattern. `form.trigger` returns false, so
`setActiveTab` never fires and the button appears dead.

Intermittent because if a valid number was previously saved to localStorage
(`schduled:lastPhoneNumber`), the auto-fill is a valid number and validation passes.

The same class of stale-value bug applies to `locationValue` (in-person address /
custom link) left behind when switching away from In-person/Custom.
