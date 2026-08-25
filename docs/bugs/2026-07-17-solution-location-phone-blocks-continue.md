# Solution: Location step — Continue button dead after switching away from a phone-call option

**Date:** 2026-07-17
**Pairs with:** [2026-07-17-bug-location-phone-blocks-continue.md](./2026-07-17-bug-location-phone-blocks-continue.md)

## What changed
[app/(app)/event-types/_components/tab-location.tsx](../../app/(app)/event-types/_components/tab-location.tsx) —
the location-card click handler now clears the per-type fields the newly selected
type does not use:

```tsx
onClick={() => {
  if (isDisabled) return;
  field.onChange(opt.value);
  // Clear per-type fields the new type doesn't use, so a stale value
  // (e.g. the dial-code PhoneInput auto-fills) can't fail the Location
  // step's validation.
  if (!opt.requiresPhone) {
    form.setValue("hostPhoneNumber", "", { shouldValidate: true, shouldDirty: true });
  }
  if (!opt.requiresValue) {
    form.setValue("locationValue", "", { shouldValidate: true, shouldDirty: true });
  }
}}
```

## Why this fixes the root cause
The Location step validates `hostPhoneNumber` and `locationValue` unconditionally.
The bug was a stale, partial `hostPhoneNumber` (`"+91 "`) left in form state after
switching away from a phone-call option, which failed the field's zod refine and made
`form.trigger` return false — silently blocking the Next button.

Clearing `hostPhoneNumber` whenever the new type does not `requiresPhone` (and
`locationValue` whenever it does not `requiresValue`) removes the stale value the
moment the user switches type. An empty `hostPhoneNumber`/`locationValue` passes
validation for non-phone / non-value types (the refine short-circuits on empty), so
the Next button advances correctly. `shouldValidate: true` also clears any lingering
inline error. Switching *to* a phone/value type keeps its field intact (guarded by
`requiresPhone`/`requiresValue`), so no valid input is lost.

## How verified
- `npx tsc --noEmit` passes clean.
- Logic trace: select "Phone call (they call)" → `PhoneInput` auto-fills `"+91 "` →
  switch to Google Meet → handler runs `setValue("hostPhoneNumber", "")` → Next runs
  `form.trigger([...])` → empty phone passes refine → `setActiveTab` advances to
  Booking Form.
