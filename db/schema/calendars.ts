import { sql } from 'drizzle-orm'
import { createId } from '@paralleldrive/cuid2'
import { boolean, index, pgTable, text, timestamp, uniqueIndex } from 'drizzle-orm/pg-core'
import { user } from './auth'
import { calendarProviderEnum, calendarStatusEnum } from './enums'

export const connectedCalendar = pgTable('connected_calendar', {
  id:              text('id').primaryKey().$defaultFn(createId),
  userId:          text('user_id').notNull().references(() => user.id, { onDelete: 'cascade' }),
  provider:        calendarProviderEnum('provider').notNull(),
  accountEmail:    text('account_email').notNull(),
  accessToken:     text('access_token'),
  refreshToken:    text('refresh_token'),
  tokenExpiresAt:  timestamp('token_expires_at', { withTimezone: true }),
  status:          calendarStatusEnum('status').notNull().default('connected'),
  disconnectedAt:  timestamp('disconnected_at', { withTimezone: true }),
  calendarId:      text('calendar_id'),
  calendarName:    text('calendar_name'),
  isPrimary:       boolean('is_primary').notNull().default(false),
  isConflictCheck: boolean('is_conflict_check').notNull().default(true),
  isWriteTarget:   boolean('is_write_target').notNull().default(false),
  createdAt:       timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
}, (t) => [
  index('connected_calendar_user_provider_idx').on(t.userId, t.provider),
  index('connected_calendar_status_idx').on(t.status),
  uniqueIndex('connected_calendar_one_write_target').on(t.userId).where(sql`is_write_target = true`),
])

export const calendarEventCache = pgTable('calendar_event_cache', {
  id:                  text('id').primaryKey().$defaultFn(createId),
  connectedCalendarId: text('connected_calendar_id').notNull().references(() => connectedCalendar.id, { onDelete: 'cascade' }),
  externalEventId:     text('external_event_id').notNull(),
  startTime:           timestamp('start_time', { withTimezone: true }).notNull(),
  endTime:             timestamp('end_time', { withTimezone: true }).notNull(),
  isBusy:              boolean('is_busy').notNull().default(true),
  syncedAt:            timestamp('synced_at', { withTimezone: true }).notNull().defaultNow(),
}, (t) => [
  index('calendar_event_cache_cal_time_idx').on(t.connectedCalendarId, t.startTime, t.endTime),
  // One cache row per external event per calendar — enables safe upserts.
  uniqueIndex('calendar_event_cache_cal_event_unq').on(t.connectedCalendarId, t.externalEventId),
])
