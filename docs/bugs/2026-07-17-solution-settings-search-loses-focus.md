# Solution: Settings "Search settings…" box loses focus after first keystroke

## What changed
- `app/(app)/settings/_components/settings-search.tsx` — added
  `onOpenAutoFocus={(e) => e.preventDefault()}` to the `PopoverContent`
  rendering the search results.

```tsx
<PopoverContent
  align="start"
  className="w-72 p-1"
  onOpenAutoFocus={(e) => e.preventDefault()}
>
```

## Why this fixes the root cause
`onOpenAutoFocus` is the Radix hook fired right when `Popover.Content` mounts
and normally moves DOM focus into the popover. Calling
`preventDefault()` on that event cancels the focus steal, so focus stays on
the `Input` for the entire typing session. The results list still opens and
updates live via the existing `results` memo — only the unwanted focus jump
is suppressed. This mirrors the standard Radix pattern for
search/combobox-style popovers where the trigger is a text input.

## How it was verified
- `npx tsc --noEmit` passes clean.
- Flow reasoning: input keeps focus across keystrokes since the popover no
  longer redirects it, so `onChange` continues to fire and `results` keeps
  updating for every character typed.
