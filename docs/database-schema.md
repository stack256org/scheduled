# Schduled — Database Schema

**One schema file per domain**, all files in `db/schema/`, re-exported from a single `index.ts`. All enums live in a shared `enums.ts`. All Drizzle relations live in `relations.ts` to avoid circular imports.

---

## File Structure

```
src/lib/db/
├── schema/
│   ├── enums.ts           ← ALL pgEnum definitions (shared — imported by every domain file)
│   ├── auth.ts            ← users, sessions, accounts, verifications
│   ├── profile.ts         ← user_profiles, user_branding, username_redirects
│   ├── event-types.ts     ← event_types, event_type_durations, cancellation_policies, event_type_questions
│   ├── availability.ts    ← availability_schedules, availability_windows, availability_overrides
│   ├── calendars.ts       ← connected_calendars, calendar_events_cache
│   ├── video.ts           ← video_connections
│   ├── bookings.ts        ← bookings, booking_answers, booking_guests
│   ├── notifications.ts   ← notification_preferences, workflow_jobs
│   ├── audit.ts           ← audit_logs
│   ├── email.ts           ← email_outbox, email_events
│   ├── platform.ts        ← idempotency_keys (platform settings → env vars; disposable emails → static JSON)
│   ├── relations.ts       ← ALL Drizzle relations (avoids circular imports)
│   └── index.ts           ← re-exports everything
├── index.ts               ← Drizzle client (imports schema from schema/index.ts)
├── users.ts               ← DbUsers query helpers
├── event-types.ts         ← DbEventTypes query helpers
├── availability.ts        ← DbAvailability query helpers
├── bookings.ts            ← DbBookings query helpers
├── calendars.ts           ← DbCalendars query helpers
├── video.ts               ← DbVideo query helpers
├── notifications.ts       ← DbNotifications query helpers
├── audit.ts               ← DbAudit query helpers
├── email.ts               ← DbEmail query helpers
└── settings.ts            ← DbSettings query helpers
```

---

## `src/lib/db/schema/enums.ts`

All PostgreSQL enums in one place. Import from here in every domain schema file.

```typescript
import { pgEnum } from 'drizzle-orm/pg-core'

// ── User & Auth ──────────────────────────────────────────────────────────────

export const themeEnum = pgEnum('theme', ['light', 'dark', 'system'])

export const dateFormatEnum = pgEnum('date_format', [
  'MM/DD/YYYY',
  'DD/MM/YYYY',
  'YYYY-MM-DD',
])

export const timeFormatEnum = pgEnum('time_format', ['12h', '24h'])

// ── Scheduling ───────────────────────────────────────────────────────────────

export const locationTypeEnum = pgEnum('location_type', [
  'zoom',
  'google_meet',
  'teams',               // Phase 2
  'phone_host_calls',    // host calls the invitee
  'phone_invitee_calls', // invitee calls the host
  'in_person',
  'custom',
  'invitees_choice',
])

export const questionTypeEnum = pgEnum('question_type', [
  'short_text',
  'long_text',
  'phone',
  'single_select',
  'dropdown',
  'multiple_select', // Phase 2
  'number',          // Phase 2
  'date',            // Phase 2
  'url',             // Phase 2
])

export const dayOfWeekEnum = pgEnum('day_of_week', [
  'monday', 'tuesday', 'wednesday', 'thursday',
  'friday', 'saturday', 'sunday',
])

export const bookingWindowTypeEnum = pgEnum('booking_window_type', [
  'rolling', // "next 60 days"
  'fixed',   // "Jun 1 – Aug 31"
])

export const bookingStatusEnum = pgEnum('booking_status', [
  'confirmed',
  'cancelled',
  'rescheduled', // old booking after reschedule; new booking linked via rescheduledFromId
  'completed',   // meeting time passed, not cancelled
  'no_show',     // Phase 2 auto-detect; manual marking at MVP
])

// ── Calendars & Video ────────────────────────────────────────────────────────

export const calendarProviderEnum = pgEnum('calendar_provider', [
  'google',
  'outlook',
  'apple',  // Phase 2 — CalDAV / iCloud
  'caldav', // Phase 2 — generic CalDAV
])

export const calendarStatusEnum = pgEnum('calendar_status', [
  'connected',
  'disconnected', // token refresh failed; booking pages disabled; host alert email sent
])

export const videoProviderEnum = pgEnum('video_provider', [
  'zoom',
  'teams', // Phase 2
])

// ── Jobs & Notifications ─────────────────────────────────────────────────────

// jobType is stored as text — it holds the actual pg-boss job name (e.g. 'BOOKING_REMINDER_24H').
// A Drizzle/Postgres enum would require a migration every time a job is added or renamed;
// plain text keeps workflow_jobs in sync with the job-types.ts constants without schema churn.

export const jobStatusEnum = pgEnum('job_status', [
  'pending',
  'running',
  'completed',
  'failed',
  'cancelled',
])

// ── Email ────────────────────────────────────────────────────────────────────

export const emailOutboxStatusEnum = pgEnum('email_outbox_status', [
  'queued',   // inserted; not yet claimed by worker
  'sending',  // worker has claimed this row and is attempting delivery
  'sent',     // accepted by SMTP server
  'failed',   // all retries exhausted
])

export const emailEventTypeEnum = pgEnum('email_event_type', [
  'delivered', // SMTP confirmed delivery
  'bounced',   // hard bounce
  'failed',    // SMTP permanent failure
])

// ── Audit ────────────────────────────────────────────────────────────────────

export const auditSourceEnum = pgEnum('audit_source', [
  'web',    // triggered from dashboard / booking page UI
  'api',    // triggered from /api route
  'worker', // triggered from pg-boss job handler
  'system', // internal automation (cron, seeder)
])

export const auditActionEnum = pgEnum('audit_action', [
  // Auth
  'user.signup',
  'user.signin',
  'user.signout',
  'user.password_reset',
  // Admin actions on users
  'user.ban',
  'user.unban',
  'user.impersonate_start',
  'user.impersonate_stop',
  'user.revoke_sessions',
  // Profile
  'user.profile_updated',
  'user.timezone_changed',
  'user.username_changed',
  'user.photo_updated',
  'user.password_changed',
  'user.email_change_requested',  // new email submitted; verification pending
  'user.account_deleted',
  // Branding
  'user.branding_updated',        // logo, color, confirmation message, or any branding field
  // Bookings
  'booking.created',
  'booking.cancelled_by_invitee',
  'booking.cancelled_by_host',
  'booking.rescheduled',
  // Event types
  'event_type.created',
  'event_type.updated',
  'event_type.deleted',
  'event_type.activated',
  'event_type.deactivated',
  // Availability
  'availability.schedule_updated',   // weekly hours or schedule name changed
  'availability.override_added',     // date blocked or hours overridden for a specific date
  'availability.override_removed',   // date override removed
  'availability.schedule_assigned',  // different named schedule assigned to an event type
  // Calendars
  'calendar.connected',
  'calendar.disconnected',
  // Platform
  // platform_settings removed — settings are now env vars (no admin-level DB audit needed)
])
```

