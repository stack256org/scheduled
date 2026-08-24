# Bug: Guided tour popup has no visible border in dark theme

## What's broken
The onboarding guided-tour popup ("Welcome to Schduled", step 1 of 6, and
every other modal/spotlight step) has no visible edge against the dark
overlay behind it in dark theme — the card blends into the backdrop.

## Where
`components/tour/guided-tour.tsx` — the shared `card` JSX used by both the
centered (welcome/completion) and spotlight-anchored tour layouts.

## How it was found
User screenshot of the "Welcome to Schduled" step in dark theme, showing the
card with no discernible border/edge.

## Root cause
The card wrapper used `border border-border bg-background`. In dark theme
`--border` is `oklch(1 0 0 / 9%)` — white at 9% opacity — which reads as
essentially invisible against the `bg-black/45` backdrop and the card's own
near-identical `--background`. The project's design system already has a
documented pattern for exactly this case: floating UI elements (dialogs,
popovers) use `ring-1 ring-foreground/10` with `bg-popover` instead of a
`border`/`bg-background` pair — see `components/ui/dialog.tsx` and
`components/ui/alert-dialog.tsx`. The guided tour card was never updated to
follow it.
