import { createId } from '@paralleldrive/cuid2'
import { pgTable, text, timestamp } from 'drizzle-orm/pg-core'
import { user } from './auth'

export const bookingBlocklist = pgTable('booking_blocklist', {
  id:        text('id').primaryKey().$defaultFn(createId),
  userId:    text('user_id').notNull().references(() => user.id, { onDelete: 'cascade' }),
  pattern:   text('pattern').notNull(),
  type:      text('type', { enum: ['email', 'domain'] as const }).$type<'email' | 'domain'>().notNull(),
  note:      text('note'),
  createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
})
