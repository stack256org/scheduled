# Bug: Browser autofill/password suggestion popup drifts when scrolling

## What's broken
When a focused input (e.g. "Current password" on `/profile/security`) shows
the browser's native saved-password/autofill suggestion popup, scrolling the
page makes the popup appear to detach and float away from the input instead
of staying anchored to it.

## Where
Any focused `<input>`/`<select>`/`<textarea>` inside the authenticated app
shell — reproduced on `/profile/security` (Change Password form), but the
cause is structural (`components/scaffold/app-shell.tsx`), not specific to
that form.

## How it was found
User reported: focusing the "Current password" field on the Security
settings page triggers Chrome's saved-password suggestions, and scrolling the
page makes that suggestion box move independently of the input.

## Root cause
`components/scaffold/app-shell.tsx` scrolls its page content inside an inner
`<main data-app-main class="overflow-y-auto">` element, not the window
(`<div data-app-shell class="... overflow-hidden">` at the root disables
window-level scrolling entirely). Chrome positions native form-control
popups — autofill/password suggestions, `<select>` dropdowns — against the
focused element's screen coordinates, and only re-tracks or auto-closes them
on **window** scroll events. Scrolling an inner container doesn't fire that
signal, so the popup stays pinned at its original screen position while the
input moves underneath it, reading as the popup "moving."
