# Notifications & Reminders

Notifications and reminders keep hosts and invitees informed before, during, and after every meeting. Automated workflows reduce no-shows, improve engagement, and eliminate the need to manually follow up after each booking.

---

## Overview

Schduled sends notifications through two channels:
1. **Transactional emails** — Booking confirmations, cancellations, reschedules (triggered instantly) *(MVP)*
2. **Pre-meeting reminders** — Hardcoded 24-hour and 1-hour emails before every meeting *(MVP)*; configurable workflow builder (custom triggers, conditions, actions) and SMS sequences *(Phase 2)*

For MVP: every booking automatically gets 24h and 1h reminders — no configuration needed. The full workflow builder (where hosts create custom trigger → condition → action sequences) ships in Phase 2 after real users show what they actually need.

---

## User Stories

**Host**
- As a host, I want to receive an instant email when someone books, cancels, or reschedules, so that I am always up to date without checking the dashboard. *(MVP)*
- As a host, I want my invitees to automatically receive 24-hour and 1-hour reminder emails, so that no-shows are reduced without any manual effort from me. *(MVP)*
- As a host, I want to customize the from-name and reply-to on all emails, so that invitees see my name rather than "Schduled". *(MVP)*
- As a host, I want to add a custom message to confirmation and reminder emails, so that I can include meeting instructions or next steps. *(MVP)*
- As a host, I want post-meeting follow-up emails to be sent automatically after a meeting ends, so that I do not have to remember to follow up with every invitee. *(Phase 2)*

**Invitee**
- As an invitee, I want to receive a confirmation email immediately after booking, so that I have proof the meeting is scheduled and know how to join. *(MVP)*
- As an invitee, I want to receive a reminder email 24 hours before my meeting, so that I do not forget about it. *(MVP)*
- As an invitee, I want to receive a reminder email 1 hour before my meeting, so that I have time to prepare and find the join link. *(MVP)*
- As an invitee, I want cancellation and reschedule links in every email, so that I can update my booking at any time without contacting the host. *(MVP)*

---

## Transactional Notifications

These fire automatically at specific lifecycle events — no configuration required.

### Booking Confirmation (to Invitee)

Sent immediately when a meeting is booked.

**Default Contents:**
- "Your meeting is confirmed" subject line
- **Your time: [date] at [time] [invitee timezone]** — e.g., "Thursday, June 5 at 3:00 PM IST"
- **Host's time: [time] [host timezone]** — e.g., "That's 10:00 AM EST for Jane Smith"
- Duration
- Location: video link (Zoom/Meet/Teams) or physical address or phone number
- Calendar download buttons: Google Calendar | iCal | Outlook
- Invitee's own form answers (for their records)
- Reschedule link
- Cancellation link
- Custom confirmation message from host (if set)

> Calendly only shows the invitee's timezone in this email. Schduled also shows the host's equivalent time so the invitee is never uncertain about what time the host is expecting them.

**Customization:**
- Subject line with dynamic variables
- From name (e.g., "Jane from Acme Corp")
- Reply-to address
- Logo and brand colors
- Custom message in body

---

### Booking Notification (to Host)

Sent immediately when a new booking is created.

**Default Contents:**
- "New booking: [event type] — [invitee name]" subject line
- Invitee name, email, phone (if provided)
- **Your time: [date] at [time] [host timezone]** — e.g., "Thursday, June 5 at 10:00 AM EST"
- **Invitee's time: [time] [invitee timezone]** — e.g., "That's 3:00 PM IST for Jane Smith"
- Duration and event type name
- Answers to all custom intake questions
- One-click cancel link
- Link to meeting detail in dashboard

**Use Case:** Host receives instant notification via email. Slack integration is Phase 2.

---

### Cancellation Confirmation (to Invitee)

Sent when an invitee cancels.

**Contents:**
- "Your meeting has been cancelled" subject line
- **Cancelled meeting time in invitee's timezone** — e.g., "Thursday, June 5 at 3:00 PM IST"
- **Host's equivalent time** — e.g., "That was 10:00 AM EST for Jane Smith"
- Cancellation reason (if provided)
- Direct link to rebook (same event type)
- Optional custom message from host (e.g., "Sorry we missed you — feel free to rebook anytime")

---

### Cancellation Notification (to Host)

Sent when an invitee cancels.

