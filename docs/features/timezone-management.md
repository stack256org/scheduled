# Timezone Management

Timezone management ensures every host and invitee sees meeting times in their own local timezone — automatically and accurately. Without this, an invitee in Tokyo booking a host in New York would see confusing or wrong times, leading to missed meetings.

---

## Overview

Timezone is one of the most error-prone aspects of scheduling. Schduled handles timezone conversion at every step — so neither the host nor the invitee ever has to manually calculate "what time is that for me?"

> **Strategic importance — read before touching this feature:**
> Dual-timezone display in every email is Schduled's #1 competitive advantage. Calendly, Cal.com, and every other mainstream scheduling tool shows only one party's timezone per email. Schduled shows both. This eliminates the #1 cause of missed meetings ("we showed up at different times") and is a concrete, demonstrable differentiator that any user can verify in 30 seconds.
>
> This is a **strategic feature, not a cosmetic one.** Every change to email templates, booking confirmation UI, or availability display must preserve the dual-timezone output. Do not simplify, remove, or make it optional.

There are two timezone contexts to manage:
1. **Host timezone** — The timezone the host's availability is defined in
2. **Invitee timezone** — The timezone the booking page displays times in (auto-detected from the invitee's browser/device)

---

## User Stories

**Host**
- As a host, I want to set my timezone once during onboarding, so that all my availability and dashboard times are displayed correctly from day one. *(MVP)*
- As a host, I want all bookings in my dashboard shown in my own timezone, so that I do not have to mentally convert meeting times. *(MVP)*
- As a host, I want to update my timezone in settings if I move or travel long-term, so that my availability always reflects the correct local time. *(MVP)*

**Invitee**
- As an invitee, I want the booking page to auto-detect my timezone, so that I see available slots in my local time without any configuration. *(MVP)*
- As an invitee, I want to manually override the detected timezone, so that I can book for a different timezone if I am traveling. *(MVP)*
- As an invitee, I want my confirmation email to show the meeting time in both my timezone and the host's timezone, so that I am confident we are both expecting the same call time. *(MVP)*

---

## Host Timezone

### Setting Host Timezone

During onboarding and in Profile & Settings, the host sets their local timezone.

**Timezone Selection:**
- Searchable dropdown with all IANA timezone identifiers
- Common timezones surfaced first (UTC, US/Eastern, US/Pacific, Europe/London, Asia/Kolkata, etc.)
- Search by city name (e.g., "Mumbai" → "Asia/Kolkata") or offset (e.g., "+5:30")
- Current local time preview updates as user selects: "Your current time: 3:45 PM IST"

**Where Host Timezone Is Used:**
- Availability schedule (Mon–Fri 9am–5pm is in host's timezone)
- Dashboard: all bookings shown in host's timezone
- Booking notification emails sent to host: show time in host's timezone
- Calendar invites for host: time written in host's timezone

### Changing Host Timezone
- Can be updated anytime in Profile & Settings
- On change: all future availability is recalculated
- Past bookings retain their original UTC timestamp (displayed converted to new timezone)
- Warning shown: "Changing your timezone will affect how your availability appears to invitees"

---

## Invitee Timezone

### Auto-Detection

When an invitee opens a booking page, Schduled automatically detects their timezone.

**Detection Method:**
- `Intl.DateTimeFormat().resolvedOptions().timeZone` — JavaScript browser API
- Returns IANA timezone string (e.g., `"Asia/Kolkata"`, `"America/New_York"`)
- Works on all modern browsers without any permission prompt
- Falls back to UTC if detection fails

**What Auto-Detection Changes:**
- All time slots on the booking page are shown in the detected timezone
- "Showing times in Asia/Kolkata (IST)" label appears on booking page
- Calendar invite and confirmation email show time in invitee's timezone

### Manual Timezone Selection

Invitees can manually change the timezone shown on the booking page.

**UI Element:**
- Timezone selector below the time slot grid
- Searchable dropdown (same as host setup)
- Changing timezone immediately recalculates all displayed slots
- Selection is ephemeral (not saved; next visit auto-detects again)

**Use Cases:**
- Invitee is booking on behalf of someone in a different timezone
- Auto-detection returned wrong timezone (e.g., VPN location mismatch)
- Invitee prefers seeing times in a different timezone for planning

---

## Timezone Conversion Logic

### How Conversion Works Internally

Availability windows are stored as `HH:mm` strings paired with the host's IANA timezone — **NOT as UTC ranges**. Individual generated slots are each converted to UTC at booking time.

For example, a host with `startTime = "09:00"`, `endTime = "17:00"`, `timezone = "America/New_York"` generates local slots 09:00–16:30 in their timezone, then converts each slot individually to UTC using `date-fns-tz.zonedTimeToUtc()` — on a non-DST day (EST, UTC-5) 09:00 becomes 14:00 UTC; on a DST transition day (EDT, UTC-4) it becomes 13:00 UTC. Calendar busy events are compared in UTC to filter occupied slots. The remaining UTC slots are then converted to the invitee's timezone for display — so an invitee in Asia/Kolkata (UTC+5:30) sees 14:00 UTC as 7:30 PM IST on the booking page.

> **Why NOT convert the window to a UTC range first:** On DST transition days, the local day is 23 or 25 hours long. A single-offset UTC range would generate slots that shift by 1 hour after the transition. Generating local slots first — then converting each slot individually — produces correct results for every day of the year.
>
> **Do not deviate from this approach.** Any shortcut that converts the availability window to a single UTC offset will produce wrong slot times on DST transition days. The per-slot `zonedTimeToUtc()` call is the correct and required implementation.

**Why HH:mm + IANA timezone storage:**
- DST changes are handled correctly (each slot converted with the correct offset for its exact date)
- Cross-timezone teams work without conversion bugs
- Database booking timestamps are always UTC (consistent ordering and comparisons)

### DST (Daylight Saving Time) Handling

Daylight Saving Time shifts clocks by 1 hour seasonally in many countries.

**Schduled's Approach:**
- All availability windows stored in IANA timezone (not offset like UTC-5)
- IANA timezones know when DST applies (America/New_York knows to shift in March/November)
- Slot display adjusts automatically as DST transitions occur
- Calendar invites include DST-aware timezone info (no manual recalculation needed)

**Example:**
- Host sets "Available 9am New York time"
- In winter (EST, UTC-5): invitee in London sees 2pm
- In summer (EDT, UTC-4): invitee in London sees 2pm still (both shifted by 1 hour)
- Schduled handles this silently — no host action required on DST change

---

## Booking Page Timezone Display

### Timezone Label
Shown clearly on the booking page so invitees know what timezone is being used:

> "Times shown in Asia/Kolkata (IST, UTC+5:30)"
> [Change timezone ↓]

### Time Format
- 12-hour or 24-hour based on locale
  - US locale: 12-hour by default (3:00 PM)
  - UK/EU/IN locale: 24-hour by default (15:00)
  - User can toggle in manual timezone selector

### Date Format
- US: MM/DD/YYYY
- UK/EU/IN: DD/MM/YYYY
- ISO: YYYY-MM-DD
- Inferred from browser locale; manual override in settings

---

## Dual Timezone Display in Confirmation Emails

Every email Schduled sends that references a meeting time shows **both the recipient's local time and the other party's local time**. This is a deliberate design decision that directly addresses a gap in Calendly and most scheduling tools.

### The Problem Schduled Solves

Calendly shows only the recipient's own timezone in confirmation and reminder emails. When the host and invitee are in different countries, one party always has to do mental timezone arithmetic — or they get confused about when the meeting actually is.

### How Schduled Shows Both Timezones

**Invitee confirmation email** (invitee is in India, host is in New York): the invitee sees their own meeting time (e.g., "Thursday, June 5 at 3:00 PM – 3:30 PM IST (Asia/Kolkata)") and the host's equivalent time (e.g., "Host's meeting time: Thursday, June 5 at 10:00 AM – 10:30 AM EST (America/New_York)") shown directly below it.

**Host notification email** (same meeting): the host sees their own meeting time (e.g., "Thursday, June 5 at 10:00 AM – 10:30 AM EST (America/New_York)") and the invitee's local time (e.g., "Invitee's local time: Thursday, June 5 at 3:00 PM – 3:30 PM IST (Asia/Kolkata)") shown directly below it.

This pattern is applied consistently in:
- Booking confirmation email
- Booking notification email
- 24-hour reminder email
- 1-hour reminder email
- Reschedule confirmation email
- Cancellation confirmation email
- ICS calendar invite description (plain text inside the event)

### Same Timezone Behaviour
When host and invitee are in the same timezone, only one time row is shown — no redundant duplication.

### Date Boundary Handling
If the host's time is Monday evening (e.g., 10 PM EST) and the invitee's converted time crosses midnight (e.g., 8:30 AM IST Tuesday), the correct date is shown for each party — not the same date for both. Emails are explicit: "Monday 10 PM for you / Tuesday 8:30 AM for your invitee."

---

## Calendar Invite Timezone

Calendar invites (ICS files and Google Calendar events) include timezone metadata.

### Google Calendar
- Event created with host's timezone
- Invitee's Google Calendar converts to their local timezone automatically
- Both parties see the correct local time in their calendars

### iCal / Apple Calendar
- ICS file includes `TZID` property with IANA timezone identifier
- Apple Calendar, Outlook, and all RFC 5545-compliant clients handle conversion

### Outlook
- Calendar event created with UTC time + timezone offset
- Outlook converts to user's configured timezone

---

## Team Timezone Handling

When a team has members across multiple timezones (common in remote teams):

### Round-Robin with Distributed Timezones
- Each team member's availability is stored in their own timezone
- Available slots shown to invitee are the union of all members' free times
- Assignment notification to each member shows time in their timezone

### Collective Events Across Timezones
- System finds slots when ALL members are free simultaneously
- Displayed to invitee in invitee's timezone
- Each host's calendar invite is in their own timezone

---

## Timezone Edge Cases

### Midnight Crossover
- If a host's availability includes evening hours, some slots may show on the "next day" for an invitee in an earlier timezone
- Example: Host available until 10pm PST → invitee in India sees 11:30am next day
- Schduled handles this correctly; shows correct date for the invitee

### International Date Line
- Extreme timezone differences (e.g., +12 and -12) may result in a 2-day gap in display
- Calendar shows correct date in both parties' locales

### Half-Hour and Quarter-Hour Timezones
- Support for non-full-hour offsets: IST (UTC+5:30), NPT (UTC+5:45), IST Australia (UTC+9:30)
- All IANA timezones supported, including historical offset changes

---

## Reference Implementations

| App | Timezone in Email | Both Timezones Shown? |
|-----|-----------------|----------------------|
| **Calendly** | Invitee sees their own timezone only; host sees their own timezone only | ❌ No — each party only sees their own time |
| **Cal.com** | Same as Calendly in default templates | ❌ No — only recipient's timezone |
| **SavvyCal** | Invitee's timezone displayed; calendar overlay shows mutual availability | Partial — booking page overlay helps but emails are single-timezone |
| **Chili Piper** | Host timezone; Salesforce timezone fields used for routing | ❌ No |
| **HubSpot Meetings** | Auto-detect invitee timezone; Google Calendar handles DST | ❌ No |
| **Schduled** | Every email shows recipient's time **and** the other party's local time | ✅ Yes — both parties always know exactly what time the meeting is for the other person |

---

## MVP Scope

**In MVP:**
- Host timezone setting (onboarding + profile settings)
- Invitee timezone auto-detection (browser API)
- Manual timezone selector for invitees on booking page
- Timezone label shown on booking page ("Times shown in X")
- **Dual timezone in all emails** — every notification shows recipient's time AND the other party's time
- `{host_time}`, `{host_timezone}`, `{invitee_time}`, `{invitee_timezone}` dynamic variables available in all email templates
- Calendar invites with correct TZID metadata (invitee's timezone in ICS; host's timezone in calendar event)
- ICS description includes both times as plain text
- Same-timezone deduplication (only one time shown when both parties share a timezone)
- Date boundary handling (correct date shown when crossing midnight)
- DST-aware slot calculation (IANA timezone storage)
- 12/24-hour format based on locale

**Post-MVP:**
- Team timezone conflict visualization
- User preference to lock to specific format (12hr/24hr)
- Timezone suggestion based on country (IP-based fallback if JS detection fails)


---

## Background Jobs

No background jobs are directly triggered by timezone reads or display. The timezone conversion logic runs synchronously in the slot generation path.

The one indirect job dependency: slot generation reads `calendar_events_cache`, which is kept current by the `CALENDAR_SYNC` pg-boss cron job (every 5 minutes per connected calendar). Timezone conversion is applied during slot generation — not inside the job itself. See `calendar-integrations.md` for the `CALENDAR_SYNC` job details.

---

## Audit Logging

Timezone changes are not a separate audit action — they are logged as part of the host's profile save:

| Action | When | source | Data Logged |
|--------|------|--------|-------------|
| `user.timezone_changed` | Host updates timezone in Profile & Settings | `'web'` | oldTimezone (IANA string), newTimezone (IANA string) |

This audit record is written inside the same DB transaction as the profile update by the user-profile-settings Server Action. See `user-profile-settings.md` for the full audit record definition and `database-schema.md` for `auditSourceEnum`.

---

## Tech Stack

- **date-fns-tz** — the core library for all timezone conversions. Converts host availability windows (defined in their local IANA timezone) to UTC for storage, and converts UTC booking times back to any display timezone. Uses IANA timezone names (e.g., `"Asia/Kolkata"`) rather than raw UTC offsets, so DST transitions are handled automatically without any manual logic.
- **PostgreSQL + Drizzle ORM** — all booking and availability timestamps stored as plain UTC. The host's IANA timezone and the invitee's IANA timezone are stored as separate text columns alongside each timestamp, so any timestamp can be correctly displayed in either party's local time at any point in the future.
- **ical-generator** — when generating `.ics` calendar invite files, the library embeds the `TZID` property so Apple Calendar, Outlook, and Google Calendar each display the event in the recipient's own local time automatically.
- **Next.js (browser Intl API)** — the invitee's timezone is detected client-side using `Intl.DateTimeFormat().resolvedOptions().timeZone`. This value is passed to the server when fetching available slots so time display is correct from the first render.
