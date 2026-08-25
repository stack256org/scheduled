# Calendar Integrations

Calendar integrations are the foundation of Schduled's scheduling intelligence. By connecting to external calendars, Schduled reads real-time busy/free data and writes new bookings back — ensuring availability is always accurate and meetings are never double-booked.

---

## Overview

A connected calendar serves two purposes:
1. **Read availability** — Schduled reads the calendar's events to know when the host is busy
2. **Write new bookings** — When a meeting is booked, Schduled adds it to the host's calendar automatically

Hosts can connect multiple calendars. All are read for availability, but new bookings are written to one designated calendar.

---

## User Stories

**Host**
- As a host, I want to connect my Google Calendar with OAuth, so that my availability is always accurate without sharing my password. *(MVP)*
- As a host, I want to connect multiple calendars (work and personal), so that Schduled checks all of them for conflicts before showing available slots. *(MVP)*
- As a host, I want new bookings to be automatically added to my chosen calendar, so that I never have to manually create calendar events after someone books me. *(MVP)*
- As a host, I want to connect my Outlook or Office 365 calendar, so that my work calendar is included in availability checks. *(MVP)*
- As a host, I want to connect my Apple iCloud calendar, so that my personal schedule is factored into my availability. *(Phase 2 — CalDAV lacks OAuth; deferred post-MVP)*
- As a host, I want to disconnect a calendar at any time, so that I can switch providers or remove a calendar without losing my Schduled setup. *(MVP)*
- As a host, I want calendar sync to happen in real-time, so that a newly added personal event blocks my availability before the next person tries to book that slot. *(MVP)*

---

## Supported Calendars

### Google Calendar

The most widely used calendar integration.

**Features:**
- Full OAuth 2.0 authentication (no password sharing)
- Read all calendars in the Google account (primary + secondary)
- Sync events in real-time
- Write new bookings to the designated calendar
- Supports multiple Google accounts (connect work + personal)
- Reads recurring events
- DST-aware timezone handling

**Setup Flow:**
1. Click "Connect Google Calendar"
2. Redirected to Google OAuth consent screen
3. Authorize Schduled to read and write calendar events
4. Select which calendars to check for conflicts
5. Select which calendar to add bookings to

**Scopes Required:**
- `calendar.readonly` — read all calendars for availability
- `calendar.events` — create/update/delete booking events

---

### Microsoft Outlook / Office 365

For Microsoft 365 accounts (work or school) and personal Outlook.com accounts.

**Features:**
- OAuth 2.0 via Microsoft Graph API
- Connects to primary Outlook calendar and room calendars
- Supports Microsoft Exchange (via Microsoft 365)
- Real-time sync via Graph API subscriptions
- Write new events with Teams meeting links
- Supports shared calendars (view-only)
- Respects "Working Hours" set in Outlook

**Setup Flow:**
1. Click "Connect Outlook / Office 365"
2. Microsoft login and consent screen
3. Authorize Schduled access
4. Select calendars to sync

**Compatibility:**
- Office 365 personal and business accounts
- Outlook.com (free Microsoft accounts)
- Microsoft Exchange 2016+ (via Exchange Web Services bridge)

---

### Apple Calendar / iCloud *(Post-MVP — Phase 2)*

> Note: Calendly dropped iCloud support in August 2024. Schduled will support it in Phase 2 — CalDAV lacks standard OAuth and requires app-specific passwords, making it more complex than Google/Outlook. Phase 2 differentiator vs Calendly.

**Features:**
- iCloud CalDAV integration
- Supports all iOS/macOS users with iCloud accounts
- Read busy/free from iCloud calendar
- Write new bookings to iCloud calendar (syncs to iPhone/Mac automatically)
- Requires app-specific password (Apple security requirement)

**Setup Flow (with guided UX for non-technical users):**
1. User clicks "Connect Apple Calendar"
2. Schduled shows an **inline step-by-step guide** (not just a link) with screenshots:
   - Step A: "Go to [appleid.apple.com/account/manage](https://appleid.apple.com) and sign in"
   - Step B: "Scroll to the **Sign-In and Security** section → click **App-Specific Passwords**"
   - Step C: "Click **+** (Generate Password) → name it 'Schduled' → click Create"
   - Step D: "Copy the 16-character password shown (it won't be shown again)"