**Contents:**
- "Meeting cancelled: [invitee name] — [event type name]" subject line
- Invitee name and email
- **Cancelled meeting time in host's timezone** — e.g., "Thursday, June 5 at 10:00 AM EST"
- **Invitee's local time** — e.g., "That was 3:00 PM IST for Jane Smith"
- Cancellation reason (if provided)
- Link to view in Meetings Dashboard

---

### Reschedule Confirmation

Sent to both host and invitee when a meeting is rescheduled.

**Contents (to invitee):**
- "Your meeting has been rescheduled" subject line
- **New time in invitee's timezone** — e.g., "New time: Friday, June 6 at 4:00 PM IST"
- **Host's new time** — e.g., "That's 10:30 AM EST for Jane Smith"
- Original time shown for reference (crossed out or labelled "was:")
- Updated calendar link (replaces old event)
- Updated video link if location changed

**Contents (to host):**
- **New time in host's timezone** — e.g., "New time: Friday, June 6 at 10:30 AM EST"
- **Invitee's new time** — e.g., "That's 4:00 PM IST for Jane Smith"
- Original time shown for reference
- Link to updated meeting in dashboard

---

### Host Cancellation Notification (to Invitee)

Sent when a host cancels a meeting.

**Contents:**
- "[Host name] has cancelled your meeting" subject line
- **Cancelled meeting time in invitee's timezone** — e.g., "Thursday, June 5 at 3:00 PM IST"
- **Host's equivalent time shown for reference** — e.g., "That was 10:00 AM EST"
- Optional reason from host
- Direct link to rebook with the same host (same event type booking page)

---

## Workflow Automations

> **MVP:** Hardcoded 24h and 1h reminder emails only — no builder UI, no configurable triggers. 90% of users want exactly this and nothing more. The full configurable workflow builder ships in Phase 2.

Workflows are timed multi-step sequences that fire before or after meetings. They are the "set and forget" layer of communication.

### What Is a Workflow? *(Post-MVP — Phase 2 — Configurable Builder)*

> The trigger → condition → action builder described below is a **Phase 2 feature**. For MVP, the 24-hour and 1-hour reminders are hardcoded — they fire for every booking automatically without any host configuration.

A configurable workflow (Phase 2) is composed of:
- **Trigger** — When should this run? (e.g., 24 hours before meeting)
- **Condition** — Which event types does this apply to? (optional filter)
- **Action** — What should happen? (send email; send SMS *(Phase 2)*)

### Workflow Triggers *(Post-MVP — Phase 2 — Configurable Builder)*

> This full trigger system requires the Phase 2 workflow builder UI. MVP fires only the two hardcoded triggers: 24h before and 1h before.

| Trigger | Description |
|---------|-------------|
| Before event starts | X minutes/hours/days before the meeting begins |
| After event ends | X minutes/hours/days after the meeting ends |
| On booking | When a new meeting is booked |
| On cancellation | When an invitee cancels |
| On reschedule | When an invitee reschedules |
| No-show detected | When meeting time passes without any activity |

---

## Reconfirmation Workflow *(Post-MVP — Phase 2)*

For meetings booked far in advance, a reconfirmation email verifies the invitee still plans to attend — reducing no-shows caused by forgotten bookings.

### How Reconfirmation Works
1. Reconfirmation email sent X days before the meeting (configurable — typically 48 hours before)
2. Email includes a prominent "Confirm Attendance" button
3. Invitee clicks the button → one-click confirmation on a simple web page
4. Host sees "Confirmed" status on that booking in the dashboard
5. If invitee does NOT confirm: host is notified; option to follow up or cancel proactively

### Reconfirmation Email Contents
- "Just checking in — your meeting is coming up"
- Meeting summary (date, time, location, host name)
- Large **"Confirm Attendance"** button
- Alternative: "Reschedule" and "Cancel" links if plans have changed

### Reconfirmation Configuration
- Enable/disable per event type
- Set timing: 72 hours before / 48 hours before / 24 hours before / custom
- Set what happens if invitee doesn't confirm: no action / notify host / auto-cancel

### When to Use Reconfirmation
- Meetings booked more than 1 week in advance
- High-value meetings (demos, consultations) where no-shows are costly
- Any meeting where pre-meeting preparation is required

---

## No-Show Tracking

