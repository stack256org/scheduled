# Booking Flow

The booking flow is the heart of Schduled. It defines the end-to-end journey from a user creating an event type to an invitee successfully scheduling a meeting.

---

## Overview

The booking flow eliminates the email back-and-forth of "when are you free?" by giving every user a shareable booking link. The invitee visits the link, sees real-time availability, picks a slot, and both parties receive a calendar invite — all in under two minutes.

---

## User Stories

**Host**
- As a host, I want to create a booking link in under 3 minutes, so that I can start accepting meetings immediately after signing up. *(MVP)*
- As a host, I want to share a single link that reflects my real-time availability, so that invitees always see accurate open slots without me updating anything manually. *(MVP)*
- As a host, I want to add my booking link to my email signature and LinkedIn, so that anyone can book me directly without asking for my availability. *(MVP)*
- As a host, I want to embed my booking page on my website, so that visitors can schedule a meeting without leaving my site. *(Phase 2)*

**Invitee**
- As an invitee, I want to book a meeting without creating an account, so that scheduling is fast and friction-free. *(MVP)*
- As an invitee, I want to see available time slots in my own timezone, so that I do not have to manually convert times. *(MVP)*
- As an invitee, I want to fill in a short booking form before confirming, so that the host has the context they need before we meet. *(MVP)*
- As an invitee, I want to reschedule or cancel my booking via a link in my email, so that I do not need to contact the host directly. *(MVP)*

---

## Host Journey (Setting Up)

### Step 1 — Connect Calendar
- Connect one or more calendars (Google Calendar, Outlook — both MVP; Apple iCloud and generic CalDAV — Phase 2)
- Schduled reads busy/free data from connected calendars in real-time
- Prevents double-booking across all connected calendars
- User selects which calendar new bookings are added to

### Step 2 — Create an Event Type
- Give the event type a name (e.g., "30-Minute Intro Call")
- Set meeting duration (15, 30, 45, 60 min — or custom)
- Set meeting location: Zoom, Google Meet, Teams, phone call, custom location, or in-person address
- Add a description shown to invitees on the booking page
- Set booking URL slug (e.g., `schduled.com/yourname/intro-call`)

### Step 3 — Configure Availability
- Set weekly recurring hours (e.g., Mon–Fri, 9am–5pm)
- Add buffer time before and after meetings
- Set minimum notice (e.g., 24-hour advance booking required)
- Set booking window (how far in advance invitees can book)
- Block specific dates or override hours for holidays

### Step 4 — Customize Booking Page
- Upload profile photo
- Add custom intake questions
- Set confirmation message
- Configure cancellation and reschedule policies
- Banner / cover image *(Phase 2)*
- Redirect to external URL after booking *(Phase 2)*

### Step 5 — Share the Link
- Copy direct booking link
- Add to email signature, LinkedIn, website
- Embed on website (inline, pop-up, or floating widget) *(Phase 2)*
- Share via QR code *(Phase 2)*

---

## Invitee Journey (Booking a Meeting)

### Step 0 — Duration Selection (Multi-Duration Event Types Only)
When the event type has `inviteeCanChooseDuration` enabled, the booking page opens with a **duration selection card** before the calendar is shown.

| Element | Description |
|---------|-------------|
| Heading | "How long would you like to meet?" |
| Duration options | One button per configured duration (e.g., 15 min / 30 min / 60 min) |
| Default selection | The duration marked as default is pre-selected |

> **Why duration must come before the calendar:** Available time slots depend entirely on duration. A 15-minute slot may be open, but the same start time as a 60-minute meeting may not be available if the host has a meeting 30 minutes later. If the invitee selects duration after seeing the calendar, the slot list would need to reload — causing confusing UX. Selecting duration first means the calendar immediately shows correct slots for the chosen length.

After a duration is selected, the normal booking flow continues from Step 1.

---

### Step 1 — Visit Booking Page
- Invitee opens the booking link
- Sees host's name, event type, duration (or selected duration if multi-duration), location type
- Sees a calendar with available time slots highlighted

### Step 2 — Select Date and Time
- Calendar shows current month with available days
- Click a date to see available time slots for that day
- Time slots shown in invitee's local timezone (auto-detected)
- Slots are calculated for the **chosen duration** (only slots with enough consecutive free time are shown)
- Option to manually change timezone

### Step 3 — Fill Booking Form
- Required fields: Name, Email
- Optional: Phone number
- **Phone Call direction logic** — when location type is "Phone Call", the `phoneCallDirection` setting on the event type controls the form:
  - `host_calls_invitee`: invitee's phone number field becomes **required** ("Your phone number — the host will call you at this number")
  - `invitee_calls_host`: invitee's phone field is hidden; confirmation screen and email display the **host's phone number** instead ("Call us at: +1 555 123 4567")