3. User enters their iCloud email address
4. User pastes the app-specific password into the Schduled input field
5. Schduled connects via CalDAV and lists available iCloud calendars
6. User selects which calendars to check for conflicts and which to write bookings to

**Error Handling:**
- Wrong password: "Incorrect app-specific password. Please generate a new one and try again." — with link back to step-by-step guide
- 2FA block: "Your iCloud account requires additional verification. Complete it at appleid.apple.com, then try again."
- No iCloud calendars found: "No calendars found. Ensure iCloud Calendar is enabled on your Apple device."

**Why App-Specific Passwords Exist (shown to user):**
> "Apple does not allow third-party apps to use your main Apple ID password. An app-specific password is a one-time generated code that gives Schduled permission to read your calendar — without sharing your real password. You can revoke it at any time from appleid.apple.com."

**Why Apple Calendar Matters:**
- ~26% of mobile users in the US use iOS
- Many freelancers and creatives primarily use Apple Calendar
- Calendly's removal created a clear gap; Schduled fills it

---

### CalDAV (Generic)

Open standard for calendar sync. Connects to any CalDAV-compatible calendar server.

**Compatible Systems:**
- Fastmail Calendar
- Zoho Calendar
- SOGo
- Nextcloud Calendar
- Fruux
- DAViCal
- Any RFC 4791-compliant calendar server

**Setup:**
- Provide CalDAV server URL, username, and password (or token)
- Schduled polls for updates at regular intervals (no real-time webhook)

---

### Exchange (On-Premise)

For organizations running self-hosted Microsoft Exchange servers (not Office 365).

**Features:**
- EWS (Exchange Web Services) integration
- Reads and writes to Exchange calendar
- Requires Exchange 2013 or later
- May require IT admin configuration for app access

**Target Users:** Large enterprises with on-premise infrastructure who cannot use cloud Microsoft 365.

---

## Multi-Calendar Support

Hosts can connect multiple calendars simultaneously across different providers.

### Use Cases
- Personal Google Calendar + Work Outlook Calendar
- Two Google accounts (personal + client-facing)
- Google Calendar + iCloud Calendar

### How It Works
- All connected calendars are read for conflicts
- A busy event on ANY connected calendar blocks the slot
- Bookings are written to only ONE designated "add bookings to" calendar
- Host selects the primary booking calendar during setup

### Calendar Priority
- When multiple calendars are connected, all are checked for free/busy
- The "check for conflicts" selection is per calendar (toggle on/off per calendar)
- The "add bookings to" is a single-calendar selection

---

## Calendar Event Details Written on Booking

When a meeting is booked, Schduled creates a calendar event with:

| Field | Content |
|-------|---------|
| Title | Event type name + Invitee name (e.g., "30-Min Intro Call with Jane Smith") |
| Date/Time | Confirmed meeting time |
| Duration | Meeting length |
| Location | Video link (Zoom/Meet/Teams) or physical address |
| Description | Invitee details, custom question answers, booking notes |
| Attendees | Host email + Invitee email (both receive invites) |
| Video Link | Auto-embedded Zoom/Meet/Teams link |
| Organizer | Host's name and email |

---

## Real-Time Sync Architecture

### Read Path (Availability Check)
- Schduled queries calendars when invitee opens booking page
- Cached availability refreshed every 5 minutes (configurable)
- On booking confirmation: final check in real-time to prevent race conditions
- Uses push notifications (Google/Outlook) where available for instant refresh

### Write Path (New Booking)
- On booking confirmation: event created immediately via API
- Retries on failure with exponential backoff
- Booking shown as pending until calendar write confirmed

### Disconnect Handling
- **Immediate email alert fires the moment token refresh fails** — this is the primary notification, not the dashboard banner; a host may not check the dashboard for days but will see an email within minutes
- Email: "Your [Google Calendar / Outlook] has been disconnected — reconnect to resume bookings" with a direct reconnect link
- All booking pages automatically disabled until calendar is reconnected — invitees see "This calendar is currently unavailable"
- Dashboard also shows a prominent banner: "⚠️ Calendar sync interrupted — your booking pages are paused" (secondary indicator)
- On reconnect: booking pages re-enable automatically, no manual action required