---

## `src/lib/db/schema/auth.ts`

Better Auth tables. Better Auth manages these columns and expects exact names.
**Important:** Use `role: text` (not `isPlatformAdmin: boolean`) — Better Auth's admin plugin reads the `role` field to identify admins.

```typescript
import { pgTable, text, boolean, timestamp } from 'drizzle-orm/pg-core'
import { index } from 'drizzle-orm/pg-core'

// Better Auth base user table.
// Do NOT rename columns — Better Auth expects these exact names.
// Custom Schduled fields (username, timezone, etc.) are additive extras.
export const users = pgTable('users', {
  // Better Auth required fields
  id:            text('id').primaryKey(),
  name:          text('name').notNull(),
  email:         text('email').notNull().unique(),
  emailVerified: boolean('email_verified').notNull().default(false),
  image:         text('image'),                         // profile photo URL (S3 public URL)
  createdAt:     timestamp('created_at').notNull().defaultNow(),
  updatedAt:     timestamp('updated_at').notNull().defaultNow(),

  // Better Auth admin plugin — MUST be text 'role', not isPlatformAdmin boolean
  // Set to 'admin' for platform administrators
  role: text('role'),

  // Better Auth ban fields
  banned:     boolean('banned').notNull().default(false),
  banReason:  text('ban_reason'),
  banExpires: timestamp('ban_expires'),

  // Schduled custom fields
  username:       text('username').unique(),          // booking URL: schduled.com/username
  timezone:       text('timezone').default('UTC'),    // IANA timezone
  onboardingStep: integer('onboarding_step').default(0), // 0–5; 5 = complete
  onboardingDone: boolean('onboarding_done').notNull().default(false),
}, (t) => [
  index('users_email_idx').on(t.email),
  index('users_username_idx').on(t.username),
])

// Better Auth session table — exact column names required
export const sessions = pgTable('sessions', {
  id:             text('id').primaryKey(),
  userId:         text('user_id').notNull().references(() => users.id, { onDelete: 'cascade' }),
  token:          text('token').notNull().unique(),
  expiresAt:      timestamp('expires_at').notNull(),
  ipAddress:      text('ip_address'),
  userAgent:      text('user_agent'),
  impersonatedBy: text('impersonated_by'),             // admin user ID if this is an impersonation session
  createdAt:      timestamp('created_at').notNull().defaultNow(),
  updatedAt:      timestamp('updated_at').notNull().defaultNow(),
})

// Better Auth OAuth account table
export const accounts = pgTable('accounts', {
  id:                    text('id').primaryKey(),
  userId:                text('user_id').notNull().references(() => users.id, { onDelete: 'cascade' }),
  accountId:             text('account_id').notNull(),
  providerId:            text('provider_id').notNull(), // 'google' | 'credential' | 'magic-link'
  accessToken:           text('access_token'),
  refreshToken:          text('refresh_token'),
  accessTokenExpiresAt:  timestamp('access_token_expires_at'),
  refreshTokenExpiresAt: timestamp('refresh_token_expires_at'),
  scope:                 text('scope'),
  idToken:               text('id_token'),
  createdAt:             timestamp('created_at').notNull().defaultNow(),
  updatedAt:             timestamp('updated_at').notNull().defaultNow(),
})

// Better Auth email/magic-link verification table
export const verifications = pgTable('verifications', {
  id:         text('id').primaryKey(),
  identifier: text('identifier').notNull(), // email being verified
  value:      text('value').notNull(),      // verification token or code
  expiresAt:  timestamp('expires_at').notNull(),
  createdAt:  timestamp('created_at').defaultNow(),
  updatedAt:  timestamp('updated_at').defaultNow(),
})
```

---

## `src/lib/db/schema/profile.ts`

Extended user profile data. Separate from the auth table so Better Auth schema doesn't need to know about Schduled-specific fields.

```typescript
import { pgTable, text, timestamp, index } from 'drizzle-orm/pg-core'
import { users } from './auth'
import { themeEnum, dateFormatEnum, timeFormatEnum } from './enums'

// Extended profile fields — one row per user (1:1)
export const userProfiles = pgTable('user_profiles', {
  id:          text('id').primaryKey(),
  userId:      text('user_id').notNull().unique().references(() => users.id, { onDelete: 'cascade' }),
  displayName: text('display_name'),           // shorter name shown on booking page
  jobTitle:    text('job_title'),
  company:     text('company'),
  bio:         text('bio'),                    // Phase 2 — up to 200 chars
  websiteUrl:  text('website_url'),            // Phase 2
  theme:       themeEnum('theme').default('system'),
  dateFormat:  dateFormatEnum('date_format').default('MM/DD/YYYY'),
  timeFormat:  timeFormatEnum('time_format').default('12h'),
  updatedAt:   timestamp('updated_at').notNull().defaultNow(),
})

// Booking page branding — one row per user (1:1)
export const userBranding = pgTable('user_branding', {
  id:                  text('id').primaryKey(),
  userId:              text('user_id').notNull().unique().references(() => users.id, { onDelete: 'cascade' }),
  brandPrimaryColor:   text('brand_primary_color').default('#0070f3'),
  brandTextColor:      text('brand_text_color').default('#ffffff'),
  logoUrl:             text('logo_url'),              // S3 key
  welcomeMessage:      text('welcome_message'),
  confirmationMessage: text('confirmation_message'),  // shown after booking + in email
  updatedAt:           timestamp('updated_at').notNull().defaultNow(),
})

// When user changes their username, old URL redirects to new URL for 30 days.
// Without this, any old booking link in an email or signature would 404 immediately.
export const usernameRedirects = pgTable('username_redirects', {
  id:          text('id').primaryKey(),
  userId:      text('user_id').notNull().references(() => users.id, { onDelete: 'cascade' }),
  oldUsername: text('old_username').notNull(),
  newUsername: text('new_username').notNull(),
  expiresAt:   timestamp('expires_at').notNull(), // 30 days from change
  createdAt:   timestamp('created_at').notNull().defaultNow(),
}, (t) => [
  index('username_redirects_old_idx').on(t.oldUsername),
])
```

