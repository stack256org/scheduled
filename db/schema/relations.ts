import { relations } from 'drizzle-orm'
import { user } from './auth'
import { userProfile, userBranding, usernameRedirect } from './profile'
import { eventType, eventTypeDuration, cancellationPolicy, eventTypeQuestion } from './event-types'
import { availabilitySchedule, availabilityWindow, availabilityOverride } from './availability'
import { connectedCalendar, calendarEventCache } from './calendars'
import { videoConnection } from './video'
import { booking, bookingAnswer, bookingGuest } from './bookings'
import { notificationPreference, workflowJob } from './notifications'

export const userRelations = relations(user, ({ one, many }) => ({
  profile:                one(userProfile, { fields: [user.id], references: [userProfile.userId] }),
  branding:               one(userBranding, { fields: [user.id], references: [userBranding.userId] }),
  usernameRedirects:      many(usernameRedirect),
  eventTypes:             many(eventType),
  availabilitySchedules:  many(availabilitySchedule),
  availabilityOverrides:  many(availabilityOverride),
  connectedCalendars:     many(connectedCalendar),
  videoConnections:       many(videoConnection),
  notificationPreference: one(notificationPreference, { fields: [user.id], references: [notificationPreference.userId] }),
  bookings:               many(booking),
}))

export const userProfileRelations = relations(userProfile, ({ one }) => ({
  user: one(user, { fields: [userProfile.userId], references: [user.id] }),
}))

export const userBrandingRelations = relations(userBranding, ({ one }) => ({
  user: one(user, { fields: [userBranding.userId], references: [user.id] }),
}))

export const usernameRedirectRelations = relations(usernameRedirect, ({ one }) => ({
  user: one(user, { fields: [usernameRedirect.userId], references: [user.id] }),
}))

export const eventTypeRelations = relations(eventType, ({ one, many }) => ({
  user:               one(user, { fields: [eventType.userId], references: [user.id] }),
  durations:          many(eventTypeDuration),
  cancellationPolicy: one(cancellationPolicy, { fields: [eventType.id], references: [cancellationPolicy.eventTypeId] }),
  questions:          many(eventTypeQuestion),
  bookings:           many(booking),
}))

export const eventTypeDurationRelations = relations(eventTypeDuration, ({ one }) => ({
  eventType: one(eventType, { fields: [eventTypeDuration.eventTypeId], references: [eventType.id] }),
}))

export const cancellationPolicyRelations = relations(cancellationPolicy, ({ one }) => ({
  eventType: one(eventType, { fields: [cancellationPolicy.eventTypeId], references: [eventType.id] }),
}))

export const eventTypeQuestionRelations = relations(eventTypeQuestion, ({ one, many }) => ({
  eventType:      one(eventType, { fields: [eventTypeQuestion.eventTypeId], references: [eventType.id] }),
  bookingAnswers: many(bookingAnswer),
}))

export const availabilityScheduleRelations = relations(availabilitySchedule, ({ one, many }) => ({
  user:    one(user, { fields: [availabilitySchedule.userId], references: [user.id] }),
  windows: many(availabilityWindow),
}))

export const availabilityWindowRelations = relations(availabilityWindow, ({ one }) => ({
  schedule: one(availabilitySchedule, { fields: [availabilityWindow.scheduleId], references: [availabilitySchedule.id] }),
}))

export const availabilityOverrideRelations = relations(availabilityOverride, ({ one }) => ({
  user: one(user, { fields: [availabilityOverride.userId], references: [user.id] }),
}))

export const connectedCalendarRelations = relations(connectedCalendar, ({ one, many }) => ({
  user:        one(user, { fields: [connectedCalendar.userId], references: [user.id] }),
  eventCache:  many(calendarEventCache),
}))

export const calendarEventCacheRelations = relations(calendarEventCache, ({ one }) => ({
  calendar: one(connectedCalendar, { fields: [calendarEventCache.connectedCalendarId], references: [connectedCalendar.id] }),
}))

export const videoConnectionRelations = relations(videoConnection, ({ one }) => ({
  user: one(user, { fields: [videoConnection.userId], references: [user.id] }),
}))

export const bookingRelations = relations(booking, ({ one, many }) => ({
  eventType:   one(eventType, { fields: [booking.eventTypeId], references: [eventType.id] }),
  host:        one(user, { fields: [booking.hostUserId], references: [user.id] }),
  answers:     many(bookingAnswer),
  guests:      many(bookingGuest),
  workflowJobs: many(workflowJob),
}))

export const bookingAnswerRelations = relations(bookingAnswer, ({ one }) => ({
  booking:  one(booking, { fields: [bookingAnswer.bookingId], references: [booking.id] }),
  question: one(eventTypeQuestion, { fields: [bookingAnswer.questionId], references: [eventTypeQuestion.id] }),
}))

export const bookingGuestRelations = relations(bookingGuest, ({ one }) => ({
  booking: one(booking, { fields: [bookingGuest.bookingId], references: [booking.id] }),
}))

export const notificationPreferenceRelations = relations(notificationPreference, ({ one }) => ({
  user: one(user, { fields: [notificationPreference.userId], references: [user.id] }),
}))

export const workflowJobRelations = relations(workflowJob, ({ one }) => ({
  booking: one(booking, { fields: [workflowJob.bookingId], references: [booking.id] }),
}))
