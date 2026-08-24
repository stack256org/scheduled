# Bug: Location step — phone number field shows the country code twice and rejects a bare 10-digit number

**Date:** 2026-07-22
**Area:** Event-type builder → Location step (phone-call location types)
**Files:**
- [app/(app)/event-types/_components/tab-location.tsx](../../app/(app)/event-types/_components/tab-location.tsx)
- [app/(app)/event-types/_components/builder.tsx](../../app/(app)/event-types/_components/builder.tsx)

## Symptom
On the meeting type Location tab, after choosing a "Phone call" location type, the
"YOUR PHONE NUMBER" field visually shows the country code dial code redundantly, and
typing only the 10-digit mobile number (without re-typing "91" / "+91") gets marked
Invalid.

## How reproduced
1. Create/edit a meeting type with a "Phone call" location option, go to the Location tab.
2. Look at the "Your phone number" field — the "+91" dial code appears twice.
3. Clear the field and type only a 10-digit number, e.g. `8988789887`.
4. Field is marked Invalid until the user also manually prefixes `+91`/`91`.

## Root cause
`PhoneInput` (`tab-location.tsx`) rendered a single `<input>` bound directly to the
raw `hostPhoneNumber` form value, plus a "badge" `<div>` next to it that displayed
`extractDialCode(value)` — i.e. the dial code re-derived from that *same* value. On
mount, an effect also auto-filled the raw value with the timezone-detected dial code
(`onChange(code + ' ')`, e.g. `"+91 "`), so the stored/typed value itself always
contained the dial code text in addition to the badge showing it again next to it.

The zod schema (`builder.tsx`, `hostPhoneNumber` refine,
`/^\+[1-9][\d\s\-().]{5,20}$/`) validates the *entire* raw string, so it requires the
dial code to be embedded inside the typed value. Because the badge was purely
cosmetic and never split out of / composed back into the actual field value, a user
who typed just the 10-digit number (assuming the visible "+91" badge already covered
the country code) produced a value with no leading `+`, failing the regex.
