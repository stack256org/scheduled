# Bug: Opening the "Menu" dropdown on booking/confirmation pages jerks the page horizontally

**Date:** 2026-07-22
**Area:** Public booking page header + booking confirmation page header
**Files:**
- [app/(booking)/confirmed/_components/confirmation-client.tsx](../../app/(booking)/confirmed/_components/confirmation-client.tsx)
- [app/(booking)/[username]/[eventSlug]/_components/booking-calendar.tsx](../../app/(booking)/[username]/[eventSlug]/_components/booking-calendar.tsx)

## Symptom
On the "Request Submitted!" / booking confirmation page (and the owner toolbar on
the live booking page), clicking the "Menu" dropdown trigger causes the whole card
to visibly shift horizontally for a frame before settling.

## How reproduced
1. Submit or view a booking that lands on `/confirmed` (or view your own booking
   page as the owner).
2. Click the "Menu" button in the header.
3. The card/content jerks sideways as the menu opens.

## Root cause
`app/globals.css` sets `scrollbar-gutter: stable` on `html` specifically to keep
scrollbar-caused width constant (see the comment at `globals.css:13-17`) — so a
page that scrolls on `<body>` never resizes when a scrollbar appears/disappears.

Radix's `DropdownMenu` (used via `components/ui/dropdown-menu.tsx`) is **modal**
by default: opening it locks body scroll and independently measures/compensates
for the scrollbar it expects to disappear, adding its own right-side padding.
Because the gutter is already permanently reserved by `scrollbar-gutter: stable`,
Radix's compensation stacks on top of the already-reserved space instead of
replacing it — over-compensating and producing the visible horizontal jerk when
the dropdown opens.

This only affects Radix menus that are still `modal` (the default) on pages using
the global `scrollbar-gutter: stable` fix; menus that don't need to trap focus /
block background interaction (like a small "Menu" utility dropdown) don't need
modal behavior in the first place.