---

## `src/lib/db/schema/event-types.ts`

Meeting type templates: all settings, durations, questions, and cancellation policies.

```typescript
import { pgTable, text, boolean, integer, jsonb, timestamp, index } from 'drizzle-orm/pg-core'
import { users } from './auth'
import { locationTypeEnum, questionTypeEnum, bookingWindowTypeEnum } from './enums'

export const eventTypes = pgTable('event_types', {
  id:                   text('id').primaryKey(),
  userId:               text('user_id').notNull().references(() => users.id, { onDelete: 'cascade' }),
  availabilityScheduleId: text('availability_schedule_id'), // FK set in availability.ts; lazy ref
  name:                 text('name').notNull(),
  slug:                 text('slug').notNull(),              // unique per user; forms booking URL path
  description:          text('description'),
  locationType:         locationTypeEnum('location_type').notNull().default('zoom'),
  locationValue:        text('location_value'),              // video URL, address, phone number, etc.
  hostPhoneNumber:      text('host_phone_number'),           // shown to invitee when locationType=phone AND phoneCallDirection=invitee_calls_host
  color:                text('color').default('#0070f3'),
  isActive:             boolean('is_active').notNull().default(true),
  isHidden:             boolean('is_hidden').notNull().default(false), // bookable via direct link only
  position:             integer('position').default(0),      // drag-and-drop order on profile page
  minimumNotice:        integer('minimum_notice').default(60),     // minutes before a slot can be booked
  bookingWindow:        integer('booking_window').default(60),     // days ahead available
  bookingWindowType:    bookingWindowTypeEnum('booking_window_type').default('rolling'),
  bufferBefore:         integer('buffer_before').default(0),       // minutes
  bufferAfter:          integer('buffer_after').default(0),        // minutes
  maxBookingsPerDay:    integer('max_bookings_per_day'),            // null = no limit
  startTimeIncrement:   integer('start_time_increment').default(30), // slot interval (min)
  requiresApproval:     boolean('requires_approval').notNull().default(false),
  createdAt:            timestamp('created_at').notNull().defaultNow(),
  updatedAt:            timestamp('updated_at').notNull().defaultNow(),
}, (t) => [
  index('event_types_user_slug_idx').on(t.userId, t.slug),
  index('event_types_user_active_idx').on(t.userId, t.isActive),
])

// Multiple durations per event type — e.g. "30 min / 60 min" on the same link
export const eventTypeDurations = pgTable('event_type_durations', {
  id:          text('id').primaryKey(),
  eventTypeId: text('event_type_id').notNull().references(() => eventTypes.id, { onDelete: 'cascade' }),
  duration:    integer('duration').notNull(), // minutes
  isDefault:   boolean('is_default').notNull().default(false),
})

// Cancellation & reschedule rules per event type (1:1)
export const cancellationPolicies = pgTable('cancellation_policies', {
  id:                          text('id').primaryKey(),
  eventTypeId:                 text('event_type_id').notNull().unique().references(() => eventTypes.id, { onDelete: 'cascade' }),
  allowCancellation:           boolean('allow_cancellation').notNull().default(true),
  cutoffHours:                 integer('cutoff_hours').default(0),           // 0 = always allowed
  allowRescheduling:           boolean('allow_rescheduling').notNull().default(true),
  rescheduleCutoffHours:       integer('reschedule_cutoff_hours').default(0),
  maxReschedules:              integer('max_reschedules'),                    // null = unlimited
  requireCancellationReason:   boolean('require_cancellation_reason').notNull().default(false),
  cancellationReasonOptions:   jsonb('cancellation_reason_options').$type<string[]>(), // typed JSONB
  showPolicyText:              boolean('show_policy_text').notNull().default(true),
  policyText:                  text('policy_text'),
  createdAt:                   timestamp('created_at').notNull().defaultNow(),
})

// Intake form questions shown to invitees at booking time
export const eventTypeQuestions = pgTable('event_type_questions', {
  id:          text('id').primaryKey(),
  eventTypeId: text('event_type_id').notNull().references(() => eventTypes.id, { onDelete: 'cascade' }),
  label:       text('label').notNull(),
  type:        questionTypeEnum('type').notNull(),
  isRequired:  boolean('is_required').notNull().default(false),
  options:     jsonb('options').$type<string[]>(),  // typed JSONB — for single_select, dropdown, multiple_select
  placeholder: text('placeholder'),
  position:    integer('position').notNull().default(0),
  isActive:    boolean('is_active').notNull().default(true),
})
```

---

## `src/lib/db/schema/availability.ts`

Weekly schedule, time windows, and date-specific overrides.

```typescript
import { pgTable, text, boolean, timestamp, index } from 'drizzle-orm/pg-core'
import { users } from './auth'
import { dayOfWeekEnum } from './enums'

// One global schedule per user at MVP. Multiple named schedules → Phase 2.
export const availabilitySchedules = pgTable('availability_schedules', {
  id:        text('id').primaryKey(),
  userId:    text('user_id').notNull().references(() => users.id, { onDelete: 'cascade' }),
  name:      text('name').notNull().default('Working Hours'),
  isDefault: boolean('is_default').notNull().default(true),
  // Stored separately from user timezone — schedule can differ (e.g. user travels but schedule stays)
  timezone:  text('timezone').notNull(),
  createdAt: timestamp('created_at').notNull().defaultNow(),
})

// Each row = one time block on a given day.
// Multiple rows per day = split schedule (e.g. Mon 9–12, Mon 14–17).
// Times stored as "HH:mm" strings in the SCHEDULE's timezone — NOT UTC.
// Converted to UTC at slot generation time, per-slot, to handle DST correctly.
export const availabilityWindows = pgTable('availability_windows', {
  id:         text('id').primaryKey(),
  scheduleId: text('schedule_id').notNull().references(() => availabilitySchedules.id, { onDelete: 'cascade' }),
  dayOfWeek:  dayOfWeekEnum('day_of_week').notNull(),
  startTime:  text('start_time').notNull(), // "09:00"
  endTime:    text('end_time').notNull(),   // "17:00"
})

// Date-specific: block a day entirely or define custom hours for one specific date
export const availabilityOverrides = pgTable('availability_overrides', {
  id:        text('id').primaryKey(),
  userId:    text('user_id').notNull().references(() => users.id, { onDelete: 'cascade' }),
  date:      text('date').notNull(),              // "YYYY-MM-DD"
  isBlocked: boolean('is_blocked').notNull().default(true),
  startTime: text('start_time'),                  // if not blocked: custom start time "HH:mm"
  endTime:   text('end_time'),                    // if not blocked: custom end time "HH:mm"
  reason:    text('reason'),
  createdAt: timestamp('created_at').notNull().defaultNow(),
}, (t) => [
  index('availability_overrides_user_date_idx').on(t.userId, t.date),
])
```

