# Solution: Opening the "Menu" dropdown on booking/confirmation pages jerks the page horizontally

**Date:** 2026-07-22
**Pairs with:** [2026-07-22-bug-menu-dropdown-horizontal-jerk.md](./2026-07-22-bug-menu-dropdown-horizontal-jerk.md)

## What changed
Set `modal={false}` on both "Menu" `DropdownMenu` instances:
- [confirmation-client.tsx:172](../../app/(booking)/confirmed/_components/confirmation-client.tsx#L172)
- [booking-calendar.tsx:959](../../app/(booking)/[username]/[eventSlug]/_components/booking-calendar.tsx#L959)

## Why this fixes the root cause
`modal={false}` tells Radix's `DropdownMenu.Root` not to lock body scroll or trap
focus when it opens — it behaves as a plain popover instead of a modal dialog.
Since it no longer touches `<body>`'s scroll/overflow state, it no longer computes
or applies its own scrollbar-width compensation, so it stops fighting the global
`scrollbar-gutter: stable` reservation in `globals.css`. Neither mechanism resizes
anything when the menu opens, so there's nothing left to cause the jerk. Clicking
outside the menu or pressing Escape still closes it as expected — non-modal
dropdown menus are the standard Radix pattern for lightweight utility menus that
don't need to block interaction with the rest of the page.

## How verified
- `npx tsc --noEmit` — clean.
- Confirmed both dropdowns are the only two `<DropdownMenu>` usages under
  `app/(booking)/` (the pages affected by the reported jerk), and both now pass
  `modal={false}`.
