# Booking Engine

The Booking Engine is the core mechanism that processes every meeting booking end-to-end — from the moment an invitee selects a time slot to the moment both parties' calendars are updated and confirmation emails are sent. It is the technical heart of Schduled.

---

## Overview

The Booking Engine is not the booking page (what invitees see visually) — it is the processing layer underneath. It answers:
- "Is this time slot still available right now?"
- "Which host should be assigned to this round-robin booking?"
- "How do I add this event to Google Calendar?"
- "What do I send in the confirmation email?"

The Booking Engine runs on every single booking and must be fast, reliable, and race-condition-safe.

---

## User Stories

**Host**
- As a host, I want the booking engine to prevent double-bookings in real-time, so that two invitees can never claim the same slot simultaneously. *(MVP)*
- As a host, I want a booking to only be confirmed after all availability checks pass, so that I never receive a booking for a time I am unavailable. *(MVP)*
- As a host, I want all post-booking tasks (calendar write, email, video link) to run in the background, so that the invitee gets an instant response without waiting. *(MVP)*

**Invitee**
- As an invitee, I want to receive clear feedback if a slot is taken while I am booking, so that I can immediately pick another available time. *(MVP)*
- As an invitee, I want the booking process to complete quickly without page reloads, so that confirming my meeting feels fast and smooth. *(MVP)*

---

## Booking Engine Flow (Step by Step)

### 1. Slot Selection
Invitee selects a date and time from the booking page.

**Engine Actions:**
- Validate that the selected slot is still within the booking window
- Validate that minimum notice period is satisfied
- Validate that the slot is not in a blocked date override
- Pass slot forward for real-time conflict check

---

### 2. Real-Time Conflict Check

Before showing the form page, re-verify availability.

**Why Real-Time Check?**
- Availability on the booking page may be cached (up to 5 minutes old)
- Another invitee may have booked the same slot between page load and form submission
- Prevents double-booking

**Conflict Sources Checked:**
- Connected Google Calendar: any "Busy" event overlapping the slot
- Connected Outlook Calendar: any busy event overlapping
- Existing Schduled bookings for this host at this time
- Buffer time from adjacent bookings (before and after)
- Daily meeting limit (if host has reached cap for the day)

**On Conflict Detected:**
- Engine returns `SLOT_UNAVAILABLE` error
- Booking page shows: "Sorry, that time was just taken. Please choose another slot."
- Page refreshes available times and highlights alternative slots

---

### 3. Form Submission

Invitee submits name, email, and custom question answers.

**Engine Actions:**
- Validate required fields — call `validateName(inviteeName)` and `validateEmail(inviteeEmail)` from `src/lib/validators.ts` before Zod. Both return `null` on invalid input; return `{ error: 'Invalid name' }` immediately if either is `null`.
- Sanitize all text inputs — call `stripHtml(answer)` from `src/lib/validators.ts` on every custom question text answer to strip HTML tags before saving (prevents stored XSS).
- Validate required custom question answers
- Normalize phone number format (if collected)
- Check email against blocked domains (if host configured any)

---

### 4. Host Assignment (Round-Robin Only)

For round-robin event types, the engine assigns a host from the pool.

**Assignment Algorithm (Balanced mode):**
1. Get all active team members in the round-robin pool
2. Filter to members who are available at the selected time (re-check calendar)
3. Filter to members who have not hit their daily/weekly limit
4. From remaining candidates, select the one who was booked least recently
5. If tie: select randomly
6. If no available member found: return `NO_AVAILABLE_HOST` error

**Atomic Operation:**
- Assignment written to database in a transaction to prevent two concurrent bookings choosing the same host
- PostgreSQL advisory lock used to handle race conditions

---

### 5. Create Booking Record

The booking is written to the Schduled database.

**Booking Record Contains:**

