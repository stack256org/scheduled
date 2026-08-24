# Video Conferencing

Video Conferencing integration automatically generates a unique meeting link for every booking — no more manually creating Zoom meetings, copying links, or forgetting to add a video URL to calendar invites. The link is created the moment a booking is confirmed and included in every notification.

---

## Overview

When an invitee books a meeting, Schduled immediately calls the video platform's API to create a new meeting room. A unique join link is generated per booking and sent to both host and invitee in the confirmation email, the calendar invite, and all reminder emails.

This eliminates two major pain points:
1. Hosts forgetting to create a video meeting and scrambling before the call
2. Invitees using a shared "permanent" link that exposes previous meeting recordings or chat history

---

## User Stories

**Host**
- As a host, I want to connect my Zoom account once, so that every new booking automatically gets a unique Zoom link without any manual steps from me. *(MVP)*
- As a host, I want to connect Google Meet, so that meetings are automatically created in Google Meet for each booking. *(MVP)*
- As a host, I want each booking to receive its own unique video link, so that past meeting recordings and chats are not accessible in new meetings. *(MVP)*
- As a host, I want the video link to appear in the calendar invite and confirmation email automatically, so that invitees always have the link without me sending it manually. *(MVP)*
- As a host, I want to set a default video platform per event type, so that client calls use Zoom while internal meetings use Google Meet. *(MVP)*
- As a host, I want to connect Microsoft Teams, so that meetings with enterprise clients are held in the platform they already use. *(Phase 2)*

**Invitee**
- As an invitee, I want to receive a unique join link in my confirmation email, so that I can join the meeting with one click. *(MVP)*
- As an invitee, I want the join link to also appear in my reminder emails, so that I can find it easily without searching through old messages. *(MVP)*

---

## Supported Platforms

> **Build priority:**
> - **P0 — Google Meet:** Free, no approval process, no separate OAuth. Link generated automatically as part of the Google Calendar event — any host with Google Calendar connected gets it instantly. Ship first.
> - **P1 — Zoom:** Requires Zoom Marketplace approval (2–4 weeks). Submit on Day 1 of development. Use dev-mode app during development; switch to published app before launch.
> - **Phase 2 — Microsoft Teams:** Requires Outlook calendar connected (full Microsoft Graph OAuth stack). Minority of solo freelancer users. Build after MVP is stable.

### Zoom

The most widely used business video conferencing platform.

