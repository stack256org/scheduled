# Bug: Guest reschedule of a confirmed booking bypasses the host and sends a misleading email

## Symptom
After a booking was confirmed (guest booked → host approved), a guest who used the
reschedule link could **instantly change the confirmed meeting time** with no host
involvement. On top of that, the guest received a **"Your booking request has been
received / Awaiting approval"** email — as if they'd submitted a brand-new booking
request — even though they had an already-approved booking and did nothing to
create a new one. This was misleading and generated confusion/support noise.

## Where
- `app/api/bookings/reschedule/route.ts` — the reschedule endpoint applied the new
  time immediately for a confirmed booking and kept `status = 'confirmed'`.
- The public reschedule page `app/(booking)/reschedule/[token]` is used by BOTH
  host and guest (the host "Reschedule" button just links to it), so there was no
  distinction between a host moving their own booking and a guest requesting a
  change.

## How it was found / reproduced
Reported by the product owner. Reproduced against the dev DB: a `confirmed`
booking, opened via the guest reschedule link, moved to a new time — the booking's
`start_time` changed immediately and the invitee received the approval-pending
("Request received") email.

## Root cause
There was no concept of a *reschedule that requires approval*. The reschedule
route mutated `start_time`/`end_time` in place for any confirmed booking
regardless of who initiated it, and a guest could therefore move a host's
confirmed meeting unilaterally. The only "reschedule of a not-yet-approved
booking" path reused the new-booking approval email, which is why a reschedule
could surface the "Request received / Awaiting approval" wording that belongs only
to brand-new bookings.

This is a design gap rather than a one-line defect — the fix is a proper
guest-reschedule approval workflow (see the paired solution file and
`docs/features/reschedule-approval.md`).