| Field | Description |
|-------|-------------|
| booking_id | UUID, globally unique |
| event_type_id | Which event type was booked |
| host_user_id | Assigned host (from round-robin or direct) |
| invitee_name | Invitee's full name |
| invitee_email | Invitee's email address |
| invitee_phone | Phone number (if collected) |
| invitee_timezone | Timezone detected/selected by invitee |
| start_time | Meeting start (stored as UTC) |
| end_time | Meeting end (stored as UTC) |
| location_type | zoom / meet / teams / phone / in_person / custom |
| location_value | Generated video link or address |
| custom_answers | JSON map of question ID → answer |
| status | confirmed / cancelled / rescheduled / completed |
| reschedule_count | How many times this booking has been rescheduled (checked against event type's max reschedule limit) |
| created_at | Booking creation timestamp (UTC) |
| cancel_token | Unique token for cancel link in email — generated with `crypto.randomUUID()` at booking INSERT time |
| reschedule_token | Unique token for reschedule link in email — generated with `crypto.randomUUID()` at booking INSERT time |

---

### 6. Generate Video Conference Link

If location type is Zoom, Google Meet, or Teams, generate a unique link.

**Zoom:**
- API call: `POST /v2/users/{userId}/meetings`
- Creates a new Zoom meeting with the booking time and duration
- Returns unique join URL and meeting ID
- Stored in `location_value` field

**Google Meet:**
- Included in the Google Calendar event creation (Step 7 — Write to Calendar)
- `conferenceData.createRequest` parameter triggers Google Meet link generation
- No separate API call required

**Microsoft Teams:**
- API call: `POST /v1.0/users/{userId}/onlineMeetings`
- Creates Teams meeting at the booking time
- Returns unique joinWebUrl
- Stored in `location_value` field

**Fallback:**
- If video link generation fails: booking still created
- Host is notified: "Video link generation failed — please add manually"
- Invitee confirmation still sent; video field shows "Link will be sent separately"

---

### 7. Write to Calendar

Add the meeting to the host's calendar (and optionally invitee's calendar).

**Host Calendar (Google):**
The CALENDAR_WRITE job calls `POST /calendars/{calendarId}/events` via the Google Calendar API. The event includes the meeting title (event type name + invitee name), start and end times in the host's timezone, the invitee's email as an attendee, the video URL as the location field, and the booking ID plus form answers in the description.

**Host Calendar (Outlook):**
- Microsoft Graph API: `POST /me/events`
- Same data, Graph API format

**ICS File for Invitee:**
- Generate RFC 5545-compliant `.ics` file
- Attached to confirmation email
- Works with any calendar app (Apple Calendar, Outlook, Thunderbird, etc.)
- Contains VTIMEZONE component for DST-safe display

**Calendar Write Failure:**
- If Google/Outlook API returns error: retry up to 3 times with exponential backoff
- If still failing after retries: booking marked `calendar_sync_failed` 
- Host notified with manual add option
- Booking still confirmed for invitee

---

### 8. Send Confirmation Emails

Send confirmation emails to both host and invitee.

**Invitee Confirmation Email:**
- Subject: "[Confirmed] 30-Min Call with Jane on Thursday June 5"
- Body: meeting summary, video link, location, reschedule link, cancel link
- ICS attachment for calendar import
- Sent within 5 seconds of booking

**Host Notification Email:**
- Subject: "New booking: 30-Min Call — Jane Smith on June 5 at 10am"
- Body: invitee details, form answers, video link, cancel link
- Sent within 5 seconds of booking

**Email Delivery:**
- Transactional email via Nodemailer (SMTP)
- If delivery fails: retry twice via pg-boss; log failure with `console.error`; host notified in dashboard

---

### 9. Booking Confirmation Response

The booking engine returns a success response to the browser.