---

## Timezone Handling

- All events stored in UTC internally
- Displayed in host's timezone in dashboard
- Displayed in invitee's timezone on booking page
- Calendar events written with correct timezone metadata
- DST transitions handled automatically

---

## Room and Resource Calendars

For enterprise users scheduling physical meeting rooms:

- Connect room calendars (via Outlook/Exchange or Google Workspace)
- Add room as a required resource on event types
- Booking only shown when both host AND room are available
- Room automatically "reserved" when booking confirmed

---

## Integration Permissions and Security

| Permission | Why Needed |
|-----------|-----------|
| Read calendar events | Check free/busy for availability |
| Create calendar events | Add booking to calendar |
| Update calendar events | Update on reschedule |
| Delete calendar events | Remove on cancellation |
| Read attendee free/busy | Collective event scheduling |

**Security:**
- OAuth tokens stored encrypted at rest
- Tokens never exposed to frontend
- Scopes requested are minimal (principle of least privilege)
- Users can revoke access anytime from both Schduled and their calendar provider

---

## Reference Implementations

| App | Google Calendar | Outlook / Office 365 | Apple / iCloud | CalDAV (generic) | Multi-Calendar (connect 2+) | Real-Time Sync |
|-----|----------------|---------------------|----------------|-----------------|----------------------------|----------------|
| **Calendly** | ✅ Yes | ✅ Yes | ❌ **Dropped Aug 2024** | ❌ No | ✅ Up to 6 calendars | ✅ Push notifications |
| **Cal.com** | ✅ Yes | ✅ Yes | ✅ iCloud CalDAV | ✅ Zoho, Nextcloud, etc. | ✅ Yes | ✅ Yes |
| **SavvyCal** | ✅ Yes | ✅ Yes | ✅ iCloud CalDAV | ❌ No | ✅ Yes | ✅ Yes |
| **Chili Piper** | ✅ Yes | ✅ Yes | ❌ No | ❌ No | ✅ Yes | ✅ Yes |
| **HubSpot Meetings** | ✅ Yes | ✅ Office 365 | ❌ No | ❌ No | ❌ One calendar only | ✅ Yes |
| **Schduled** | ✅ Yes — OAuth 2.0; also generates Google Meet links | ✅ Yes — Microsoft Graph; also creates Teams meetings | ✅ **Phase 2 — iCloud CalDAV** — direct differentiator vs Calendly (who dropped it Aug 2024) | ✅ Phase 2 | ✅ Up to 3 calendars in MVP (Google + Outlook only); Apple adds Phase 2 | ✅ 5-min polling in MVP; push notifications Phase 2 |

---

## MVP Scope

**In MVP — P0 (build first, launch blocker):**
- Google Calendar (OAuth 2.0) — most freelancers and solopreneurs use Google; simpler OAuth, more consistent API; ship this first
- Calendar event creation on booking, update on reschedule, deletion on cancellation
- Multi-calendar conflict detection (connect up to 2 Google calendars)
- Token expiry detection with immediate email alert

**In MVP — P1 (sprint 2, after Google is stable):**
- Outlook / Office 365 (Microsoft Graph API) — Microsoft Graph adds a second token system and different event format; build after Google is fully tested
- Extends multi-calendar to Google + Outlook (up to 2 calendars across providers)

**Post-MVP:**
- Apple Calendar / iCloud (CalDAV with app-specific password) *(Phase 2 — lacks OAuth, complex protocol)*
- CalDAV (generic servers — Nextcloud, Fastmail, etc.) *(Phase 2)*
- Exchange (on-premise EWS) *(Phase 2)*
- Room and resource calendars
- Real-time push notification sync (vs polling)
- Calendar health monitoring dashboard


---

## Background Jobs