---

## `src/lib/db/schema/calendars.ts`

Connected calendar OAuth tokens and the 5-minute free/busy event cache.

```typescript
import { pgTable, text, boolean, timestamp, index } from 'drizzle-orm/pg-core'
import { users } from './auth'
import { calendarProviderEnum, calendarStatusEnum } from './enums'

// OAuth tokens for connected calendars.
// accessToken and refreshToken are stored AES-256-GCM encrypted (see src/lib/encrypt.ts).
export const connectedCalendars = pgTable('connected_calendars', {
  id:               text('id').primaryKey(),
  userId:           text('user_id').notNull().references(() => users.id, { onDelete: 'cascade' }),
  provider:         calendarProviderEnum('provider').notNull(),
  accountEmail:     text('account_email').notNull(),
  accessToken:      text('access_token'),           // AES-256-GCM encrypted
  refreshToken:     text('refresh_token'),          // AES-256-GCM encrypted
  tokenExpiresAt:   timestamp('token_expires_at'),
  status:           calendarStatusEnum('status').notNull().default('connected'),
  disconnectedAt:   timestamp('disconnected_at'),   // set when token refresh fails permanently
  calendarId:       text('calendar_id'),            // provider-specific calendar ID
  calendarName:     text('calendar_name'),
  isPrimary:        boolean('is_primary').notNull().default(false),
  isConflictCheck:  boolean('is_conflict_check').notNull().default(true),  // block slots from this calendar
  isWriteTarget:    boolean('is_write_target').notNull().default(false),   // write new bookings here
  createdAt:        timestamp('created_at').notNull().defaultNow(),
}, (t) => [
  index('connected_calendars_user_provider_idx').on(t.userId, t.provider),
  index('connected_calendars_status_idx').on(t.status),
  // Enforce at most one write target per user — partial unique index (only rows where is_write_target = true are indexed)
  uniqueIndex('connected_calendars_one_write_target_per_user').on(t.userId).where(sql`is_write_target = true`),
])

// 5-minute TTL cache of external calendar events for free/busy lookups.
// CALENDAR_SYNC cron (every 5 min) refreshes this via Google/Outlook API.
// Booking pages read from cache — no live API call at page load time.
// Final conflict check re-reads live data inside the booking DB transaction.
export const calendarEventsCache = pgTable('calendar_events_cache', {
  id:                  text('id').primaryKey(),
  connectedCalendarId: text('connected_calendar_id').notNull().references(() => connectedCalendars.id, { onDelete: 'cascade' }),
  externalEventId:     text('external_event_id').notNull(),
  startTime:           timestamp('start_time').notNull(), // UTC
  endTime:             timestamp('end_time').notNull(),   // UTC
  isBusy:              boolean('is_busy').notNull().default(true),
  syncedAt:            timestamp('synced_at').notNull().defaultNow(),
}, (t) => [
  index('calendar_events_cache_cal_time_idx').on(t.connectedCalendarId, t.startTime, t.endTime),
])
```

---

## `src/lib/db/schema/video.ts`

Zoom (and Phase 2: Teams) OAuth tokens.

```typescript
import { pgTable, text, timestamp } from 'drizzle-orm/pg-core'
import { users } from './auth'
import { videoProviderEnum } from './enums'

// Google Meet does NOT need a row here — its token is in connected_calendars.
// Only Zoom (MVP) and Teams (Phase 2) use this table.
// accessToken and refreshToken are stored AES-256-GCM encrypted.
export const videoConnections = pgTable('video_connections', {
  id:             text('id').primaryKey(),
  userId:         text('user_id').notNull().references(() => users.id, { onDelete: 'cascade' }),
  provider:       videoProviderEnum('provider').notNull(),
  accountEmail:   text('account_email'),
  accessToken:    text('access_token').notNull(),    // AES-256-GCM encrypted
  refreshToken:   text('refresh_token'),             // AES-256-GCM encrypted
  tokenExpiresAt: timestamp('token_expires_at'),
  providerUserId: text('provider_user_id'),          // Zoom user ID, Teams object ID
  createdAt:      timestamp('created_at').notNull().defaultNow(),
})
```

---

## `src/lib/db/schema/bookings.ts`

All booking records, invitee answers, and additional guests.