- Custom questions (pre-configured by host): text, dropdown, checkbox, radio
- Pre-fill via URL parameters for embedded forms

### Step 4 — Confirmation
- Instant confirmation screen shown
- Confirmation email sent to both host and invitee
- Calendar invite (.ics) attached and added to both parties' calendars
- Video conferencing link (Zoom / Meet / Teams) included in invite
- Option for invitee to schedule another meeting

---

## Booking Conflict Prevention

- **Real-time availability check** — Schduled re-checks calendar at the moment of booking to prevent race conditions
- **Buffer enforcement** — Buffer times before/after are factored into available slots
- **Daily meeting limits** — If host has set a cap (e.g., max 5 meetings/day), slots beyond that cap are hidden
- **Minimum notice enforcement** — Same-day or same-hour bookings blocked if notice period not met

---

## Cancellation Policy Enforcement

Schduled goes beyond Calendly by not just displaying a policy — it can **actively enforce** cancellation rules.

### Policy Text
Hosts can add cancellation policy text shown on the booking page and in confirmation emails:
> "Cancellations must be made at least 24 hours before the meeting."

This is informational only; the invitee can still cancel at any time via their email link unless enforcement is enabled.

### Enforcement Window (Configurable)
Per event type, hosts can set a **cancellation window** that blocks invitees from cancelling within a set period before the meeting.

| Setting | Description |
|---------|-------------|
| No enforcement (default) | Invitee can cancel any time up to the meeting |
| Block cancellations within X hours | Invitee's cancel link shows an error if within window |
| Block cancellations entirely | Cancel link disabled; invitee must contact host |

**Behavior when invitee tries to cancel within the blocked window:**

The cancel link is always active (invitee should never see a dead link). When clicked inside the blocked window, the invitee reaches a **Cancellation Blocked** page that shows:

| Element | Content |
|---------|---------|
| Heading | "This booking can no longer be cancelled online" |
| Explanation | "Cancellations for this meeting are not accepted within [X hours] of the start time." |
| Meeting details | Date, time, host name — so invitee knows which booking this is |
| Host contact | "To discuss this booking, please contact: **[host reply-to email]**" |
| Calendar reminder | "Add to calendar" button still visible so invitee can ensure they attend |

- Host is **not automatically notified** when the blocked page is shown — the invitee must reach out directly
- Booking status remains `confirmed` — no change on the host's dashboard
- The reschedule link follows the same logic independently: if reschedule window is also blocked, the reschedule link shows a similar page with the host email

**Enforcement Scope:**
- Applies to invitee-initiated cancellations via email link only
- Host can always cancel from the dashboard regardless of the enforcement window
- If the host cancels inside the window: invitee receives a cancellation email with an apology note

### Reschedule Policy (Separate from Cancel)
- Reschedule window can be set independently from cancellation window
- Example: Allow rescheduling up to 4 hours before, block cancellations within 24 hours
- If rescheduling is disabled entirely: reschedule link leads to contact message

### Reschedule Limits
- **Maximum reschedules per booking** — Hosts can cap how many times a single booking can be rescheduled (e.g., maximum 2 reschedules per invitee per event)
- If limit is reached: reschedule link shows: "This meeting has been rescheduled the maximum number of times. Please contact [host] to make further changes."

### Cancellation Reason (Optional)
When an invitee cancels (within policy), they can optionally provide a reason:
- Reason is free text or selectable from a dropdown (host configures options)
- Example options: "Schedule conflict", "No longer needed", "Need to reschedule", "Other"
- Reason is stored with the cancellation record and visible in the host's Meetings Dashboard
- Reason included in the host's cancellation notification email

### Configuration (Per Event Type)
Event type settings → Cancellation & Reschedule tab:

| Option | Values |
|--------|--------|
| Cancellation policy text | Free text (shown on booking page) |
| Enforce cancellation window | Off / 1h / 2h / 4h / 8h / 24h / 48h / 72h |
| Allow rescheduling | On / Off |
| Enforce reschedule window | Off / 1h / 2h / 4h / 8h / 24h |
| Max reschedules per booking | Unlimited / 1 / 2 / 3 |
| Require cancellation reason | Off / Optional / Required |
| Cancellation reason options | Custom dropdown list (host-defined) |

---

## Cancellation & Reschedule Flow