### Marking No-Shows *(MVP)*
- When meeting time passes, host can manually mark the booking as "No-Show" in the Meetings Dashboard
- No-show status stored on the booking record
- Visible in the Meetings Dashboard past meetings list

### Automated No-Show Follow-Up Workflow *(Post-MVP — Phase 2)*
After the host marks a meeting as no-show (or automatically after X hours if no activity):
1. Automated email sent to invitee: "Looks like we missed each other"
2. Email includes a direct link to rebook
3. Warm, non-blaming tone (configurable message)
4. Host receives notification that follow-up was sent

### No-Show Follow-Up Email Contents *(Post-MVP)*
- "Hi [Name], sorry we missed our call today"
- Brief note that the slot is available to rebook
- Direct booking link for the same event type
- Host contact info for alternative scheduling

### No-Show Analytics *(Post-MVP — Phase 2)*
- No-show rate tracked per event type
- % of no-shows that rebooked after follow-up
- Visible in the Analytics Dashboard

### Workflow Actions

| Action | MVP / Post-MVP | Description |
|--------|---------------|-------------|
| Send email to invitee | ✅ MVP (hardcoded 24h + 1h only) | Reminder email sent to the person who booked |
| Send email to host | ✅ MVP (transactional only) | Instant notification to the meeting host on lifecycle events |
| Send email to other | Phase 2 (workflow builder) | Email sent to a CC'd third party (e.g., team member, manager) — requires configurable workflow |
| Send SMS to invitee | Phase 2 | Text message to the invitee's phone number |
| Send SMS to host | Phase 2 | Text message to the host |
| Send webhook | Phase 2 | HTTP POST to external URL with booking data |

---

## Pre-Meeting Reminders

The most impactful use of workflows — reducing no-shows by reminding invitees before the meeting.

### Recommended Reminder Sequence
1. **24 hours before** — Email reminder with meeting details and prep materials *(MVP)*
2. **1 hour before** — Email reminder with direct video link *(MVP)*
3. **15 minutes before** — SMS reminder with video link (highest open rate) *(Post-MVP — Phase 2)*

### Reminder Email Content *(MVP)*
- **Your time: [date] at [time] [invitee timezone]** — e.g., "Tomorrow at 3:00 PM IST"
- **Host's time: [time] [host timezone]** — e.g., "That's 10:00 AM EST for Jane Smith" — repeated in every reminder so invitees never need to do timezone math
- Duration and event type name
- Video conference link (prominent, large "Join Meeting" button)
- Location details (address or call-in number if not video)
- Host name and profile photo
- Custom message from host (agenda, preparation instructions)
- Reschedule / cancel links

> **Calendly comparison:** Calendly reminder emails show only the invitee's timezone. Schduled shows both timezones in every reminder — the same differentiator as the confirmation email.

### SMS Reminders *(Post-MVP — Phase 2)*
- Short, direct: "Reminder: Your call with Jane starts in 1 hour. Join here: [link]"
- Also includes both times: "3 PM for you / 10 AM for Jane"
- Requires invitee phone number (asked in booking form)
- International numbers supported

---

## Post-Meeting Follow-Ups *(Post-MVP — Phase 2)*

> **Not in MVP.** Post-meeting follow-ups require the configurable workflow builder to trigger "X minutes after meeting ends." For MVP, hardcoded reminders fire before the meeting only. Add follow-up workflows in Phase 2 once you have real users who ask for them.

Automated messages sent after the meeting to nurture the relationship.

### Thank You / Follow-Up Email *(Post-MVP — Phase 2)*
- Sent 30 minutes after meeting ends (configurable)
- "Thanks for meeting" message
- Links to next steps (book another call, review proposal, etc.)
- Feedback/rating request (1–5 stars or short survey)

### No-Show Follow-Up *(Post-MVP — Phase 2)*
- Triggered when the meeting time has passed with no activity
- "Looks like we missed each other" message
- Offer to reschedule directly
- Host can disable if not desired

### Outcome-Based Follow-Up *(Post-MVP — Phase 2)*
- Triggered by host marking a meeting outcome (e.g., "Qualified", "Not a fit")
- Sends different email based on outcome

---

## Dual Timezone Display in Every Email

This is a deliberate Schduled differentiator. Every email that mentions a meeting time shows **both the recipient's local time and the other party's local time**.

### Why This Matters

Calendly only shows one timezone per email — the recipient's own timezone. This causes a common failure:

