# Solution: Guest reschedule of a confirmed booking now requires host approval

## What changed
A guest reschedule of a **confirmed** booking is now a **host-approved request**
instead of an instant change. A host rescheduling their own booking stays
immediate. Full capability write-up:
`docs/features/reschedule-approval.md`.

### Data model
- `booking_status` gained `reschedule_requested`
  ([db/schema/enums.ts](../../db/schema/enums.ts)).
- `booking` gained `reschedule_requested_start` / `reschedule_requested_end`
  ([db/schema/bookings.ts](../../db/schema/bookings.ts)) to stage the proposed
  time. Migration `db/migrations/0017_productive_red_ghost.sql` (non-destructive:
  enum add + two nullable columns). The host review link reuses the existing
  `approval_token` column.

### Behavior
- `app/api/bookings/reschedule/route.ts` — detects the actor via
  `getCurrentSession()`. Logged-in host of the booking → immediate (unchanged).
  Guest on a `confirmed` (or already `reschedule_requested`) booking → stages the
  proposed time, sets `reschedule_requested`, and enqueues
  `BOOKING_RESCHEDULE_REQUEST` (host email + notification). `start_time`/`end_time`
  are left untouched; the guest gets no email (their UI shows "Awaiting host
  approval").
- `app/api/bookings/reschedule-approve/route.ts` — re-checks conflicts against the
  proposed time, applies it, returns to `confirmed`, clears the staged fields +
  `approval_token`, bumps `reschedule_count`, and enqueues the existing "Meeting
  Rescheduled" email + calendar update + reminder refresh.
- `app/api/bookings/reschedule-reject/route.ts` — restores `confirmed` at the
  original time, clears the staged fields, enqueues `BOOKING_RESCHEDULE_DECLINED`.

### Why this fixes the root cause
- A guest can no longer change a host's confirmed meeting unilaterally — the time
  only moves when the host approves.
- The misleading "Request received / Awaiting approval" email no longer fires on a
  reschedule; that email is now only used for brand-new bookings. Guests instead
  get "Meeting Rescheduled" (approve) or "Reschedule request declined" (reject).

### Supporting changes
- New emails: `lib/email/templates/reschedule-request.ts` (Current → Requested,
  Approve/Decline), `lib/email/templates/reschedule-declined.ts` (reassures the
  original meeting stands). New jobs `booking.reschedule-request` /
  `booking.reschedule-declined` + handlers.
- Host surfaces: `reschedule_requested` shows in the Pending tab and booking
  detail with a "Reschedule requested → new time" badge and Approve/Decline; the
  `/booking/review/[token]?type=reschedule` page renders Current → Requested.
- Backward-compat: `reschedule_requested` added to every active-slot filter
  (slots, available-days, conflict checks, limits, host cleanup) so the original
  slot stays blocked while a request is pending; plus status/notification maps.
- Edge cases: reminders keep firing for the original time until approval;
  cancelling while pending discards the request (approve/reject then return "no
  longer valid"); a proposed slot taken before approval yields a clear "requested
  time is no longer available" error without mutating anything.

## How it was verified
End-to-end against the running dev app + DB:
- Guest request → `reschedule_requested`, `start_time` unchanged, host emailed,
  no "Request received" email to the guest.
- Approve → time applied, `confirmed`, `reschedule_count` incremented, guest gets
  "Rescheduled".
- Reject → original time preserved, guest gets "declined".
- Cancel while pending → staged fields cleared; approve/reject both return
  "This reschedule request is no longer valid" (409); stale review link renders a
  friendly "no longer valid" page (HTTP 200, not 404).
- Active review page renders "Review reschedule request" with Current → Requested.
- `tsc --noEmit` passes clean.