### Invitee Cancels
1. Invitee clicks "Cancel" link in confirmation email
2. **API validates that `startTime > NOW()`** — if the meeting has already started or passed, the cancel link shows a "Meeting Already Completed" page ("This meeting has already taken place and cannot be cancelled."). Cancelling a past meeting would corrupt historical records.
3. Cancellation policy window checked — if within blocked window, show **Cancellation Blocked** page (see above)
4. Shown cancellation form (optional reason field)
5. Cancellation confirmed; both parties notified
6. Calendar event removed from both calendars
7. Host can trigger post-cancellation workflows (e.g., offer to reschedule)

### Invitee Reschedules
1. Invitee clicks "Reschedule" link in confirmation email
2. **API validates that `startTime > NOW()`** — if the meeting time has already passed, the reschedule link shows a "Meeting Already Completed" page ("This meeting has already taken place and cannot be rescheduled."). Rescheduling a past meeting would corrupt analytics and host schedules.
3. Reschedule policy window checked — if within blocked window, show **Reschedule Blocked** page
4. Taken back to booking page with original time slot highlighted
5. Selects new time
6. Original calendar invite updated for both parties
7. Confirmation email sent with updated details

### Host Cancels
- Host can cancel any booking from their dashboard
- Invitee is notified automatically
- Optional: host provides a reason or rescheduling prompt

---

## Group Booking Flow *(Post-MVP — Phase 2)*

For event types that allow multiple invitees per slot:
- Host sets maximum capacity (e.g., 10 people per slot)
- Invitees independently book the same slot
- Each invitee gets their own confirmation
- Slot hidden once capacity is reached
- All invitees receive same video conference link

---

## Multi-Host Collective Booking Flow *(Post-MVP — Phase 2)*

For events requiring multiple hosts to be present:
- System checks availability of ALL required hosts simultaneously
- Only shows slots when every host is free
- All hosts receive calendar invites
- All hosts can see the booking in their dashboard

---

## Reference Implementations

| App | Booking Steps | Cancel / Reschedule (no login) | Cancellation Enforced | Calendar Overlay | Group Booking |
|-----|--------------|-------------------------------|----------------------|-----------------|---------------|
| **Calendly** | Date → time → form → confirm | ✅ Token links in email | ❌ Policy text shown only — never enforced | ❌ No | ✅ Paid plans only |
| **Cal.com** | Same as Calendly | ✅ Token links | ❌ Policy text only | ❌ No | ✅ Yes |
| **SavvyCal** | Date → time (with calendar overlay) → form → confirm | ✅ Token links | ❌ No | ✅ **Yes** — invitee connects their calendar to see mutual free times | ❌ No |
| **Chili Piper** | Embedded form → instant calendar popup → confirm | ✅ Via email link | ❌ No | ❌ No | ✅ Yes |
| **HubSpot Meetings** | Minimal — date → time → confirm; no custom form | ✅ Via email link | ❌ No | ❌ No | ✅ Basic |
| **Schduled** | Date → time → form → confirm; dual-timezone shown at every step | ✅ Secure token links — no Schduled account needed | ✅ **Configurable enforcement window** — cancel link blocked within X hours before meeting (Calendly gap filled) | ✅ Phase 3 (SavvyCal-inspired) | ✅ Phase 2 |

---

## MVP Scope

**In MVP:**
- Full solo user booking flow (steps 1–5)
- Confirmation email to both parties (with dual timezone display)
- ICS calendar invite generation
- Cancellation via email link (token-based, no login required)
- Reschedule via email link (token-based, no login required)
- **Cancellation policy text** shown on booking page and in confirmation emails
- **Cancellation window enforcement** — block cancellations within a configurable number of hours before meeting (e.g., no cancellations within 24 hours) — this is a direct Calendly gap: Calendly only shows policy text, never enforces it
- **Reschedule window enforcement** — block reschedules within a configurable window
- **Cancellation reason capture** — optional or required reason dropdown on cancel page
- Timezone auto-detection for invitee
- Custom intake questions on booking form

> **Calendly comparison:** Calendly displays cancellation policy text but does not enforce it — any invitee can cancel at any time regardless of the stated policy. Schduled actually blocks the cancel link when the window has passed, which is a key differentiator for coaching calls, high-value demos, and any meeting where last-minute cancellations are disruptive.

**Post-MVP:**
- Calendar overlay — invitee connects own calendar to see mutual free times *(Phase 3)*
- Group booking with capacity limits *(Phase 2)*
- Collective multi-host booking *(Phase 2)*
- QR code for sharing booking link *(Phase 2)*


---

## Background Jobs

Every booking lifecycle event triggers pg-boss jobs. All are keyed with `singletonKey: {bookingId}_{jobType}` so they can be individually cancelled.

