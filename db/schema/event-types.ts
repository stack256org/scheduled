import { createId } from '@paralleldrive/cuid2'
import { boolean, date, index, integer, jsonb, pgTable, text, timestamp, uniqueIndex } from 'drizzle-orm/pg-core'
import { user } from './auth'
import { locationTypeEnum, questionTypeEnum, bookingWindowTypeEnum, meetingTypeEnum } from './enums'

export const eventType = pgTable('event_type', {
  id:                     text('id').primaryKey().$defaultFn(createId),
  userId:                 text('user_id').notNull().references(() => user.id, { onDelete: 'cascade' }),
  availabilityScheduleId: text('availability_schedule_id'),
  name:                   text('name').notNull(),
  slug:                   text('slug').notNull(),
  description:            text('description'),
  meetingType:            meetingTypeEnum('meeting_type').notNull().default('one_on_one'),
  locationType:           locationTypeEnum('location_type').notNull().default('zoom'),
  locationValue:          text('location_value'),
  hostPhoneNumber:        text('host_phone_number'),
  color:                  text('color').default('#0d9488'),
  isActive:               boolean('is_active').notNull().default(true),
  isHidden:               boolean('is_hidden').notNull().default(false),
  position:               integer('position').default(0),
  minimumNotice:          integer('minimum_notice').default(60),
  bookingWindow:          integer('booking_window').default(60),
  bookingWindowType:      bookingWindowTypeEnum('booking_window_type').default('rolling'),
  // For bookingWindowType='fixed' — invitees can only book within this date range.
  bookingRangeStart:      date('booking_range_start'),
  bookingRangeEnd:        date('booking_range_end'),
  bufferBefore:           integer('buffer_before').default(0),
  bufferAfter:            integer('buffer_after').default(0),
  maxBookingsPerDay:      integer('max_bookings_per_day'),
  startTimeIncrement:     integer('start_time_increment').default(30),
  requiresApproval:            boolean('requires_approval').notNull().default(false),
  requiresEmailVerification:   boolean('requires_email_verification').notNull().default(false),
  confirmationNote:            text('confirmation_note'),
  createdAt:              timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
  updatedAt:              timestamp('updated_at', { withTimezone: true }).notNull().defaultNow(),
}, (t) => [
  uniqueIndex('event_type_user_slug_idx').on(t.userId, t.slug),
  index('event_type_user_active_idx').on(t.userId, t.isActive),
])

export const eventTypeDuration = pgTable('event_type_duration', {
  id:          text('id').primaryKey().$defaultFn(createId),
  eventTypeId: text('event_type_id').notNull().references(() => eventType.id, { onDelete: 'cascade' }),
  duration:    integer('duration').notNull(),
  isDefault:   boolean('is_default').notNull().default(false),
})

export const cancellationPolicy = pgTable('cancellation_policy', {
  id:                        text('id').primaryKey().$defaultFn(createId),
  eventTypeId:               text('event_type_id').notNull().unique().references(() => eventType.id, { onDelete: 'cascade' }),
  allowCancellation:         boolean('allow_cancellation').notNull().default(true),
  cutoffHours:               integer('cutoff_hours').default(0),
  allowRescheduling:         boolean('allow_rescheduling').notNull().default(true),
  rescheduleCutoffHours:     integer('reschedule_cutoff_hours').default(0),
  maxReschedules:            integer('max_reschedules'),
  requireCancellationReason: boolean('require_cancellation_reason').notNull().default(false),
  cancellationReasonOptions: jsonb('cancellation_reason_options').$type<string[]>(),
  showPolicyText:            boolean('show_policy_text').notNull().default(true),
  policyText:                text('policy_text'),
  createdAt:                 timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
})

export const eventTypeQuestion = pgTable('event_type_question', {
  id:          text('id').primaryKey().$defaultFn(createId),
  eventTypeId: text('event_type_id').notNull().references(() => eventType.id, { onDelete: 'cascade' }),
  label:       text('label').notNull(),
  type:        questionTypeEnum('type').notNull(),
  isRequired:  boolean('is_required').notNull().default(false),
  options:     jsonb('options').$type<string[]>(),
  placeholder: text('placeholder'),
  position:    integer('position').notNull().default(0),
  isActive:    boolean('is_active').notNull().default(true),
})
