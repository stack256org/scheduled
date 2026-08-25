# Bug: Settings "Search settings…" box loses focus after first keystroke

## What's broken
On `/settings/*` pages, typing into the "Search settings…" box in the sidebar
appears to only register the first character — further typing does nothing,
making the search unusable.

## Where
`app/(app)/settings/_components/settings-search.tsx` — the `SettingsSearch`
component (input inside a Radix `Popover`).

## How it was found
User reported the "Search settings" bar on `/settings/my-link` "not working
proper."

## Root cause
The search `Input` is wrapped as the `PopoverTrigger`, and `open` is set to
`true` in the input's `onChange` handler as soon as there's a non-empty query.
Radix `Popover.Content` auto-focuses itself when it opens
(`onOpenAutoFocus`), which happens right after the first keystroke. That
steals DOM focus away from the `Input` into the popover content, so
subsequent keystrokes never reach the input's `onChange` — the field looks
frozen after one character.
