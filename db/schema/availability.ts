import { createId } from '@paralleldrive/cuid2'
import { boolean, index, integer, pgTable, text, timestamp } from 'drizzle-orm/pg-core'
import { user } from './auth'
import { dayOfWeekEnum, meetingLimitPeriodEnum } from './enums'

export const availabilitySchedule = pgTable('availability_schedule', {
  id:        text('id').primaryKey().$defaultFn(createId),
  userId:    text('user_id').notNull().references(() => user.id, { onDelete: 'cascade' }),
  name:      text('name').notNull().default('Working Hours'),
  isDefault: boolean('is_default').notNull().default(true),
  timezone:  text('timezone').notNull(),
  createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
})

export const availabilityWindow = pgTable('availability_window', {
  id:         text('id').primaryKey().$defaultFn(createId),
  scheduleId: text('schedule_id').notNull().references(() => availabilitySchedule.id, { onDelete: 'cascade' }),
  dayOfWeek:  dayOfWeekEnum('day_of_week').notNull(),
  startTime:  text('start_time').notNull(),
  endTime:    text('end_time').notNull(),
})

export const availabilityOverride = pgTable('availability_override', {
  id:        text('id').primaryKey().$defaultFn(createId),
  userId:    text('user_id').notNull().references(() => user.id, { onDelete: 'cascade' }),
  date:      text('date').notNull(),
  isBlocked: boolean('is_blocked').notNull().default(true),
  startTime: text('start_time'),
  endTime:   text('end_time'),
  reason:    text('reason'),
  createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
}, (t) => [
  index('availability_override_user_date_idx').on(t.userId, t.date),
])

export const meetingLimit = pgTable('meeting_limit', {
  id:        text('id').primaryKey().$defaultFn(createId),
  userId:    text('user_id').notNull().references(() => user.id, { onDelete: 'cascade' }),
  period:    meetingLimitPeriodEnum('period').notNull(),
  count:     integer('count').notNull(),
  createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
})
