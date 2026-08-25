# Reschedule Approval (Guest-Initiated)

When a **guest** asks to move an already-**confirmed** meeting, the change is not
applied immediately — it becomes a **reschedule request** the host must approve or
reject. The original meeting stays booked until the host decides. A **host** who
reschedules their own booking still applies the change immediately (no
self-approval).

---

## Overview

Previously, a guest clicking the reschedule link on a confirmed booking instantly
overwrote the meeting time, and the guest received a misleading "Booking request
received / Awaiting approval" email (as if they'd made a brand-new booking). This
feature makes a guest reschedule of a confirmed booking a first-class approval
workflow that mirrors the initial new-booking approval flow.

**What it does:**
1. Guest requests a new time on a confirmed booking → booking enters
   `reschedule_requested`; the original `start_time`/`end_time` are untouched.
2. Host sees the request in the **Pending** tab (and via email + notification)
   with a clear **Current → Requested** view.
3. Host **approves** → the new time is applied, booking returns to `confirmed`,
   guest gets a "Meeting Rescheduled" email.
4. Host **rejects** → the original meeting stands, guest gets a "Reschedule
   request declined" email reassuring them the meeting is still on.

**Out of scope / unchanged:**
- Host-initiated reschedule (from `/bookings`, logged in) stays immediate.
- Guest rescheduling a still-`pending` (not yet approved) booking is unchanged.

---

## User Stories

**Guest**
- As a guest, when I request a new time for a confirmed meeting, I want the host
  to approve it, so I can't unilaterally change a meeting they committed to.
- As a guest, if my request is declined, I want to be told my original meeting is
  still confirmed, so I'm not confused about whether I still have a meeting.

**Host**
- As a host, I want a guest's reschedule request to show up in my Pending list
  next to new-booking requests, clearly marked, so I can act on it.
- As a host, I want the request to show the current time and the requested time
  side by side, so I understand exactly what's changing.
- As a host, when I reschedule my own booking, I don't want to approve my own
  change.

---

## Status flow

```
Confirmed
   │  guest requests new time
   ▼
Reschedule Requested        (original time still held)
   ├── host approves ──► Confirmed (new time)   → "Meeting Rescheduled" email
   └── host rejects  ──► Confirmed (old time)   → "Reschedule Declined" email
```

`booking_status` gained a `reschedule_requested` value. The proposed time is
staged in `booking.reschedule_requested_start` / `_end`; it is written to
`start_time`/`end_time` only on approval. The host's review link reuses the
existing `approval_token` column.

---

## Behavior details

### Actor detection — `app/api/bookings/reschedule/route.ts`
The reschedule endpoint checks the session. If the caller is the logged-in host
of the booking, the reschedule applies immediately (existing behavior). Otherwise
(a guest on the public link) rescheduling a `confirmed` (or already
`reschedule_requested`) booking stages a request instead of mutating the time.

### Approval / rejection
- `POST /api/bookings/reschedule-approve` — requires `reschedule_requested`;
  re-checks slot conflicts against the **proposed** time (advisory lock, like the
  initial approve route); on success applies the time, sets `confirmed`, clears
  the staged fields + `approval_token`, increments `reschedule_count`, and
  enqueues the "Meeting Rescheduled" email + calendar update + reminder refresh.
- `POST /api/bookings/reschedule-reject` — requires `reschedule_requested`;
  restores `confirmed` at the original time, clears the staged fields, and
  enqueues the "declined" email. Times are never touched.

### Host surfaces
- **Pending tab** (`app/(app)/bookings`) includes `reschedule_requested` rows,
  badged `🔄 Reschedule requested → <new time>`, with Approve / Decline actions.
- **Booking detail** shows the requested time and Approve / Decline reschedule
  buttons.
- **Review page** (`/booking/review/[token]?type=reschedule`) renders
  Current → Requested and calls the reschedule approve/reject endpoints;
  `?action=approve` auto-approves from the email button.

### Slot holding
A `reschedule_requested` booking still **holds its original slot** everywhere
availability is computed (slots, available-days, conflict checks, booking limits,
host suspension/removal), so the original time can't be double-booked while a
request is pending. The proposed slot is not held; it is re-validated on approval.

---

## Emails

| Event | Recipient | Email |
|---|---|---|
| Guest requests reschedule | Host | **Reschedule request** (Current → Requested, Approve / Decline) |
| Guest requests reschedule | Guest | *(none — the request UI shows "Awaiting host approval")* |
| Host approves | Guest + Host | **Meeting Rescheduled** (reused existing template) |
| Host rejects | Guest | **Reschedule request declined** (original meeting remains confirmed) |

The old "Booking request received / Awaiting approval" email is only sent for
brand-new bookings and never on a reschedule.

Templates: `lib/email/templates/reschedule-request.ts`,
`lib/email/templates/reschedule-declined.ts`. Jobs: `booking.reschedule-request`,
`booking.reschedule-declined` (handlers under `lib/worker/handlers/`).

---

## Edge cases

- **Reminders:** existing 24h/1h reminders keep firing for the original meeting
  while a request is pending (they self-skip only when `start_time` changes). On
  approval, the old reminders self-skip and reschedule reminders take over. No
  reminder is cancelled at request time.
- **Cancellation while pending:** cancelling the booking discards the request
  (clears the staged times); the approve/reject endpoints then return
  *"This reschedule request is no longer valid,"* and the review link shows a
  friendly "no longer valid" screen instead of a 404.
- **Proposed slot taken before approval:** the approve endpoint returns *"The
  requested time is no longer available"* without mutating anything — the host can
  reject or ask the guest for another time.
- **Revised request:** a guest re-submitting while already `reschedule_requested`
  updates the proposed time and re-sends the host email.

Related: [booking-flow.md](./booking-flow.md), [single-use-links.md](./single-use-links.md),
[notifications-reminders.md](./notifications-reminders.md). Bug that prompted this:
`docs/bugs/2026-07-17-bug-guest-reschedule-no-approval.md`.
