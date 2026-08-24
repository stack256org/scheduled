# Solution: Location step — phone number field shows the country code twice and rejects a bare 10-digit number

**Date:** 2026-07-22
**Pairs with:** [2026-07-22-bug-phone-input-duplicate-country-code.md](./2026-07-22-bug-phone-input-duplicate-country-code.md)

## What changed

**[app/(app)/event-types/_components/tab-location.tsx](../../app/(app)/event-types/_components/tab-location.tsx)**
- `PhoneInput` now renders two independent controls instead of one badge + one
  raw-value input: a small editable dial-code field (`+91`) and a separate
  number field that only ever holds the local digits. `stripDialCode()`
  derives the number field's display value by removing the dial code prefix
  from the stored `hostPhoneNumber`; `composeAndEmit()` recombines
  `${dialCode} ${localNumber}` into the single string written back to the
  form on every change to either field.
- Removed the mount-time auto-fill that wrote a dial-code-only value
  (`"+91 "`) straight into the form field — no longer needed since the dial
  code now lives in its own field and isn't part of what the user types into
  the number box.
- Added `capDigits()` and a `MAX_LOCAL_DIGITS` (15, the E.164 national-number
  ceiling) so the number field stops accepting further digits once the cap is
  hit, instead of allowing arbitrarily long pastes/typing (reported
  separately: a 25-digit string was enterable with no bound).
- Dropped the now-outdated "Include your country code" hint from the field's
  `FormDescription`, since the dial code is its own field now.

**[app/(app)/event-types/_components/builder.tsx](../../app/(app)/event-types/_components/builder.tsx)**
- `hostPhoneNumber`'s zod validation no longer bounds the raw value by
  character count (`{5,20}` chars, which under- or over-counted depending on
  how many separators were typed). It now has two refinements: a format check
  (`+` followed by digits/separators) and a digit-count check requiring
  between 5 and 18 total digits (dial code + local number), matching the
  4–15 digit local-number range enforced in the input.

## Why this fixes the root cause
The dial code and the local number are no longer the same piece of state
rendered twice — the dial code is only ever shown/edited in its own field,
and the number field only ever shows/accepts the digits after it. A user
typing a bare 10-digit number now produces a value that already has the
correctly-composed `+91 <10 digits>` behind the scenes, so it passes
validation without the user needing to type the country code a second time.

## How verified
- `npx tsc --noEmit` — clean.
- Live check in the running dev server (`localhost:3000` → Meeting Types →
  Location tab → Phone call): confirmed only one "+91" box appears next to a
  separate number box (previously two "+91" boxes appeared), and typing a
  bare 10-digit number no longer triggers "Invalid".