```typescript
import { pgTable, text, boolean, integer, timestamp, index } from 'drizzle-orm/pg-core'
import { users } from './auth'
import { eventTypes } from './event-types'
import { eventTypeQuestions } from './event-types'
import { bookingStatusEnum } from './enums'

export const bookings = pgTable('bookings', {
  id:          text('id').primaryKey(),
  eventTypeId: text('event_type_id').notNull().references(() => eventTypes.id),
  hostUserId:  text('host_user_id').notNull().references(() => users.id),

  // Invitee details — denormalized. Invitees have no Schduled account.
  inviteeName:     text('invitee_name').notNull(),
  inviteeEmail:    text('invitee_email').notNull(),
  inviteePhone:    text('invitee_phone'),              // collected when locationType = phone
  inviteeTimezone: text('invitee_timezone').notNull(), // IANA — for dual-timezone emails

  // Meeting time — always stored as UTC
  startTime: timestamp('start_time', { withTimezone: true }).notNull(),
  endTime:   timestamp('end_time', { withTimezone: true }).notNull(),
  duration:  integer('duration').notNull(), // minutes — denormalized for display

  // Location — final resolved value
  locationValue:    text('location_value'),     // video join URL, address, or phone number
  videoLinkHost:    text('video_link_host'),    // host's moderator/start URL (Zoom start URL)
  videoLinkInvitee: text('video_link_invitee'), // invitee's join URL

  status: bookingStatusEnum('status').notNull().default('confirmed'),

  // Cancellation & reschedule tokens — crypto.randomUUID(), single-use, in confirmation emails
  cancelToken:             text('cancel_token').notNull().unique(),
  rescheduleToken:         text('reschedule_token').notNull().unique(),
  cancelTokenExpiresAt:    timestamp('cancel_token_expires_at', { withTimezone: true }),    // set to createdAt + 30 days; null if already used
  rescheduleTokenExpiresAt: timestamp('reschedule_token_expires_at', { withTimezone: true }), // set to createdAt + 30 days; null if already used
  cancellationReason:  text('cancellation_reason'),
  cancelledBy:         text('cancelled_by'),          // 'host' | 'invitee'
  cancelledAt:         timestamp('cancelled_at', { withTimezone: true }),
  rescheduledFromId:   text('rescheduled_from_id'),   // previous booking ID when rescheduled
  rescheduleCount:     integer('reschedule_count').notNull().default(0), // checked against cancellation_policies.maxReschedules

  // Host private notes (Phase 2 — visible only in dashboard)
  hostNotes: text('host_notes'),

  createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
  updatedAt: timestamp('updated_at', { withTimezone: true }).notNull().defaultNow(),
}, (t) => [
  index('bookings_host_start_time_idx').on(t.hostUserId, t.startTime),
  index('bookings_host_status_idx').on(t.hostUserId, t.status),
  index('bookings_invitee_email_idx').on(t.inviteeEmail),
  index('bookings_cancel_token_idx').on(t.cancelToken),
  index('bookings_reschedule_token_idx').on(t.rescheduleToken),
])

// Invitee's answers to intake form questions.
// questionLabel is denormalized — answers remain readable if the question label is later edited.
export const bookingAnswers = pgTable('booking_answers', {
  id:            text('id').primaryKey(),
  bookingId:     text('booking_id').notNull().references(() => bookings.id, { onDelete: 'cascade' }),
  questionId:    text('question_id').references(() => eventTypeQuestions.id, { onDelete: 'set null' }),
  questionLabel: text('question_label').notNull(), // label at time of booking — immutable snapshot
  answer:        text('answer').notNull(),
})

// Additional attendees added by the invitee (up to 10 per booking).
// Each guest receives all confirmation, reminder, and follow-up emails.
export const bookingGuests = pgTable('booking_guests', {
  id:          text('id').primaryKey(),
  bookingId:   text('booking_id').notNull().references(() => bookings.id, { onDelete: 'cascade' }),
  guestEmail:  text('guest_email').notNull(),
  guestName:   text('guest_name'),
})
```

---

## `src/lib/db/schema/notifications.ts`

Per-user email notification preferences and the pg-boss job tracker.

```typescript
import { pgTable, text, boolean, integer, timestamp, index } from 'drizzle-orm/pg-core'
import { users } from './auth'
import { bookings } from './bookings'
import { jobStatusEnum } from './enums'

// One row per user — which email notifications they want to receive
export const notificationPreferences = pgTable('notification_preferences', {
  id:                       text('id').primaryKey(),
  userId:                   text('user_id').notNull().unique().references(() => users.id, { onDelete: 'cascade' }),
  bookingConfirmationEmail: boolean('booking_confirmation_email').notNull().default(true),
  bookingNotificationEmail: boolean('booking_notification_email').notNull().default(true),
  reminderEmail24h:         boolean('reminder_email_24h').notNull().default(true),
  reminderEmail1h:          boolean('reminder_email_1h').notNull().default(true),
  cancellationEmail:        boolean('cancellation_email').notNull().default(true),
  rescheduleEmail:          boolean('reschedule_email').notNull().default(true),
  fromName:                 text('from_name'),       // sender name override; default: user's full name
  replyToEmail:             text('reply_to_email'),  // reply-to override; default: user's email
  updatedAt:                timestamp('updated_at').notNull().defaultNow(),
})

// Tracks pg-boss background jobs per booking.
// singletonKey format: "{bookingId}_{jobType}"
// Allows cancelling one specific job type for one specific booking (e.g. reminder_24h only)
// without touching other bookings' jobs.
export const workflowJobs = pgTable('workflow_jobs', {
  id:            text('id').primaryKey(),
  bookingId:     text('booking_id').notNull().references(() => bookings.id, { onDelete: 'cascade' }),
  jobType:       text('job_type').notNull(),        // pg-boss job name: 'BOOKING_REMINDER_24H', 'EMAIL_SEND', etc.
  singletonKey:  text('singleton_key').notNull(),  // "{bookingId}_{jobType}"
  scheduledFor:  timestamp('scheduled_for', { withTimezone: true }), // null = immediate; set for reminder jobs
  status:        jobStatusEnum('status').notNull().default('pending'),
  completedAt:   timestamp('completed_at', { withTimezone: true }),
  failureReason: text('failure_reason'),
  retryCount:    integer('retry_count').notNull().default(0),
  createdAt:     timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
}, (t) => [
  index('workflow_jobs_booking_idx').on(t.bookingId),
  index('workflow_jobs_singleton_key_idx').on(t.singletonKey),
  index('workflow_jobs_status_idx').on(t.status),
])
```

---

## `src/lib/db/schema/audit.ts`

Immutable record of every significant platform mutation.