**Response Payload:**
- Booking ID
- Confirmed start/end time (in invitee's timezone)
- Host name
- Video link (or location)
- Reschedule URL
- Cancel URL

**Browser Action:**
- Booking page transitions to confirmation screen
- "You're scheduled!" message shown
- Calendar import buttons displayed
- Meeting details summary

---

## Race Condition Handling

The most critical reliability concern: two invitees trying to book the same slot simultaneously.

### PostgreSQL Advisory Lock Strategy

Schduled uses **PostgreSQL advisory locks** — a pessimistic locking approach that prevents two concurrent booking requests from both succeeding for the same slot.

1. When an invitee submits the booking form, the engine calls `SELECT pg_advisory_xact_lock(slotHash)` where `slotHash` is a deterministic integer derived from `hostUserId + startTime` — **not** `eventTypeId + startTime`. Using the host's user ID ensures that two concurrent bookings for the **same host at the same time** (even across different event types, e.g. "Intro Call" and "Support Call") are serialised correctly. Using only `eventTypeId` would allow both bookings to proceed simultaneously for the same host time slot.
2. The lock is held for the duration of the database transaction — any second request for the same host + time blocks until the first transaction completes
3. Inside the lock: perform the final availability check → if slot is free, insert booking record → commit
4. Lock is released automatically when the transaction commits or rolls back (no manual release needed, no TTL to manage, no extra table required)
5. If another session is waiting for the same lock: it runs its own check after the first commits — if the first succeeded, the slot is now taken and the second returns "slot unavailable"

### Database Transaction
All booking creation steps (lock acquisition → idempotency check → availability check → booking insert → email outbox insert → job enqueue → audit log) run in a single database transaction. If any step fails, the entire transaction rolls back — no orphaned records, no double-bookings.

### Idempotency Key (POST Safety)

The booking form submission includes a client-generated idempotency key (UUID, generated on form load). Before taking any action, the engine queries the `idempotency_keys` table for a matching, non-expired key. If one exists, the stored response is returned immediately without creating a duplicate booking. If no existing key is found, booking creation proceeds and the response is stored in `idempotency_keys` with a 24-hour TTL. This prevents duplicate bookings caused by network retries, double-clicks, or browser back-button resubmissions.

### Audit Log

On successful booking creation, an entry is written to `audit_logs` inside the same transaction: `actorUserId` is null (invitees are not logged-in users), `actorEmail` is the invitee's email, `action` is `booking.created`, `source` is `'api'` (the `POST /api/bookings` route is unauthenticated), and `after` contains the booking ID, host ID, and start time. The `source` field must always be set — use `'api'` for booking creation, `'web'` for Server Actions, `'worker'` for jobs. See `database-schema.md` for `auditSourceEnum`.

---

## Retry and Resilience

| Step | Failure Handling |
|------|-----------------|
| Conflict check | Fail-safe: return unavailable if check errors |
| Host assignment | Return error to invitee if no host available |
| Calendar write | Retry 3× with backoff; notify host if all retries fail |
| Video link generation | Retry 3× with exponential backoff (5s → 30s → 2min); if all fail: host receives alert email, invitee email shows "Your video link will be sent shortly" — booking never blocked |
| Email sending | Retry 2×; log failure; dashboard alert to host |

---

## Booking Statuses

| Status | Description |
|--------|-------------|
| `confirmed` | Meeting booked and active |
| `cancelled` | Cancelled by host or invitee |
| `rescheduled` | Original booking replaced by new one |
| `completed` | Meeting time has passed (no cancellation) |
| `no_show` | Meeting time passed, marked as no-show by host |

---

## Calendar Disconnected — Booking Page Behaviour

If a host's calendar integration is disconnected (token expired, access revoked, or manual disconnect):

- All event types that use that calendar as the write target are **automatically disabled**
- Invitees visiting the booking page see: "This calendar is currently unavailable. Please check back later."
- No new bookings are accepted while the calendar is disconnected — prevents double-bookings from undetected conflicts
- Host receives an alert email: "Your [Google Calendar / Outlook] has been disconnected — reconnect to resume accepting bookings"
- A banner is shown in the host's dashboard: "⚠️ Calendar sync interrupted — booking pages paused"
- Once the host reconnects the calendar, event types are automatically re-enabled and the booking page becomes live again

> Booking pages **cannot** be manually re-enabled while the calendar is disconnected — the calendar connection is required for conflict detection.

---

## Spam Booking Protection

Booking pages are publicly accessible with no authentication required. Basic protections are applied to prevent spam bookings without adding friction for real users.

- **Rate limiting** — `POST /api/bookings` is rate-limited at **10 requests / 60 seconds per IP** using the fixed-window counter in `src/lib/rate-limit.ts`. Returns `429 Too Many Requests` with a `Retry-After` header when exceeded. Prevents automated booking spam.
- **`GET /api/slots` is also rate-limited** — slot availability fetches are limited at the same rate to prevent calendar-scraping.
- Email format validated with Zod before any DB write
- Disposable email domain blocklist checked against known throwaway providers
- No CAPTCHA needed in MVP — CAPTCHA adds friction for genuine invitees

---

## Performance Targets

| Operation | Target Time |
|-----------|------------|
| Conflict check | < 500ms |
| Full booking creation | < 3 seconds |
| Calendar write (async) | < 10 seconds |
| Confirmation email delivery | < 30 seconds |
| Booking page initial load | < 1.5 seconds |

---

## Reference Implementations

| App | Race Condition Protection | Real-Time Conflict Check | Post-Booking Jobs Async | Slot-Taken Error Message |
|-----|--------------------------|-------------------------|------------------------|--------------------------|
| **Calendly** | ✅ Industry benchmark; no double-bookings reported | ✅ Re-checks at form submit | Partial | Generic "time no longer available" |
| **Cal.com** | ✅ Atomic booking via open-source engine | ✅ Yes | ✅ Queue-based | Generic message |
| **SavvyCal** | ✅ Yes | ✅ Yes | ✅ Yes | Generic message |
| **Chili Piper** | ✅ Optimised for high-volume inbound leads | ✅ Near real-time | ✅ Yes | ✅ With alternative slot suggestion |
| **HubSpot Meetings** | ✅ Yes | ✅ Yes | ✅ Yes | Generic message |
| **Schduled** | ✅ PostgreSQL advisory lock — concurrent bookings for same slot cannot both succeed | ✅ Final check inside DB transaction before insert | ✅ All post-booking work (video link, calendar write, confirmation email, reminder scheduling) runs as pg-boss jobs after transaction commits — booking API responds instantly | ✅ Clear message + highlights alternative available slots on the same page |

---

## MVP Scope

**In MVP:**
- Full 9-step booking flow (conflict check → form → host assignment → booking record → video link → calendar write → email → response)
- PostgreSQL advisory lock for race condition prevention (no extra table needed)
- Google Calendar and Outlook write support
- ICS file generation for invitees
- Zoom and Google Meet link generation
- Confirmation email to both parties within 5 seconds
- Booking record with all fields persisted
- All booking statuses tracked
- Retry logic for calendar write and email

**Post-MVP:**
- Apple Calendar write (CalDAV POST) *(Phase 2)*
- Async queue for calendar writes (improve response time)
- Booking engine webhook events (booking.created, etc.)
- Detailed engine logs for debugging


---

## Background Jobs

All post-booking work runs as pg-boss jobs after the DB transaction commits. The booking API returns immediately without waiting for any external API.

| Job Name | Trigger | Payload | pg-boss config |
|----------|---------|---------|---------------|
| `EMAIL_SEND` | On booking confirmed (×2: invitee + host) | `{ emailOutboxId }` | retryLimit: 0 (state machine owns retries — handler re-enqueues with 60s/5min/15min backoff on failure), **localConcurrency: 5** |
| `VIDEO_LINK_GENERATE` | On booking confirmed (if video location) | `{ bookingId, provider }` | retryLimit: 3, retryDelay: exponential (5s→30s→120s), **localConcurrency: 3** |
| `CALENDAR_WRITE` | On booking confirmed | `{ bookingId, calendarId }` | retryLimit: 3, retryDelay: 15s, **localConcurrency: 1** — must be 1 to avoid concurrent writes to the same calendar |
| `BOOKING_REMINDER_24H` | On booking confirmed — fires 24h before start | `{ bookingId }` | singletonKey: `{bookingId}_reminder_24h`; retryLimit: 2 |
| `BOOKING_REMINDER_1H` | On booking confirmed — fires 1h before start | `{ bookingId }` | singletonKey: `{bookingId}_reminder_1h`; retryLimit: 2 |

### Job Dispatch Order

All database writes happen inside a single transaction (steps 1–7 below). Jobs are enqueued only after the transaction commits successfully (steps 8–13). If the transaction rolls back, no jobs are dispatched.

**Inside the DB transaction:**
1. Acquire advisory lock for the host + time slot
2. Idempotency check — return stored response if key exists
3. Final availability check — slot must still be free
4. Insert `bookings` row + `booking_answers` rows
5. Insert two `email_outbox` rows (invitee confirmation + host notification)
6. Insert `audit_logs` row (`booking.created`, source `'api'`)
7. Insert `idempotency_keys` row (TTL 24h)

**After transaction commits — enqueue pg-boss jobs:**
8. `EMAIL_SEND` for invitee confirmation email
9. `EMAIL_SEND` for host notification email
10. `VIDEO_LINK_GENERATE` (if location is Zoom or Teams)
11. `CALENDAR_WRITE` (write event to host's calendar)
12. `BOOKING_REMINDER_24H` scheduled for 24h before start time
13. `BOOKING_REMINDER_1H` scheduled for 1h before start time

All handlers are registered with `workMonitored()` (not raw `boss.work()`) — see `jobs-queues.md` for the dead-letter queue monitoring pattern.

---

## Tech Stack

- **PostgreSQL** — the booking engine depends on two PostgreSQL features for reliability: (1) **advisory locks** (`pg_advisory_xact_lock(hostUserId + startTime)`) to prevent two concurrent bookings from claiming the same host time slot — the lock key must include the **host's user ID**, not the event type ID, so that bookings across different event types for the same host at the same time are correctly serialised; and (2) **transactions** to ensure all booking record writes, email outbox rows, audit log, and idempotency key either all succeed or all roll back together.
- **`idempotency_keys` table** — client-generated UUID sent with every booking POST. Prevents duplicate bookings from network retries, double-clicks, or browser back-button resubmissions. TTL: 24h.
- **`email_outbox` table** — two rows inserted inside the booking transaction (one for invitee confirmation, one for host notification). `EMAIL_SEND` jobs sent after commit — never blocking the booking response.
- **`audit_logs` table** — `booking.created` row written inside the transaction. Contains invitee email, host ID, start time, and booking ID.
- **Drizzle ORM** — the `bookings` table holds all booking data (UTC times, status, cancel token, reschedule token, custom answer references, video link). Drizzle's transaction API is used for the atomic booking creation flow.
- **Next.js API Route** — `POST /api/bookings` is the single endpoint for the entire booking creation flow: Zod validation → conflict check → DB write → job dispatch.
- **Zod** — validates the complete booking form payload (invitee name, email, selected slot, answers) before any database operation. Strips HTML from all text inputs to prevent XSS.
- **pg-boss** — after the database transaction commits, jobs are enqueued: `EMAIL_SEND` (×2), `VIDEO_LINK_GENERATE`, `CALENDAR_WRITE`, `BOOKING_REMINDER_24H`, `BOOKING_REMINDER_1H`. All use `singletonKey` format `{bookingId}_{jobType}` so each job can be individually cancelled on reschedule or cancellation.