**Features:**
- Unique Zoom meeting created per booking via Zoom API
- Host receives "Start Meeting" link; invitee receives "Join Meeting" link
- Meeting ID and passcode auto-generated
- Waiting room settings respected (if enabled in host's Zoom account)
- Meeting title set to event type name + invitee name
- Meeting duration set to match the booking duration
- Auto-recording enabled if configured in host's Zoom settings

**Connection:**
- OAuth 2.0 — host connects their Zoom account once
- Requires a Zoom account (Free Zoom account is sufficient)
- One Zoom account per Schduled user

> ⚠️ **Zoom Marketplace Approval Required**
> Creating unique meeting links via the Zoom API requires a published Zoom OAuth app approved through the [Zoom Marketplace](https://marketplace.zoom.us). Approval requires a publicly accessible privacy policy, terms of service, and a working demo. Review can take **2–4 weeks**. Submit the app early — this is a hard dependency before Zoom integration can go live for all users. During development, use a development-mode OAuth app (works for up to 100 users without approval).

**Link Format:** A unique `zoom.us/j/{meetingId}?pwd={password}` URL generated per booking via the Zoom API.

**Setup:**
1. Go to Profile & Settings → Integrations → Zoom
2. Click "Connect Zoom Account"
3. Authorize Schduled in Zoom OAuth window
4. Connection confirmed — Zoom available as location on all event types

---

### Google Meet

Auto-generates a Google Meet link as part of calendar event creation. No separate API call needed — the link is created when the Google Calendar event is written.

**Features:**
- Unique Meet link per booking
- No capacity limits (Google Meet supports up to 100 participants on free Google accounts)
- No additional connection step required — uses the existing Google Calendar connection
- Link generated only when Google Calendar is the connected calendar

**Requirement:**
- Host must have Google Calendar connected (see calendar-integrations.md)
- Works with both personal Google accounts and Google Workspace accounts

**Link Format:** A unique `meet.google.com/{code}` URL generated automatically as part of the Google Calendar event creation.

**How It Works:**
- When Schduled creates the Google Calendar event for the booking, it includes `conferenceData.createRequest` in the API call
- Google Calendar API auto-generates and attaches a unique Meet link
- Link returned in the API response and stored in the booking record

---

### Microsoft Teams *(Post-MVP — Phase 2)*

Auto-generates a Teams meeting link via the Microsoft Graph API.

**Features:**
- Unique Teams meeting created per booking
- Works with Microsoft 365 paid accounts and Teams Free
- Teams meeting appears in the host's Teams calendar
- In-meeting chat, recording, and transcription available (per Teams settings)
- Requires Microsoft Outlook / Office 365 calendar connection

**Requirement:**
- Host must have Outlook / Office 365 connected (see calendar-integrations.md)
- Microsoft 365 Business Basic or higher recommended for full features

**Link Format:** A `teams.microsoft.com/l/meetup-join/...` URL returned in the `joinWebUrl` field from the Microsoft Graph API.

**How It Works:**
- Schduled calls `POST /v1.0/users/{userId}/onlineMeetings` on the Microsoft Graph API
- Returns a `joinWebUrl` stored as the meeting location

---

### Webex *(Post-MVP — Phase 2)*

Integration with Cisco Webex for enterprises and teams using Webex as their video platform.

**Features:**
- Unique Webex meeting per booking via Webex REST API
- Requires Webex account (Free or paid)
- Meeting password auto-generated
- Host and co-host access controls respected

**Connection:**
- OAuth 2.0 via Webex developer app
- Connect once in Profile & Settings → Integrations → Webex

---

### GoTo Meeting *(Post-MVP — Phase 2)*

Integration with GoTo Meeting (formerly GoToMeeting by LogMeIn).

**Features:**
- Unique meeting room per booking via GoTo Meeting API
- Dial-in phone numbers included in meeting details
- Recording settings from GoTo account respected

**Connection:**
- OAuth via GoTo Meeting developer portal
- Connect once in Profile & Settings → Integrations → GoTo Meeting

---

### Custom Video Link (Any Platform)

For platforms not natively supported, hosts can use a permanent or custom link.

**Use Cases:**
- Whereby (permanent room links)
- Jitsi Meet (self-hosted)
- Around
- Any other platform with a shareable URL

**How It Works:**
- Host pastes a permanent meeting URL in the "Custom" location field on the event type
- Same URL included in every booking for that event type
- No API integration — host manages the video platform separately

**Limitation:** Same link shared for all bookings — no per-booking uniqueness.

---

## Invitee Choice of Video Platform

For event types with multiple location options enabled, the invitee can choose their preferred video platform at booking time.

**Example:**
Host has connected Zoom and Google Meet. Event type is set to "Invitee's Choice."

Invitee sees:
> "How would you like to meet?"
> ○ Zoom
> ○ Google Meet

Schduled creates a meeting on the selected platform and sends the appropriate link.

**Configuration:** Enable in event type settings → Location → "Let invitee choose" → select which platforms to offer.

---

## How the Link Reaches the Invitee

The video link is delivered in multiple places to ensure the invitee never loses it:

| Delivery Point | Details |
|---------------|---------|
| Confirmation email (immediate) | Prominently displayed as a large "Join Meeting" button |
| Calendar invite | In the Location field and event description |
| 24-hour reminder email | Meeting link repeated; "Join Meeting" button |
| 1-hour reminder email | Meeting link repeated; large prominent button |
| Meetings Dashboard (host) | "Join" button active 15 minutes before start |
| Booking confirmation page | Shown immediately after booking |

---

## Meeting Link in the Host's Calendar Invite

When Schduled writes the booking to the host's calendar:

**Google Calendar:**
- Conference data embedded (shows in Google Calendar UI as a "Join with Google Meet" button)
- Location field contains the video URL
- Description includes the full join link as text

**Outlook:**
- Location field contains the video URL
- Body of the meeting contains the formatted video link
- For Teams: Teams meeting card shown natively in Outlook

---

## Per-Booking Unique Links (Why It Matters)

Calendly and Schduled both create a new unique meeting room per booking. This is important because:

- **Privacy:** Previous attendees cannot re-join a meeting using an old link
- **Security:** No "room squatting" by someone who had a previous link
- **Recording isolation:** Each meeting has its own recording, not mixed with others
- **Cleaner history:** Each Zoom/Teams meeting shows the correct title and participant list

---

## Video Platform Connection Status

In Profile & Settings → Integrations, each connected video platform shows:

| Status | Meaning |
|--------|---------|
| 🟢 Connected | Active and working |
| 🔴 Disconnected | Token expired or revoked — click to reconnect |
| ⚠️ Error | API quota or permission issue — check platform account |

If a platform disconnects and a new booking comes in:
- Booking still created successfully — video link failure never blocks a booking
- pg-boss retries video link generation 3× with exponential backoff (5s → 30s → 2min)
- If all 3 retries fail: host receives alert email "Video link generation failed for [Invitee Name]'s booking — please add the meeting link manually"
- Invitee confirmation email shows: "Your video link will be sent shortly" — no broken links visible to invitee

---

## Video Conferencing and Recording Notice

When AI Notetaker is enabled (Phase 2 feature), a recording notice is automatically appended to the video meeting details in confirmation emails:

> "This meeting may be recorded and transcribed by Schduled Notetaker. You will be notified at the start of the meeting."

Hosts can disable this notice or the recording feature per event type.

---

## Reference Implementations

| App | Supported Platforms | Unique Link per Booking | Invitee Choice | Built-in Video |
|-----|---------------------|------------------------|----------------|----------------|
| **Calendly** | Zoom, Google Meet, Teams, Webex, GoTo Meeting | ✅ Yes — new room per booking | ✅ Yes — invitee picks platform | ❌ No |
| **Cal.com** | Zoom, Meet, Teams, Webex, Jitsi, Around, Daily.co | ✅ Yes | ✅ Yes | ✅ Cal Video (Daily.co powered) |
| **SavvyCal** | Zoom, Google Meet, Teams | ✅ Yes | ❌ No | ❌ No |
| **Chili Piper** | Zoom, Teams, Meet | ✅ Yes | ❌ No | ❌ No |
| **HubSpot Meetings** | Zoom, Teams | ✅ Via calendar event creation | ❌ No | ❌ No |
| **Schduled** | Google Meet (P0), Zoom (P1), Teams (Phase 2); Webex, GoTo (Phase 3) | ✅ Yes — unique room per booking; no shared permanent links | ✅ Yes — invitee selects if host has 2+ platforms connected | ❌ No — Phase 3 consideration |

---

## MVP Scope

**In MVP — P0 (Google Meet first):**
- Google Meet (P0 — via Google Calendar API, no separate OAuth, free)
- Zoom (P1 — unique link per booking; submit Marketplace approval on Day 1 of development)
- Custom URL (permanent link for unsupported platforms)
- Invitee's choice (if host has both Google Meet and Zoom connected)
- Link in confirmation email, calendar invite, and reminder emails
- "Join" button on Meetings Dashboard (active 15 min before)
- Graceful failure handling (3× retry with exponential backoff; host alert if all fail)

**Post-MVP:**
- Microsoft Teams (Phase 2 — requires full Outlook/Microsoft Graph OAuth; minority of solo users)
- Webex (Phase 3)
- GoTo Meeting (Phase 3)
- Jitsi Meet — self-hosted option (Phase 3)
- Auto-reconnect if token expires before booking (Phase 2)


---

## Background Jobs

| Job Name | Trigger | Payload | pg-boss config |
|----------|---------|---------|---------------|
| `VIDEO_LINK_GENERATE` | After booking confirmed (if location = zoom or teams) | `{ bookingId, provider: 'zoom' \| 'teams' }` | retryLimit: 3, retryDelay: exponential (5s → 30s → 120s); singletonKey: `{bookingId}_video_link`; **localConcurrency: 3** |
| `VIDEO_LINK_RETRY` | Spawned by `VIDEO_LINK_GENERATE` handler on retryable error | `{ bookingId, provider, attempt }` | Manual retry job (separate from pg-boss auto-retry) for cases like rate limiting |

> **All handlers use `workMonitored()`** — register handlers with `workMonitored('VIDEO_LINK_GENERATE', handler)` not raw `boss.work()`. The DLQ callback fires when all 3 retries are exhausted — use it to send the "video link failed" alert email. See `jobs-queues.md` — "Dead-Letter Queue Monitoring".

### Retry Pattern

The `VIDEO_LINK_GENERATE` handler calls the Zoom API to create the meeting, stores the host start URL and invitee join URL on the booking record, and updates any pending `email_outbox` rows so the confirmation emails include the correct link. On failure, pg-boss retries up to 3 times with exponential backoff (5s → 30s → 120s). After all 3 retries are exhausted: the booking remains confirmed (video failure never blocks the booking), the host receives an `EMAIL_SEND` alert "Video link generation failed — add link manually", and the invitee's confirmation email shows "Your video link will be sent shortly" instead of a broken link.

### Google Meet — No Background Job Needed

Google Meet links are generated **inline** during `CALENDAR_WRITE` — when creating the Google Calendar event, the `conferenceData.createRequest` field in the API request body causes Google to auto-generate and attach a Meet link. The handler reads the Meet URL from the response and stores it on the booking record. No separate `VIDEO_LINK_GENERATE` job is needed for Google Meet hosts.

---

## Tech Stack

- **Zoom API (OAuth 2.0)** — creates a unique Zoom meeting room per booking via `POST /v2/users/me/meetings`. The host connects their Zoom account once in Settings; Schduled stores the OAuth token (AES-256-GCM encrypted) and uses it for every future booking via `VIDEO_LINK_GENERATE` pg-boss job.
- **Microsoft Graph API** *(Phase 2)* — creates Microsoft Teams meetings via `POST /v1.0/users/{userId}/onlineMeetings`. Reuses the same OAuth token already stored for the host's Outlook calendar connection — no separate Teams login needed. Built in Phase 2 after Google Meet and Zoom are stable.
- **Google Calendar API** — Google Meet links are generated automatically as part of `CALENDAR_WRITE` job's Google Calendar event creation (no separate `VIDEO_LINK_GENERATE` job needed for Meet hosts).
- **PostgreSQL + Drizzle ORM** — stores Zoom and Webex OAuth tokens (AES-256-GCM encrypted) in `video_connections`. Teams tokens are reused from `connected_calendars`. The generated video link is stored in `bookings.locationValue`.
- **pg-boss** — `VIDEO_LINK_GENERATE` runs asynchronously after booking confirmation so the booking API responds instantly. Retries automatically 3× with exponential backoff (5s → 30s → 120s). On permanent failure: host receives alert email via `EMAIL_SEND` job; invitee confirmation email shows "Your video link will be sent shortly". Uses `singletonKey: {bookingId}_video_link` to prevent duplicate link generation.