```typescript
import { pgTable, text, jsonb, timestamp, index } from 'drizzle-orm/pg-core'
import { users } from './auth'
import { auditActionEnum, auditSourceEnum } from './enums'

export const auditLogs = pgTable('audit_logs', {
  id: text('id').primaryKey(),

  // Actor — who performed the action
  // actorUserId is nullable: set null if user is deleted (record survives user deletion)
  actorUserId: text('actor_user_id').references(() => users.id, { onDelete: 'set null' }),
  // actorEmail is DENORMALIZED — written at log time. Never join to users table.
  // Reason: user may be deleted; actorEmail must remain readable in the audit log forever.
  actorEmail:  text('actor_email'),

  action:     auditActionEnum('action').notNull(),
  targetType: text('target_type'),  // 'user' | 'booking' | 'event_type' | 'platform'
  targetId:   text('target_id'),    // ID of the affected entity

  // Request context
  ipAddress: text('ip_address'),
  userAgent: text('user_agent'),

  // source tells you where the mutation came from
  source: auditSourceEnum('source').notNull().default('web'),

  // State snapshots — typed JSONB
  before: jsonb('before').$type<Record<string, unknown>>(), // state before mutation
  after:  jsonb('after').$type<Record<string, unknown>>(),  // state after mutation

  // Audit logs are IMMUTABLE — no updatedAt column. Never UPDATE or DELETE audit rows.
  createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
}, (t) => [
  index('audit_logs_actor_idx').on(t.actorUserId),
  index('audit_logs_action_idx').on(t.action),
  index('audit_logs_target_idx').on(t.targetType, t.targetId),
  index('audit_logs_created_at_idx').on(t.createdAt),
])
```

---

## `src/lib/db/schema/email.ts`

Async email queue (outbox pattern) and per-email delivery event tracking.

```typescript
import { pgTable, text, integer, jsonb, timestamp, index } from 'drizzle-orm/pg-core'
import { users } from './auth'
import { bookings } from './bookings'
import { emailOutboxStatusEnum, emailEventTypeEnum } from './enums'

export const emailOutbox = pgTable('email_outbox', {
  id: text('id').primaryKey(),

  // idempotencyKey: random UUID generated at INSERT time.
  // Passed to SMTP provider as a deduplication key.
  // If the worker crashes and retries, the provider's 24h dedup window prevents double-send.
  idempotencyKey: text('idempotency_key').notNull().unique(),

  toEmail:      text('to_email').notNull(),
  toName:       text('to_name'),
  subject:      text('subject').notNull(),
  template:     text('template').notNull(),                        // React Email template name
  templateData: jsonb('template_data').$type<Record<string, unknown>>().notNull(),
  fromName:     text('from_name').notNull().default('Schduled'),
  replyToEmail: text('reply_to_email'),

  // State machine: queued → sending → sent | failed
  // The row state (not pg-boss retry count) is the source of truth for delivery status.
  status: emailOutboxStatusEnum('status').notNull().default('queued'),

  attempts:      integer('attempts').notNull().default(0),
  lastAttemptAt: timestamp('last_attempt_at', { withTimezone: true }),
  sentAt:        timestamp('sent_at', { withTimezone: true }),
  errorMessage:  text('error_message'),          // last error from SMTP provider

  // Optional links back to source entity (set null on delete — email history is preserved)
  bookingId: text('booking_id').references(() => bookings.id, { onDelete: 'set null' }),
  userId:    text('user_id').references(() => users.id, { onDelete: 'set null' }),

  createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
}, (t) => [
  index('email_outbox_status_idx').on(t.status),
  index('email_outbox_status_claimed_idx').on(t.status, t.lastAttemptAt), // for stuck-row reaper
  index('email_outbox_user_idx').on(t.userId),
  index('email_outbox_created_at_idx').on(t.createdAt),
])

// SMTP delivery event tracking per email.
// Written by the EMAIL_SEND job handler after each delivery attempt.
export const emailEvents = pgTable('email_events', {
  id:             text('id').primaryKey(),
  emailOutboxId:  text('email_outbox_id').references(() => emailOutbox.id, { onDelete: 'cascade' }),
  eventType:      emailEventTypeEnum('event_type').notNull(),
  occurredAt:     timestamp('occurred_at', { withTimezone: true }).notNull().defaultNow(),
  metadata:       jsonb('metadata').$type<Record<string, unknown>>(), // bounce reason, SMTP response, etc.
})
```

---

## `src/lib/db/schema/platform.ts`

Platform-wide settings, disposable email blocklist, and POST idempotency keys.

```typescript
import { pgTable, text, boolean, integer, jsonb, timestamp, index } from 'drizzle-orm/pg-core'
import { users } from './auth'

// Platform-level settings are controlled via environment variables — no DB table needed.
// All values come from env.ts (Zod-validated). To change a setting: update the env var and restart.
//
//   ALLOW_NEW_SIGNUPS=true            — set false to lock the platform (maintenance)
//   EMAIL_SENDER_NAME=Schduled        — from-name used on all outbound emails
//   MAINTENANCE_MESSAGE=              — if set, shows a maintenance banner on all pages
//   MAX_BOOKINGS_PER_INVITEE_PER_DAY=10
//
// These were previously a platform_settings singleton DB row. Removed: env vars require
// no schema migration to change, and the admin panel for runtime-edit is deferred to Phase 2.

// Blocklist of known disposable/throwaway email providers.
// Stored as a static JSON file: src/lib/data/disposable-domains.json
// Checked at signup; update the file and deploy to add new domains — no cron job or DB table needed.
// import disposableDomains from '@/lib/data/disposable-domains.json'

// Prevents duplicate booking POST submissions from network retries.
// Client generates a UUID idempotency key before POST /api/bookings.
// If the key exists: return the stored response immediately (no re-processing).
// TTL: 24 hours. Pruned by IDEMPOTENCY_KEYS_PRUNE cron (or inline on read).
export const idempotencyKeys = pgTable('idempotency_keys', {
  id:           text('id').primaryKey(),         // = the client-generated UUID key
  requestPath:  text('request_path').notNull(),  // e.g. '/api/bookings'
  responseBody: jsonb('response_body').$type<Record<string, unknown>>(), // stored response
  createdAt:    timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
  expiresAt:    timestamp('expires_at', { withTimezone: true }).notNull(), // 24h TTL
}, (t) => [
  index('idempotency_keys_expires_at_idx').on(t.expiresAt),
])
```

---

## `src/lib/db/schema/relations.ts`

All Drizzle `relations()` definitions in one file. This avoids circular import issues that arise when two schema files both reference each other's tables.

