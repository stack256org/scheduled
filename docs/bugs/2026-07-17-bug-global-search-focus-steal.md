# Bug: Global search bar unusable — clicking it does nothing

**Date:** 2026-07-17
**Area:** Global search (app header)
**File:** [components/scaffold/global-search.tsx](../../components/scaffold/global-search.tsx)

## Symptom
Clicking the global search bar in the app header does nothing usable. The dropdown
flashes but the field feels dead — you cannot type a query into it.

## Where
`GlobalSearch()` in `components/scaffold/global-search.tsx`. The header `<input>`
(lines 126–134) is wrapped in `<PopoverTrigger asChild>`, and the results dropdown
is a Radix `<PopoverContent>` (line 137).

## How reproduced
1. Load any authenticated app page.
2. Click the search input in the header.
3. The dropdown appears (Pages list) but the text cursor is not in the input;
   typing does not update the field.

## Root cause
Focusing the input sets `open = true` (`onFocus`, line 129). Because the empty
query already matches all 7 static pages, `totalCount > 0` (line 89–90), so the
Popover opens immediately (`open={open && totalCount > 0}`, line 112).

Radix `PopoverContent` fires `onOpenAutoFocus` on open and moves focus **into the
popover content**, blurring the input the instant it opens. Focus never stays in the
field, so keystrokes are not captured and the search bar appears non-functional.

This is the well-known Radix pitfall when a text input drives a Popover (combobox
pattern): the content must be told not to grab focus on open.
