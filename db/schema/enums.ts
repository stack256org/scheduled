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
  'phone_host_calls',
  'phone_invitee_calls',
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
  'multiple_select',
  'number',
  'date',
  'url',
])

export const dayOfWeekEnum = pgEnum('day_of_week', [
  'monday', 'tuesday', 'wednesday', 'thursday',
  'friday', 'saturday', 'sunday',
])

export const meetingLimitPeriodEnum = pgEnum('meeting_limit_period', ['day', 'week', 'month'])

export const bookingWindowTypeEnum = pgEnum('booking_window_type', [
  'rolling',
  'fixed',
])

export const meetingTypeEnum = pgEnum('meeting_type', [
  'one_on_one',
  'group',
  'round_robin',
  'collective',
])

export const bookingStatusEnum = pgEnum('booking_status', [
  'pending',
  'confirmed',
  'reschedule_requested',
  'cancelled',
  'rescheduled',
  'completed',
  'no_show',
])

// ── Calendars & Video ────────────────────────────────────────────────────────

export const calendarProviderEnum = pgEnum('calendar_provider', [
  'google',
  'outlook',
  'apple',
  'caldav',
])

export const calendarStatusEnum = pgEnum('calendar_status', [
  'connected',
  'disconnected',
])

export const videoProviderEnum = pgEnum('video_provider', [
  'zoom',
  'teams',
])

// ── Jobs ─────────────────────────────────────────────────────────────────────

export const jobStatusEnum = pgEnum('job_status', [
  'pending',
  'running',
  'completed',
  'failed',
  'cancelled',
])

// ── Audit ────────────────────────────────────────────────────────────────────

export const auditSourceEnum = pgEnum('audit_source', [
  'web',
  'api',
  'worker',
  'system',
])

export const auditActionEnum = pgEnum('audit_action', [
  // Auth
  'user.signup',
  'user.signin',
  'user.signout',
  'user.password_reset',
  // Admin
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
  'user.email_change_requested',
  'user.account_deleted',
  // Branding
  'user.branding_updated',
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
  'availability.schedule_created',
  'availability.schedule_deleted',
  'availability.schedule_updated',
  'availability.override_added',
  'availability.override_removed',
  'availability.schedule_assigned',
  // Calendars
  'calendar.connected',
  'calendar.disconnected',
])