```typescript
import { relations } from 'drizzle-orm'
import { users, sessions, accounts }                                from './auth'
import { userProfiles, userBranding, usernameRedirects }            from './profile'
import { eventTypes, eventTypeDurations, cancellationPolicies,
         eventTypeQuestions }                                       from './event-types'
import { availabilitySchedules, availabilityWindows,
         availabilityOverrides }                                    from './availability'
import { connectedCalendars, calendarEventsCache }                  from './calendars'
import { videoConnections }                                         from './video'
import { bookings, bookingAnswers, bookingGuests }                  from './bookings'
import { notificationPreferences, workflowJobs }                   from './notifications'
import { auditLogs }                                               from './audit'
import { emailOutbox, emailEvents }                                 from './email'

// ── Users ─────────────────────────────────────────────────────────────────────

export const usersRelations = relations(users, ({ one, many }) => ({
  profile:                 one(userProfiles, { fields: [users.id], references: [userProfiles.userId] }),
  branding:                one(userBranding, { fields: [users.id], references: [userBranding.userId] }),
  sessions:                many(sessions),
  accounts:                many(accounts),
  usernameRedirects:       many(usernameRedirects),
  eventTypes:              many(eventTypes),
  availabilitySchedules:   many(availabilitySchedules),
  availabilityOverrides:   many(availabilityOverrides),
  connectedCalendars:      many(connectedCalendars),
  videoConnections:        many(videoConnections),
  notificationPreferences: one(notificationPreferences, { fields: [users.id], references: [notificationPreferences.userId] }),
  hostedBookings:          many(bookings),
  auditLogs:               many(auditLogs),
}))

export const sessionsRelations = relations(sessions, ({ one }) => ({
  user: one(users, { fields: [sessions.userId], references: [users.id] }),
}))

export const accountsRelations = relations(accounts, ({ one }) => ({
  user: one(users, { fields: [accounts.userId], references: [users.id] }),
}))

// ── Profiles ──────────────────────────────────────────────────────────────────

export const userProfilesRelations = relations(userProfiles, ({ one }) => ({
  user: one(users, { fields: [userProfiles.userId], references: [users.id] }),
}))

export const userBrandingRelations = relations(userBranding, ({ one }) => ({
  user: one(users, { fields: [userBranding.userId], references: [users.id] }),
}))

// ── Event Types ───────────────────────────────────────────────────────────────

export const eventTypesRelations = relations(eventTypes, ({ one, many }) => ({
  user:               one(users, { fields: [eventTypes.userId], references: [users.id] }),
  durations:          many(eventTypeDurations),
  cancellationPolicy: one(cancellationPolicies, { fields: [eventTypes.id], references: [cancellationPolicies.eventTypeId] }),
  questions:          many(eventTypeQuestions),
  availabilitySchedule: one(availabilitySchedules, {
    fields: [eventTypes.availabilityScheduleId],
    references: [availabilitySchedules.id],
  }),
  bookings: many(bookings),
}))

export const eventTypeDurationsRelations = relations(eventTypeDurations, ({ one }) => ({
  eventType: one(eventTypes, { fields: [eventTypeDurations.eventTypeId], references: [eventTypes.id] }),
}))

export const eventTypeQuestionsRelations = relations(eventTypeQuestions, ({ one }) => ({
  eventType: one(eventTypes, { fields: [eventTypeQuestions.eventTypeId], references: [eventTypes.id] }),
}))

// ── Availability ──────────────────────────────────────────────────────────────

export const availabilitySchedulesRelations = relations(availabilitySchedules, ({ one, many }) => ({
  user:    one(users, { fields: [availabilitySchedules.userId], references: [users.id] }),
  windows: many(availabilityWindows),
}))

export const availabilityWindowsRelations = relations(availabilityWindows, ({ one }) => ({
  schedule: one(availabilitySchedules, { fields: [availabilityWindows.scheduleId], references: [availabilitySchedules.id] }),
}))

// ── Calendars ─────────────────────────────────────────────────────────────────

export const connectedCalendarsRelations = relations(connectedCalendars, ({ one, many }) => ({
  user:         one(users, { fields: [connectedCalendars.userId], references: [users.id] }),
  cachedEvents: many(calendarEventsCache),
}))

export const calendarEventsCacheRelations = relations(calendarEventsCache, ({ one }) => ({
  calendar: one(connectedCalendars, { fields: [calendarEventsCache.connectedCalendarId], references: [connectedCalendars.id] }),
}))

// ── Video ─────────────────────────────────────────────────────────────────────

export const videoConnectionsRelations = relations(videoConnections, ({ one }) => ({
  user: one(users, { fields: [videoConnections.userId], references: [users.id] }),
}))

// ── Bookings ──────────────────────────────────────────────────────────────────

export const bookingsRelations = relations(bookings, ({ one, many }) => ({
  eventType: one(eventTypes, { fields: [bookings.eventTypeId], references: [eventTypes.id] }),
  host:      one(users, { fields: [bookings.hostUserId], references: [users.id] }),
  answers:   many(bookingAnswers),
  guests:    many(bookingGuests),
  jobs:      many(workflowJobs),
  emails:    many(emailOutbox),
  // Self-referential: the booking this one was rescheduled from
  rescheduledFrom: one(bookings, {
    fields: [bookings.rescheduledFromId],
    references: [bookings.id],
    relationName: 'rescheduleChain',
  }),
}))

export const bookingAnswersRelations = relations(bookingAnswers, ({ one }) => ({
  booking:  one(bookings, { fields: [bookingAnswers.bookingId], references: [bookings.id] }),
  question: one(eventTypeQuestions, { fields: [bookingAnswers.questionId], references: [eventTypeQuestions.id] }),
}))

export const bookingGuestsRelations = relations(bookingGuests, ({ one }) => ({
  booking: one(bookings, { fields: [bookingGuests.bookingId], references: [bookings.id] }),
}))

// ── Notifications ─────────────────────────────────────────────────────────────

export const notificationPreferencesRelations = relations(notificationPreferences, ({ one }) => ({
  user: one(users, { fields: [notificationPreferences.userId], references: [users.id] }),
}))

export const workflowJobsRelations = relations(workflowJobs, ({ one }) => ({
  booking: one(bookings, { fields: [workflowJobs.bookingId], references: [bookings.id] }),
}))

// ── Email ─────────────────────────────────────────────────────────────────────

export const emailOutboxRelations = relations(emailOutbox, ({ one, many }) => ({
  booking: one(bookings, { fields: [emailOutbox.bookingId], references: [bookings.id] }),
  user:    one(users, { fields: [emailOutbox.userId], references: [users.id] }),
  events:  many(emailEvents),
}))

export const emailEventsRelations = relations(emailEvents, ({ one }) => ({
  outbox: one(emailOutbox, { fields: [emailEvents.emailOutboxId], references: [emailOutbox.id] }),
}))
```

---

## `src/lib/db/schema/index.ts`

