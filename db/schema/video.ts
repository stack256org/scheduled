import { createId } from '@paralleldrive/cuid2'
import { pgTable, text, timestamp, uniqueIndex } from 'drizzle-orm/pg-core'
import { user } from './auth'
import { videoProviderEnum } from './enums'

export const videoConnection = pgTable('video_connection', {
  id:             text('id').primaryKey().$defaultFn(createId),
  userId:         text('user_id').notNull().references(() => user.id, { onDelete: 'cascade' }),
  provider:       videoProviderEnum('provider').notNull(),
  accountEmail:   text('account_email'),
  accessToken:    text('access_token').notNull(),
  refreshToken:   text('refresh_token'),
  tokenExpiresAt: timestamp('token_expires_at', { withTimezone: true }),
  providerUserId: text('provider_user_id'),
  createdAt:      timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
}, (t) => [
  // One connection per provider per user — prevents duplicate/stale rows.
  uniqueIndex('video_connection_user_provider_unq').on(t.userId, t.provider),
])