| Job Name | Trigger | Payload | pg-boss config |
|----------|---------|---------|---------------|
| `CALENDAR_SYNC` | Cron — every 5 minutes | `{ connectedCalendarId }` | singletonKey: `calendar_sync_{connectedCalendarId}`; prevents duplicate syncs for the same calendar |
| `CALENDAR_TOKEN_REFRESH` | Before any calendar API call when `tokenExpiresAt < now()` | `{ connectedCalendarId }` | retryLimit: 3; on 3rd failure → enqueue `CALENDAR_DISCONNECT_ALERT` |
| `CALENDAR_DISCONNECT_ALERT` | When `CALENDAR_TOKEN_REFRESH` fails permanently (all retries exhausted) | `{ connectedCalendarId, userId }` | Marks calendar `status='disconnected'`; enqueues `EMAIL_SEND` with disconnect alert template |
| `CALENDAR_WRITE` | After booking confirmed | `{ bookingId, calendarId }` | retryLimit: 3; retryDelay: 15s |
| `CALENDAR_UPDATE` | After booking rescheduled | `{ bookingId, calendarId, externalEventId }` | retryLimit: 3 |
| `CALENDAR_CANCEL` | After booking cancelled | `{ bookingId, calendarId, externalEventId }` | retryLimit: 2 |

### CALENDAR_SYNC cron (every 5 min)

The 5-minute sync job polls the calendar provider for events within the next 60 days and upserts them into `calendar_events_cache`. The job uses a `singletonKey` of `calendar_sync_{connectedCalendarId}` so two sync jobs for the same calendar can never run simultaneously. Push notifications (Google Calendar push channels, Outlook subscriptions) replace polling in Phase 2.

### Disconnect → Alert Flow

When a token refresh fails permanently, the entire disconnect flow is:
1. `CALENDAR_TOKEN_REFRESH` exhausts 3 retries
2. Handler calls `DbCalendars.markDisconnected(connectedCalendarId)`
3. Handler enqueues `EMAIL_SEND` with template `calendar-disconnect-alert`:
   - Subject: "Your [Google Calendar / Outlook] has been disconnected"
   - Body: reconnect link + list of affected booking pages now paused
4. Booking pages with this calendar as write target are automatically disabled (checked at slot-generation time via `status = 'disconnected'`)
5. Audit log entry: `calendar.disconnected`

## Audit Logging

| Event | Audit Action | source |
|-------|-------------|--------|
| Calendar connected (OAuth success) | `calendar.connected` | `'web'` (Server Action after OAuth callback) |
| Calendar disconnected (manual) | `calendar.disconnected` | `'web'` (Server Action) |
| Calendar disconnected (token failure) | `calendar.disconnected` | `'worker'` (fired by `CALENDAR_DISCONNECT_ALERT` job) |

Every `audit_logs` insert must include `source: 'web' | 'api' | 'worker' | 'system'`. The `source` distinguishes user-initiated disconnects from automatic token expiry disconnects — useful for support triage. See `database-schema.md` for `auditSourceEnum`.

---

## Tech Stack

- **Google Calendar API (OAuth 2.0)** — reads free/busy events from all calendars on the host's Google account and writes new bookings as calendar events. Google Meet links are generated automatically as part of event creation (no separate Meet API call).
- **Microsoft Graph API (OAuth 2.0)** — connects Outlook and Office 365 calendars for free/busy sync and booking writes. The same OAuth token is also used to create Teams meeting links (Phase 2).
- **Apple CalDAV (iCloud) + `tsdav`** *(Phase 2)* — connects iCloud calendars using the CalDAV protocol with app-specific password (no OAuth). Uses the [`tsdav`](https://www.npmjs.com/package/tsdav) npm package — the TypeScript CalDAV client. Install: `pnpm add tsdav`. Also used for generic CalDAV servers (Nextcloud, Fastmail).
- **PostgreSQL + Drizzle ORM** — stores OAuth access and refresh tokens in `connected_calendars` (AES-256-GCM encrypted) and caches free/busy events in `calendar_events_cache` to avoid querying provider APIs on every slot request. Connect/disconnect events are written to `audit_logs`.
- **pg-boss** — `CALENDAR_SYNC` cron runs every 5 min per connected calendar to refresh `calendar_events_cache`. `CALENDAR_TOKEN_REFRESH` handles token renewal before API calls. `CALENDAR_DISCONNECT_ALERT` fires when refresh fails permanently and triggers the disconnect email + booking page disable flow. `CALENDAR_WRITE`, `CALENDAR_UPDATE`, `CALENDAR_CANCEL` handle post-booking calendar mutations asynchronously. All handlers registered with `workMonitored()` — see `jobs-queues.md` for the dead-letter queue pattern.