Re-exports every table, enum, and relation. Import from `@/lib/db/schema` everywhere in the codebase.

```typescript
// Enums
export * from './enums'

// Tables
export * from './auth'
export * from './profile'
export * from './event-types'
export * from './availability'
export * from './calendars'
export * from './video'
export * from './bookings'
export * from './notifications'
export * from './audit'
export * from './email'
export * from './platform'

// Relations (must come after all table exports to avoid circular refs)
export * from './relations'
```

---

## `src/lib/db/index.ts`

Drizzle client — imports the combined schema.

```typescript
import { drizzle } from 'drizzle-orm/postgres-js'
import postgres from 'postgres'
import { env } from '@/lib/env'  // never use process.env.X directly
import * as schema from './schema'

// Global singleton — prevents multiple Drizzle instances in Next.js dev HMR
declare global {
  var dbGlobal: ReturnType<typeof drizzle> | undefined
}

const client = postgres(env.DATABASE_URL, {
  max: 20, // connection pool size
})

const db = global.dbGlobal ?? drizzle(client, { schema })

if (env.NODE_ENV !== 'production') {
  global.dbGlobal = db
}

export default db
export type DB = typeof db
```

---

## `drizzle.config.ts`

Updated to point at the schema index file (or wildcard). `schemaFilter: ['public']` is required.

```typescript
import { defineConfig } from 'drizzle-kit'

export default defineConfig({
  // Point at the index file — Drizzle resolves all re-exported tables
  schema: './src/lib/db/schema/index.ts',
  out: './drizzle',
  dialect: 'postgresql',
  dbCredentials: {
    url: process.env.DATABASE_URL!,
  },
  // REQUIRED: prevents Drizzle Kit from touching pg-boss's pgboss.* schema tables.
  // pg-boss creates its own schema on startup. Without this filter, drizzle-kit generate
  // detects those untracked tables and generates DROP statements — breaking the job queue.
  schemaFilter: ['public'],
})
```

---

## How to Use in Server Actions / API Routes

Import path changes from the old single-file schema — now import from the schema index:

```typescript
// Before (old — single file):
import { users, bookings } from '@/lib/db/schema'

// After (new — same import, different file resolution):
import { users, bookings } from '@/lib/db/schema'  // ← resolves to schema/index.ts — no change needed!

// Query helpers — unchanged:
import { DbBookings } from '@/lib/db/bookings'
import { DbAudit } from '@/lib/db/audit'

const booking = await DbBookings.create({ ... })
await DbAudit.log({ action: 'booking.created', ... })
```

The `index.ts` re-export means all existing import paths stay the same.

---

## Important Schema Notes

### 1. Better Auth — `role: text` not `isPlatformAdmin: boolean`

The Better Auth admin plugin reads a `role` field (string) to grant admin access. The value must be `'admin'`.

```typescript
// Set a user as admin:
await db.update(users).set({ role: 'admin' }).where(eq(users.id, userId))

// Check in middleware / server components:
if (session.user.role !== 'admin') redirect('/dashboard')
```

**Do NOT use `isPlatformAdmin: boolean`** — Better Auth will not recognize it.

### 2. AES-256-GCM Encrypted Fields

These columns store encrypted values. Always call `encrypt(value)` before INSERT and `decrypt(value)` after SELECT:

| Table | Column | What's encrypted |
|-------|--------|-----------------|
| `connected_calendars` | `accessToken` | Google / Outlook OAuth access token |
| `connected_calendars` | `refreshToken` | Google / Outlook OAuth refresh token |
| `video_connections` | `accessToken` | Zoom access token |
| `video_connections` | `refreshToken` | Zoom refresh token |

### 3. Typed JSONB Columns — `.$type<T>()`

All JSONB columns use `.$type<T>()` for TypeScript safety:

| Table | Column | Type |
|-------|--------|------|
| `cancellation_policies` | `cancellationReasonOptions` | `string[]` |
| `event_type_questions` | `options` | `string[]` |
| `email_outbox` | `templateData` | `Record<string, unknown>` |
| `email_events` | `metadata` | `Record<string, unknown>` |
| `audit_logs` | `before` / `after` | `Record<string, unknown>` |
| `idempotency_keys` | `responseBody` | `Record<string, unknown>` |

### 4. Audit Logs — Never Join to `users`

`actorEmail` is denormalized. Write it at log time. Never `JOIN audit_logs` to `users` — the user may have been deleted, but the audit record must survive.

### 5. Times — UTC in DB, Timezone at Display

- All `timestamp` columns store UTC
- `startTime` / `endTime` in `bookings`: `{ withTimezone: true }` — use `timestamptz` in PostgreSQL
- `availabilityWindows.startTime` / `endTime`: stored as `"HH:mm"` strings in the SCHEDULE's timezone, not UTC. Convert per-slot at query time to handle DST.

---

## Table Summary — 30 Tables

| Domain | Tables | Schema File | Query Helper |
|--------|--------|-------------|-------------|
| **Auth** | `users`, `sessions`, `accounts`, `verifications` | `auth.ts` | `DbUsers` |
| **Profile** | `user_profiles`, `user_branding`, `username_redirects` | `profile.ts` | `DbUsers` |
| **Event Types** | `event_types`, `event_type_durations`, `cancellation_policies`, `event_type_questions` | `event-types.ts` | `DbEventTypes` |
| **Availability** | `availability_schedules`, `availability_windows`, `availability_overrides` | `availability.ts` | `DbAvailability` |
| **Calendars** | `connected_calendars`, `calendar_events_cache` | `calendars.ts` | `DbCalendars` |
| **Video** | `video_connections` | `video.ts` | `DbVideo` |
| **Bookings** | `bookings`, `booking_answers`, `booking_guests` | `bookings.ts` | `DbBookings` |
| **Notifications** | `notification_preferences`, `workflow_jobs` | `notifications.ts` | `DbNotifications` |
| **Audit** | `audit_logs` | `audit.ts` | `DbAudit` |
| **Email** | `email_outbox`, `email_events` | `email.ts` | `DbEmail` |
| **Platform** | `idempotency_keys` | `platform.ts` | — |

**Total: 26 tables** across 11 domain schema files + 1 enums file + 1 relations file + 1 index.
*(platform_settings removed → env vars; disposable_email_domains removed → static JSON; contacts tables deferred to Phase 2)*
