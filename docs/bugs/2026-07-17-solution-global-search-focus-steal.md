# Solution: Global search bar unusable — clicking it does nothing

**Date:** 2026-07-17
**Pairs with:** [2026-07-17-bug-global-search-focus-steal.md](./2026-07-17-bug-global-search-focus-steal.md)

## What changed
[components/scaffold/global-search.tsx](../../components/scaffold/global-search.tsx) —
added `onOpenAutoFocus={(e) => e.preventDefault()}` to the `<PopoverContent>` that
renders the results dropdown.

```tsx
<PopoverContent
  align="start"
  className="w-[340px] p-1"
  onOpenAutoFocus={(e) => e.preventDefault()}
>
```

## Why this fixes the root cause
By default Radix `PopoverContent` fires `onOpenAutoFocus` when it opens and moves
focus into the popover. Because focusing the input opens the popover instantly (the
empty query matches all static pages, so `totalCount > 0`), focus was being yanked
out of the input the moment the user clicked it — making the field impossible to
type in.

Calling `e.preventDefault()` in `onOpenAutoFocus` cancels that focus move, so focus
stays in the input. The user can now type, the debounced `/api/search` query runs,
and result rows remain clickable. This is the standard Radix combobox pattern for a
text input that drives a Popover.

## How verified
- `npx tsc --noEmit` passes clean.
- Focus behavior: opening the popover no longer relocates focus (autofocus
  prevented), so keystrokes land in the input and the query state updates, which in
  turn drives `matchingPages` and the debounced fetch.