| Event | Jobs Enqueued |
|-------|--------------|
| Booking confirmed | `EMAIL_SEND` (×2), `VIDEO_LINK_GENERATE`, `CALENDAR_WRITE`, `BOOKING_REMINDER_24H`, `BOOKING_REMINDER_1H` |
| Booking cancelled (by invitee) | `EMAIL_SEND` (×2: cancellation emails), `BOOKING_CANCEL_REMINDERS`, `CALENDAR_CANCEL` |
| Booking cancelled (by host) | `EMAIL_SEND` (×1: host-cancellation to invitee), `BOOKING_CANCEL_REMINDERS`, `CALENDAR_CANCEL` |
| Booking rescheduled | `EMAIL_SEND` (×2: reschedule emails), `BOOKING_RESCHEDULE_REMINDERS`, `CALENDAR_UPDATE` |

### BOOKING_CANCEL_REMINDERS job

Cancels the pending 24h and 1h reminder jobs so they don't fire for a meeting that no longer exists. The handler calls `boss.cancel()` for both `BOOKING_REMINDER_24H` and `BOOKING_REMINDER_1H` using the singletonKey format `{bookingId}_reminder_24h` and `{bookingId}_reminder_1h`. All handlers are registered with `workMonitored()` — see `jobs-queues.md` for the dead-letter queue pattern.

### BOOKING_RESCHEDULE_REMINDERS job

Cancels the old reminder jobs (using the original bookingId in the singletonKeys) and schedules two new reminder jobs using `boss.sendAfter()` with the rescheduled meeting time — one firing 24h before the new start time and one firing 1h before, each with a new `singletonKey` tied to the new bookingId.

## Audit Logging

Every cancellation and reschedule writes an entry to `audit_logs`:

| Event | Audit Action | source |
|-------|-------------|--------|
| Invitee cancels | `booking.cancelled_by_invitee` | `'api'` (invitee hits `/api/bookings/[id]/cancel`) |
| Host cancels from dashboard | `booking.cancelled_by_host` | `'web'` (Server Action) |
| Invitee reschedules | `booking.rescheduled` | `'api'` |

Every `audit_logs` insert must include `source: 'web' | 'api' | 'worker' | 'system'`. Set `source: 'api'` for invitee cancel/reschedule (unauthenticated API routes) and `source: 'web'` for host-initiated Server Actions. See `database-schema.md` for the full `auditSourceEnum`.

---

## Tech Stack

- **Next.js App Router** — the full booking flow spans three pages: the public booking calendar (`/[username]/[eventSlug]`), the booking form (step 2 on the same page), and the confirmation screen (`/[username]/[eventSlug]/confirmed`). Cancel and reschedule flows are token-based pages that work without any invitee login.
- **PostgreSQL** — cancel and reschedule operations use database transactions to ensure atomic state changes (no partial updates). Advisory locks prevent two concurrent reschedule requests from creating conflicting bookings for the same new slot. All cancel/reschedule writes include audit log row within the same transaction.
- **Drizzle ORM** — stores a unique `cancelToken` and `rescheduleToken` on every booking record. Both tokens are generated with `crypto.randomUUID()` at booking INSERT time and embedded in confirmation email links, allowing invitees to cancel or reschedule without a Schduled account. Token lookup is the only authentication for these flows.
- **`GET /api/slots` — rate limited** — the endpoint that returns available time slots for a booking page is rate-limited at 10 requests / 60 seconds per IP (same `rateLimiter` middleware from `src/lib/rate-limit.ts` used by `POST /api/bookings`). Prevents slot-scraping abuse.
- **pg-boss** — orchestrates all async work triggered by the booking flow. On new booking: enqueues `EMAIL_SEND` (×2), `VIDEO_LINK_GENERATE`, `CALENDAR_WRITE`, `BOOKING_REMINDER_24H`, `BOOKING_REMINDER_1H`. On cancellation: enqueues `EMAIL_SEND` (×2), `BOOKING_CANCEL_REMINDERS`, `CALENDAR_CANCEL`. On reschedule: enqueues `EMAIL_SEND` (×2), `BOOKING_RESCHEDULE_REMINDERS`, `CALENDAR_UPDATE`.
- **`audit_logs` table** — every cancel/reschedule writes `booking.cancelled_by_invitee`, `booking.cancelled_by_host`, or `booking.rescheduled` inside the DB transaction.
- **Better Auth** — protects host-side dashboard routes. The public booking and cancel/reschedule flows are intentionally unauthenticated — invitees use secure single-use tokens instead of requiring a Schduled account.
