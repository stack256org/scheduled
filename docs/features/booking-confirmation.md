# Booking Confirmation

Booking Confirmation is the final step of the booking flow — the moment an invitee's meeting is locked in. It covers everything that happens immediately after a booking is created: the confirmation screen the invitee sees, the emails sent to both parties, the calendar invites, and the data recorded in the system.

---

## Overview

A confirmation is not just a "thank you" message. It is:
- **Proof** that the booking succeeded
- **Instructions** for how to join the meeting
- **A calendar event** that blocks time for both parties
- **A record** of what was agreed (time, location, invitee's form answers)
- **Links** to cancel or reschedule if plans change

Done well, a confirmation email makes both host and invitee feel confident the meeting is real and they know exactly what to do next.

---

## User Stories

**Host**
- As a host, I want to receive an instant email when someone books me, so that I always know about new meetings the moment they are created. *(MVP)*
- As a host, I want to see the invitee's form answers in my notification email, so that I can prepare for the meeting before it starts. *(MVP)*
- As a host, I want to set a custom confirmation message, so that invitees receive relevant next steps or instructions after booking. *(MVP)*

**Invitee**
- As an invitee, I want to see a confirmation screen immediately after booking, so that I know my meeting was successfully scheduled. *(MVP)*
- As an invitee, I want to see the meeting time in my own timezone on the confirmation screen, so that I know exactly when to join. *(MVP)*
- As an invitee, I want to see the host's timezone alongside mine, so that I am confident we are both expecting the same time. *(MVP)*
- As an invitee, I want "Add to Calendar" buttons on the confirmation page, so that I can save the meeting to my calendar with one click. *(MVP)*
- As an invitee, I want a confirmation email with a reschedule and cancel link, so that I can change plans without contacting the host directly. *(MVP)*

---

## Confirmation Screen (Invitee Browser)

Immediately after the invitee clicks "Book" and the booking is processed, the booking page transitions to a confirmation screen — no page reload needed.

### Confirmation Screen Content

| Element | Description |
|---------|-------------|
| ✅ Success icon | Large green checkmark animation |
| Headline | "You're scheduled!" |
| Host name and photo | Reassures invitee they booked with the right person |
| Event type name | e.g., "30-Minute Intro Call" |
| **Your time** | Full date + time in **invitee's timezone** — e.g., "Thursday, June 5 at 3:00 PM IST" |
| **Host's time** | Same meeting in **host's timezone** — e.g., "That's 10:00 AM EST for Jane Smith" — shown directly below invitee time so neither party is confused |
| Duration | e.g., "30 minutes" |
| Location | Video link button (Join Zoom / Join Meet) or address |
| Invitee email | "A confirmation has been sent to jane@example.com" |

> **Why both timezones on the confirmation screen?**
> Calendly only shows one timezone on the confirmation screen. When an invitee in India books a host in New York, the invitee sees their own time but has no idea what time the host is expecting them. Schduled shows both — reducing "I thought it was at 3pm for both of us" confusion before it happens.

### Add to Calendar Buttons
Three prominent "Add to Calendar" buttons:

| Button | Action |
|--------|--------|
| Google Calendar | Opens Google Calendar with event pre-filled; one click to save |
| Outlook / iCal | Downloads `.ics` file; works with Apple Calendar, Outlook, any calendar app |
| Office 365 | Opens Outlook Web with event pre-filled |

These buttons ensure even invitees without a Schduled account get the meeting into their calendar.

### Manage Booking Links
Below the calendar buttons, two text links:
- "Reschedule this meeting" — opens rescheduling flow
- "Cancel this meeting" — opens cancellation confirmation

### Custom Confirmation Message
If the host has set a custom message for this event type, it appears below the meeting details:
> "Thanks for booking! Please review our intake guide before our call: [link]"
> Supports basic markdown: bold, links, line breaks.

### Schedule Another Meeting (Optional)
- Small link: "Need another time? View all my event types →"
- Routes back to host's profile overview page
- Useful for recurring clients or invitees who need multiple booking types

---

## Confirmation Email — To Invitee

Sent automatically within seconds of a successful booking. This is the invitee's primary record of their booking.

### Email Subject Line
Default format: "[Confirmed] {event_type} with {host_name} on {date}" — for example, "[Confirmed] 30-Minute Intro Call with Jane Smith on Thursday, June 5". Customizable by host via dynamic variables:
- `{event_type}` — event type name
- `{host_name}` — host's name
- `{date}` — meeting date
- `{time}` — meeting start time

### Email Body Structure

**Section 1 — Header**
- Host's logo or profile photo
- "Your meeting is confirmed" headline
- Brand color applied to header bar

**Section 2 — Meeting Summary**

| Field | Content |
|-------|---------|
| Event | 30-Minute Intro Call |
| Date | Thursday, June 5, 2026 |
| **Your time** | **3:00 PM – 3:30 PM IST (Asia/Kolkata)** — invitee's local timezone, auto-detected |
| **Host's time** | **10:00 AM – 10:30 AM EST (America/New_York)** — so the invitee knows exactly what time the host is expecting them |
| Location | [Join Zoom Meeting](https://zoom.us/j/...) |
| Host | Jane Smith |

> Both timezones are always shown in this section. Calendly only shows the invitee's timezone; Schduled shows both so there is zero ambiguity about when the meeting is for each party.

**Section 3 — Calendar Buttons**
- Google Calendar | Download ICS | Office 365
- Same buttons as confirmation screen

**Section 4 — Your Answers** (if custom questions were asked)
Lists the invitee's own answers for their records — each question label followed by the submitted answer (e.g., Company: Acme Corp, Purpose of call: Product demo, Team size: 45).

**Section 5 — Manage Booking**
- "Reschedule this meeting" link
- "Cancel this meeting" link
- Both use unique secure tokens (no login required to act on them)

**Section 6 — Footer**
- Host's reply-to email address
- No "Powered by Schduled" branding shown (open source)
- Unsubscribe link (GDPR/CAN-SPAM compliant)

---

## Booking Notification Email — To Host

Sent to the host immediately when a new booking is created.

### Email Subject Line
```
New booking: 30-Min Call — Jane Smith on June 5 at 10:00 AM
```

### Email Body Structure

**Section 1 — New Booking Alert**
- "You have a new meeting!" headline
- Invitee name and email address prominently displayed

**Section 2 — Meeting Details**

| Field | Content |
|-------|---------|
| Event | 30-Minute Intro Call |
| Date | Thursday, June 5, 2026 |
| **Your time** | **10:00 AM – 10:30 AM EST (America/New_York)** — host's own timezone |
| **Invitee's time** | **3:00 PM – 3:30 PM IST (Asia/Kolkata)** — so the host immediately knows what time it is for the person they are meeting |
| Location | [Start Zoom Meeting](https://zoom.us/s/...) — "Start" link for host |
| Invitee | Jane Smith (jane@acme.com) |
| Phone | +91 98765 43210 (if collected) |

**Section 3 — Invitee's Answers**
All custom question answers displayed with question labels — each field shown as "Label: Answer" (e.g., Company: Acme Corp, Purpose of call: Product demo, Team size: 45, How they heard about us: LinkedIn).

**Section 4 — Quick Actions**
- "View in dashboard" link → opens meeting detail in Schduled dashboard
- "Cancel this meeting" link (one-click from email)

---

## Calendar Invite

A calendar event is created on the host's calendar and an ICS file is sent to the invitee. Both represent the same meeting.

### Host Calendar Event (Google / Outlook)

| Field | Content |
|-------|---------|
| Title | "30-Min Call with Jane Smith" |
| Date/Time | Booking time in host's timezone |
| Duration | Meeting length |
| Location | Video URL (Zoom/Meet/Teams link) |
| Attendees | Host + invitee (invitee receives invite from calendar) |
| Description | Booking ID, invitee details, video link, form answers |
| Conference | Zoom/Meet/Teams meeting card (platform-native) |

When Schduled adds this event to Google Calendar, Google automatically sends the invitee a calendar invitation from the host's calendar — they receive a second email from Google/Outlook, separate from the Schduled confirmation email. The invitee can accept or decline this calendar invitation.

### Invitee ICS File (Attachment in Confirmation Email)
- RFC 5545-compliant `.ics` file
- Works with: Apple Calendar, Outlook (all versions), Thunderbird, any CalDAV client
- Contains `TZID` property — the invitee's calendar app converts the time to their own local timezone automatically
- One click: "Open with Calendar" adds the event

**Timezone in ICS:** The ICS file uses the **invitee's detected timezone** as the `TZID`. This means:
- An invitee in India opens the `.ics` → their Apple Calendar / Outlook shows the event at 3:00 PM IST
- The same event on the host's Google Calendar shows 10:00 AM EST
- Both parties see the correct local time in their own calendar — no manual conversion needed

**ICS Description field also includes both timezones as plain text:** the invitee's local time, the host's local time, the video join URL, and the reschedule and cancel links — all as readable text in the description body.

This means even users who read the calendar event description (without relying on timezone conversion) can see both times clearly.

---

## Confirmation for Different Booking Types

### Group Event Confirmation *(Post-MVP — Phase 2)*
- Each invitee receives individual confirmation (same template as 1:1)
- All invitees share the same video conference link
- Invitee's confirmation shows: "X other people have also booked this session"
- Host notification shows all confirmed invitees as a list

### Round-Robin Confirmation *(Post-MVP — Phase 2)*
- Assigned host name shown in invitee's confirmation (if host reveal is enabled)
- If host reveal is disabled: event type name shown without host name
- Assigned host receives the host notification email

### Collective (Multi-Host) Confirmation *(Post-MVP — Phase 2)*
- All required hosts receive the host notification email
- Invitee's confirmation shows all host names: "You'll be meeting with Jane Smith and Mike Lee"
- All hosts added as attendees on the calendar event

---

## Confirmation Page for Redirect *(Post-MVP — Phase 2)*

Instead of Schduled's default confirmation screen, hosts can redirect invitees to a custom URL after booking.

**Use Cases:**
- Redirect to an onboarding page: "Now that you've booked, here's what to expect"
- Trigger a Pixel event on a custom page for ad tracking
- Redirect to a community or product portal

**Configuration:** Event type settings → Confirmation → "Redirect to URL after booking" → enter URL.

**Behavior:** As soon as booking is confirmed, browser is redirected. Confirmation email is still sent; only the screen is replaced.

---

## Confirmation Email Delivery

### Delivery Target
- Invitee confirmation: delivered within 30 seconds of booking
- Host notification: delivered within 30 seconds of booking

### Delivery Provider
- Transactional email via Nodemailer (rendered with React Email, sent via SMTP)
- Dedicated sending domain for deliverability (e.g., `notifications.schduled.com`)
- SPF, DKIM, and DMARC configured to prevent spam classification

### Delivery Tracking
- Delivery failures logged via `console.error` and visible in dashboard alert *(MVP)*
- Open tracking and bounce detection require SMTP feedback loops — **Post-MVP**

### Retry on Failure
- Failed delivery retried 2 times with 5-minute spacing
- If all retries fail: logged in booking record; host notified via dashboard alert

---

## Customizing the Confirmation

### Custom Confirmation Message
- Set per event type
- Shown on confirmation screen and included in confirmation email
- Supports markdown: `**bold**`, `[link text](url)`, line breaks
- Use cases:
  - "Please fill out this prep form: [link]"
  - "Here's our meeting agenda template: [link]"
  - "Bring your last 3 months of data if you have it"

### Custom Email Subject Line *(Post-MVP — Phase 2)*
- Replace default subject with custom text
- Dynamic variables supported: `{invitee_name}`, `{date}`, `{time}`, `{event_type}`
- Example: "Your {event_type} with us is confirmed for {date}!"

> **Why Phase 2:** Custom subject lines require a template editor UI. For MVP, Schduled ships one well-crafted default subject line per email type. Hosts can add a custom message to the body. Subject line customisation ships in Phase 2.

### From Name and Reply-To
- Emails appear "from" the host's name, not "Schduled"
- Example: From: `Jane Smith <notifications@schduled.com>`
- Reply-to set to host's actual email so replies go directly to host

---

## Reference Implementations

| App | Confirmation Approach | Timezone in Email |
|-----|----------------------|------------------|
| **Calendly** | Confirmation screen with calendar buttons; email to both; ICS; reschedule/cancel links | **Invitee's timezone only** — host timezone not shown to invitee, invitee timezone not shown to host |
| **Cal.com** | Same as Calendly; custom redirect; open source | Invitee's timezone only in most templates |
| **SavvyCal** | Clean confirmation; email confirmation; ICS | Invitee's timezone; host timezone shown on booking page but not always in email |
| **Chili Piper** | Instant confirmation; CRM update on confirm | Host timezone; invitee timezone shown if configured |
| **HubSpot Meetings** | Confirmation + calendar; auto-creates HubSpot contact | Invitee's timezone only |
| **Schduled** | Same core flow + **both timezones shown in every email** — invitee sees their time AND host's time; host sees their time AND invitee's time | **Both timezones always shown** — no ambiguity for either party |

---

## MVP Scope

**In MVP:**
- Confirmation screen with success animation, meeting summary, add-to-calendar buttons
- **Dual-timezone display on confirmation screen** — invitee's time + host's equivalent time both shown
- Invitee confirmation email (within 30 seconds) — **both invitee time and host time shown**
- Host notification email (within 30 seconds) — **both host time and invitee time shown**
- ICS file attachment for invitees (in invitee's detected timezone; both times in description text)
- Google Calendar event creation (host's calendar)
- Outlook calendar event creation (host's calendar)
- Reschedule and cancel links in confirmation email
- Custom confirmation message (per event type)
- From name and reply-to customization
- Invitee's form answers in both emails (answers stored in `booking_answers`; included in host notification and invitee confirmation)

**Post-MVP:**
- Custom email subject line with dynamic variables *(Post-MVP — Phase 2 — requires template editor UI)*
- Confirmation page redirect to custom URL
- Pixel tracking on custom confirmation page
- Open/bounce tracking
- Group event invitee count display
- Round-robin and collective event type confirmations *(Post-MVP — Phase 2)*


---

## Background Jobs

All confirmation work runs as pg-boss jobs after the booking DB transaction commits. The booking API returns `{ ok: true, booking }` to the browser immediately — none of these jobs block the response.

| Job Name | Trigger | Payload | pg-boss Config |
|----------|---------|---------|----------------|
| `EMAIL_SEND` | After booking confirmed (invitee) | `{ emailOutboxId }` | retryLimit: 0 (state machine), localConcurrency: 5 |
| `EMAIL_SEND` | After booking confirmed (host notification) | `{ emailOutboxId }` | retryLimit: 0 (state machine), localConcurrency: 5 |
| `CALENDAR_WRITE` | After booking confirmed | `{ bookingId, calendarId }` | retryLimit: 3, retryDelay: 15s, localConcurrency: 1 |
| `VIDEO_LINK_GENERATE` | After booking confirmed (if location = zoom or teams) | `{ bookingId, provider }` | retryLimit: 3, retryDelay: exponential (5s→30s→120s), localConcurrency: 3 |

> **All handlers use `workMonitored()`** — every handler is registered with `workMonitored('JOB_NAME', handler)` not raw `boss.work()`. See `jobs-queues.md` — "Dead-Letter Queue Monitoring" for the DLQ pattern.

---

## Tech Stack

- **pg-boss** — confirmation emails are sent as async background jobs after the booking API returns. The invitee sees the confirmation screen immediately; email delivery happens within seconds in the background. This prevents email provider latency from affecting booking response time.
- **Nodemailer (SMTP)** — delivers both the invitee confirmation email (with ICS attachment) and the host notification email. The SMTP server should be configured with proper SPF/DKIM/DMARC records to ensure high deliverability and prevent spam classification.
- **ical-generator** — generates the RFC 5545-compliant `.ics` calendar invite file attached to the invitee's confirmation email. Includes `TZID` so the event displays correctly in Apple Calendar, Outlook, and Google Calendar.
- **Google Calendar API** — the `CALENDAR_WRITE` background job creates the host's calendar event on Google Calendar after the booking is confirmed. Google also automatically sends the invitee a calendar invitation email.
- **Microsoft Graph API** — same as Google Calendar, but for hosts using Outlook/Office 365. The calendar event is created via the Graph API with the invitee as an attendee.