> An invitee in India books a call with a host in New York. The invitee's confirmation says "3:00 PM IST". They assume the host is also on at 3 PM. They show up 10 hours early or miss the meeting entirely.

Schduled eliminates this by always showing both:

### What Each Person Sees

**Invitee (in India) receives:** their local time (e.g., "Thursday, June 5 at 3:00 PM IST (Asia/Kolkata)") plus the host's equivalent time (e.g., "Host's meeting time: Thursday, June 5 at 10:00 AM EST (America/New_York)").

**Host (in New York) receives:** their own local time (e.g., "Thursday, June 5 at 10:00 AM EST (America/New_York)") plus the invitee's equivalent time (e.g., "Invitee's local time: Thursday, June 5 at 3:00 PM IST (Asia/Kolkata)").

### Which Emails Show Both Timezones

| Email Type | Both Timezones Shown |
|-----------|---------------------|
| Booking confirmation to invitee | ✅ Yes |
| Booking notification to host | ✅ Yes |
| 24-hour reminder to invitee | ✅ Yes |
| 1-hour reminder to invitee | ✅ Yes |
| Reschedule confirmation (to both) | ✅ Yes |
| Cancellation confirmation | ✅ Yes — shows the cancelled time in both zones |
| Post-meeting follow-up | ✅ Yes — references the time of the meeting that just occurred |
| ICS calendar invite description | ✅ Yes — both times in plain text inside the description field |

### Edge Cases Handled

- **Same timezone:** When host and invitee are in the same timezone, only one time row is shown (no redundant "your time / their time" duplication)
- **Half-hour offset timezones:** IST (UTC+5:30), NPT (UTC+5:45) — displayed correctly, not rounded
- **Date boundary crossover:** If the host's time is "10 PM Monday" and the invitee's time is "8:30 AM Tuesday", the correct date is shown for each party — not the same date for both

---

## Dynamic Variables in Emails *(and SMS — Phase 2)*

> **MVP:** All default email templates use these variables internally — invitee name, both timezone times, video link, and form answers are all auto-populated in hardcoded templates. No UI is needed for this to work.
>
> **Phase 2:** The full template editor UI — where hosts write custom email bodies and subject lines using `{invitee_name}`, `{host_time}`, etc. — ships in Phase 2. For MVP, hosts can only add a plain-text custom message at the bottom of each email type. Do not build a variable editor for MVP.

All default templates auto-fill with meeting data using these variables:

### Available Variables

