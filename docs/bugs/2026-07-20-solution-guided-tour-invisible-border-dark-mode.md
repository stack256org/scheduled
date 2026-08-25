# Solution: Guided tour popup has no visible border in dark theme

## What changed
`components/tour/guided-tour.tsx` — the shared tour card wrapper:

```diff
- <div className="relative w-full max-w-sm border border-border bg-background">
+ <div className="relative w-full max-w-sm bg-popover ring-1 ring-foreground/10">
```

## Why this fixes the root cause
`border-border` was nearly invisible in dark theme because `--border` is
white at only 9% opacity there. Swapping to `ring-1 ring-foreground/10` +
`bg-popover` matches the pattern already used by every other floating
element in the design system (`components/ui/dialog.tsx`,
`components/ui/alert-dialog.tsx`, `components/ui/popover.tsx`), which reads
correctly in both themes and is the CLAUDE.md-documented exception to the
"no shadows" rule for floating UI. `bg-popover` is also a touch lighter than
`bg-background` in dark theme, giving the card proper visual separation from
the dimmed backdrop behind it.

## How it was verified
- `npx tsc --noEmit` passes clean.
- Confirmed via `app/globals.css` that dark theme's `--popover` (`oklch(0.180
  ...)`) sits above `--background` (`oklch(0.145 ...)`), and that
  `ring-foreground/10` is the same visibility mechanism already relied on by
  Dialog/AlertDialog/Popover in dark theme.