| Variable | Description |
|----------|-------------|
| `{invitee_name}` | Full name of the person who booked |
| `{invitee_email}` | Invitee's email address |
| `{host_name}` | Name of the meeting host |
| `{event_type}` | Name of the event type |
| `{date}` | Meeting date (formatted for invitee's locale) |
| `{time}` | Meeting start time in **invitee's timezone** |
| `{timezone}` | Invitee's timezone name (e.g., "IST") |
| `{host_time}` | Meeting start time in **host's timezone** — for showing the other party's local time |
| `{host_timezone}` | Host's timezone name (e.g., "EST") |
| `{invitee_time}` | Meeting start time in **invitee's timezone** — for use in host-facing emails |
| `{invitee_timezone}` | Invitee's timezone name — for use in host-facing emails |
| `{duration}` | Meeting length (e.g., "30 minutes") |
| `{location}` | Video link or address |
| `{reschedule_link}` | Direct link to reschedule |
| `{cancel_link}` | Direct link to cancel |
| `{booking_id}` | Unique booking identifier |
| `{answer_1}` through `{answer_10}` | Answers to custom intake questions |

---

## In-App Notifications

Beyond email (and SMS in Phase 2), notifications appear in the Schduled dashboard.

### Dashboard Notification Feed
- New booking notifications
- Cancellation alerts
- Reschedule notifications
- Team booking activity (for admins)

### Browser Push Notifications
- Optional push notifications for new bookings
- Opt-in via browser permission prompt
- Works in Chrome, Firefox, Edge, Safari (iOS 16.4+)

### Mobile Push Notifications *(Post-MVP — Phase 3)*
- Instant push notification via Schduled mobile app
- Configurable: all bookings, cancellations only, or nothing

---

## Slack Integration *(Post-MVP — Phase 2)*

For teams using Slack, booking notifications can be sent to Slack channels. Not included in MVP — requires team workspace feature and OAuth bot setup.

### Planned Slack Notifications (Phase 2)
- New booking → post to configured `#channel`
- Cancellation → post alert to channel
- Round-robin assignment → notify assigned rep
- Custom message format with meeting details

---

## Notification Preferences

Both hosts and invitees can manage notification preferences.

### Host Preferences
- Toggle email for each event type (new booking, cancel, reschedule) *(MVP)*
- Toggle push notifications *(Phase 2)*
- Toggle SMS notifications *(Phase 2)*
- Enable/disable daily digest: summary of tomorrow's meetings

### Invitee Preferences
- Opt out of follow-up sequences via unsubscribe link
- CAN-SPAM and GDPR compliant opt-out
- Preference not stored beyond the booking (no account required)

---

## Reference Implementations

| App | Email Reminders | SMS Reminders | Both Timezones in Email | Reconfirmation |
|-----|----------------|--------------|------------------------|----------------|
| **Calendly** | ✅ Paid plans; 24hr + 1hr pre-built; custom workflows | ✅ Paid plans | ❌ Only invitee's timezone | ❌ No native reconfirmation |
| **Cal.com** | ✅ Free tier; email + SMS; webhook actions | ✅ Free tier | ❌ Only invitee's timezone | ❌ No |
| **Chili Piper** | Instant alerts to Slack/email for new leads; less focus on invitee reminders | ❌ No | ❌ No | ❌ No |
| **HubSpot Meetings** | Basic confirmations only; follow-up via HubSpot workflows | ❌ No | ❌ No | ❌ No |
| **SavvyCal** | ✅ Premium plan; email reminders | Limited | ❌ No | ❌ No |
| **Schduled** | ✅ All users; 24hr + 1hr in MVP; full workflow builder (Phase 2) — open source, no plan gating | ✅ Phase 2 | ✅ **Both timezones in every email** — key differentiator | ✅ Phase 2 |

---

## MVP Scope

**In MVP:**
- Booking confirmation email to invitee — with both timezones (invitee's time + host's time)
- Booking notification email to host — with both timezones (host's time + invitee's time)
- Cancellation confirmation to invitee (with both timezones)
- Cancellation notification to host (with both timezones)
- Reschedule confirmation to both parties (with both timezones)
- Host cancellation notice to invitee
- Pre-meeting reminder: 24-hour email (with both timezones) — **hardcoded, fires automatically for every booking**
- Pre-meeting reminder: 1-hour email (with both timezones) — **hardcoded, fires automatically for every booking**
- Default templates auto-populate: invitee name, both timezone times, video link, reschedule/cancel links, and form answers — all via internal variables, no editor UI needed
- Custom message per event type (plain text appended to confirmation email body)
- From name and reply-to customisation

> **Comparison:** Calendly requires a paid plan for reminder workflows. Schduled includes 24hr and 1hr email reminders for all users — no plan required (open source).

**Post-MVP:**
- Configurable workflow builder UI — custom trigger → condition → action sequences (Phase 2)
- Custom trigger timing (send at X hours/days before/after, not just hardcoded 24h/1h) (Phase 2)
- Custom email template editor with dynamic variable syntax `{invitee_name}`, `{host_time}`, etc. (Phase 2)
- Custom email subject lines with variable substitution (Phase 2)
- Send email to third-party CC (via workflow builder) (Phase 2)
- SMS reminders (Phase 2)
- Post-meeting follow-up workflow emails (Phase 2)
- No-show detection and automated follow-up email (Phase 2)
- Reconfirmation workflow — "Confirm Attendance" button for far-in-advance bookings (Phase 2)
- Slack integration for team booking notifications (Phase 2)
- Browser push notifications (Phase 2)
- Mobile push notifications (Phase 3 — mobile app)
- Outcome-based follow-up workflows (Phase 3)
- Unsubscribe management — GDPR-compliant opt-out (Phase 2)


---

## Email Queue Architecture

All emails are sent **asynchronously via pg-boss** — never inline in an API route or Server Action.

### Flow: Booking Confirmed → Emails Sent

```
1. Booking engine creates booking record (PostgreSQL transaction)
2. Inside same transaction:
   a. Insert rows into email_outbox (status='queued') — one for invitee, one for host
   b. Enqueue EMAIL_SEND jobs in pg-boss (one per outbox row)
   c. Schedule BOOKING_REMINDER_24H job (fires 24h before meeting)
   d. Schedule BOOKING_REMINDER_1H job (fires 1h before meeting)
3. Transaction commits
4. pg-boss EMAIL_SEND worker atomically claims the outbox row (WHERE status='queued')
   → renders React Email → sends via Nodemailer
5. On success: update email_outbox.status = 'sent'; insert email_events row (delivered)
6. On RETRYABLE failure (5xx, 429, network): back to status='queued';
   handler re-enqueues EMAIL_SEND with delay (60s → 5min → 15min)
7. On TERMINAL failure (4xx non-429) or all retries used: status='failed'
   — pg-boss job ends successfully (retryLimit: 0); state machine owns all retry logic
```

### Email Outbox Table

Every email starts as a row in `email_outbox` before being sent. This gives:
- Retry on SMTP failure (pg-boss retries the `EMAIL_SEND` job)
- Per-user email history visible in the admin panel
- Delivery tracking via `email_events` rows

To enqueue an email, the Server Action (or booking engine) inserts an `email_outbox` row with all the template data (recipient, subject, template name, template variables, from name, reply-to, booking ID) and then sends an `EMAIL_SEND` job to pg-boss with the outbox row's ID as the payload. The worker fetches the row, renders the React Email template, and delivers via Nodemailer SMTP.

**`idempotencyKey` — Deduplication on SMTP**

Every `email_outbox` row is inserted with a random UUID `idempotencyKey` (generated at INSERT time). This key is passed to the SMTP provider as a deduplication header with a 24-hour TTL.

If the `EMAIL_SEND` worker crashes after SMTP accepts the message but before it can write `status = 'sent'`, pg-boss retries the job. On retry, the same `emailOutboxId` → same `idempotencyKey` → SMTP deduplicates and does not re-deliver the email. Without this, a crash-then-retry cycle causes duplicate emails in the user's inbox.

---

## Background Jobs

### Complete Job Map for Notifications

| Job Name | Trigger | Payload | pg-boss config |
|----------|---------|---------|---------------|
| `EMAIL_SEND` | Inline — any time an email is enqueued | `{ emailOutboxId }` | retryLimit: 0 (state machine owns retries — handler re-enqueues with 60s/5min/15min backoff on failure), **localConcurrency: 5** |
| `EMAIL_OUTBOX_REAP` | Cron — daily at 03:00 UTC | `{}` | Deletes `email_outbox` rows older than 90 days with status=sent/failed |
| `EMAIL_EVENTS_PRUNE` | Cron — daily at 03:30 UTC | `{}` | Deletes `email_events` rows older than 30 days |
| `BOOKING_REMINDER_24H` | On booking confirmed — fires exactly 24h before start | `{ bookingId }` | singletonKey: `{bookingId}_reminder_24h`; retryLimit: 2 |
| `BOOKING_REMINDER_1H` | On booking confirmed — fires exactly 1h before start | `{ bookingId }` | singletonKey: `{bookingId}_reminder_1h`; retryLimit: 2 |
| `BOOKING_CANCEL_REMINDERS` | On booking cancelled | `{ bookingId }` | Cancels both reminder jobs by singletonKey |
| `BOOKING_RESCHEDULE_REMINDERS` | On booking rescheduled | `{ oldBookingId, newBookingId }` | Cancels old reminder jobs; schedules new ones for new time |

> **All handlers use `workMonitored()`** — register handlers with `workMonitored('EMAIL_SEND', handler)` not raw `boss.work()`. When `EMAIL_SEND` exhausts all retries, the DLQ callback fires — log the failure and update `email_outbox.status = 'failed'`. See `jobs-queues.md` — "Dead-Letter Queue Monitoring".

### singletonKey Pattern

Every booking-scoped job uses a `singletonKey` so each job can be individually cancelled when the booking changes:

```
{bookingId}_reminder_24h     — 24h reminder for this booking
{bookingId}_reminder_1h      — 1h reminder for this booking
{bookingId}_video_link       — video link generation
{bookingId}_calendar_write   — calendar event write
```

On booking cancellation, `BOOKING_CANCEL_REMINDERS` runs and calls `boss.cancel()` for both the 24h reminder (singletonKey `{bookingId}_reminder_24h`) and the 1h reminder (singletonKey `{bookingId}_reminder_1h`) to prevent reminders from firing for a cancelled meeting.

### Cron Schedule

| Cron Job | Schedule | Purpose |
|----------|----------|---------|
| `EMAIL_OUTBOX_REAP` | Daily 03:00 UTC | Delete old sent/failed email rows (90-day retention) |
| `EMAIL_EVENTS_PRUNE` | Daily 03:30 UTC | Delete old delivery events (30-day retention) |
| `DISPOSABLE_EMAILS_REFRESH` | Daily 04:00 UTC | Sync disposable email domain blocklist from upstream source |

---

## Audit Logging

Email delivery events are tracked in the `email_outbox` and `email_events` tables (not `audit_logs`) — see `database-schema.md`. The email outbox row records status (`queued → sending → sent / failed`), and `email_events` records delivery events (sent, bounced, etc.). This is readable from the admin panel per-user email history.

Host notification **preference changes** (toggling "new booking on/off", "cancellation on/off", etc.) are low-risk preference mutations and are **not** in `auditActionEnum` by design. A developer searching for a `notifications.preferences_updated` audit action will not find one — this is an explicit decision, not an oversight. If audit coverage of preferences is required, add a new enum value and log it in the notification preferences Server Action.

| What is tracked | Where |
|----------------|-------|
| Every outbound email (sent, failed, bounced) | `email_outbox` + `email_events` tables |
| Email history per user | Admin panel → User Detail → Email History (reads `email_outbox`) |
| Notification preference changes | **Not audited** — explicit decision; add if compliance requires it |

---

## Tech Stack

- **pg-boss** — the primary engine for all timed notifications. At the moment a booking is confirmed, pg-boss schedules future jobs with exact fire times: `EMAIL_SEND` (immediate ×2), `BOOKING_REMINDER_24H`, `BOOKING_REMINDER_1H`. Each uses a `singletonKey` so it can be individually cancelled on booking change. **`singletonKey` format: `{bookingId}_{jobType}`** — this ensures each job type per booking is unique and individually cancellable.
- **`email_outbox` table** — every outbound email starts as a row here. The `EMAIL_SEND` pg-boss job reads the row, renders the React Email template, sends via Nodemailer, and updates the row status. This decouples email rendering from booking creation and enables retry without re-running booking logic.
- **`email_events` table** — delivery tracking: each successful send, bounce, or failure appends a row. Visible in the admin panel user detail email history section.
- **Nodemailer (SMTP)** — delivers all transactional and reminder emails. Each email uses the host's `displayName` as the sender and routes replies to the host's actual email address. The `fromName` is read from `platform_settings.emailSenderName` as default, overridden per-host.
- **`@react-email/components` (React Email)** — renders all email templates as React components compiled to HTML before passing to Nodemailer. Install: `pnpm add @react-email/components react-email`. Template files live in `src/lib/email/templates/`:

  | File | Sent When |
  |------|-----------|
  | `booking-confirmation.tsx` | Invitee books — sent to invitee |
  | `booking-notification-host.tsx` | Invitee books — sent to host |
  | `cancellation-invitee.tsx` | Booking cancelled — sent to invitee |
  | `cancellation-host.tsx` | Invitee cancels — sent to host |
  | `reschedule-invitee.tsx` | Booking rescheduled — sent to invitee |
  | `reschedule-host.tsx` | Invitee reschedules — sent to host |
  | `host-cancellation-invitee.tsx` | Host cancels — sent to invitee |
  | `reminder-24h.tsx` | 24h before meeting — sent to invitee |
  | `reminder-1h.tsx` | 1h before meeting — sent to invitee |
  | `magic-link.tsx` | Sign-in magic link — sent to user |
  | `calendar-disconnect-alert.tsx` | Calendar token expires — sent to host |
  | `video-link-failed.tsx` | VIDEO_LINK_GENERATE exhausts retries — sent to host |
  | `password-reset.tsx` | Password reset requested — sent to user |

  The `EMAIL_SEND` worker reads the `template` field from the `email_outbox` row, imports the matching file, renders it with `renderAsync()`, and passes the resulting HTML to Nodemailer.
- **PostgreSQL + Drizzle ORM** — `notification_preferences` stores per-user preferences. `workflow_jobs` tracks pg-boss job state per booking. `email_outbox` + `email_events` track delivery status. pg-boss uses the same PostgreSQL database — no separate queue infrastructure needed.
