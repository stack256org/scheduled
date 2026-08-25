import { createId } from '@paralleldrive/cuid2'
import { boolean, index, pgTable, text, timestamp, uniqueIndex } from 'drizzle-orm/pg-core'
import { user } from './auth'

export const contact = pgTable('contact', {
  id:         text('id').primaryKey().$defaultFn(createId),
  hostUserId: text('host_user_id').notNull().references(() => user.id, { onDelete: 'cascade' }),
  email:      text('email').notNull(),
  name:       text('name').notNull(),
  notes:      text('notes'),
  isArchived: boolean('is_archived').notNull().default(false),
  createdAt:  timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
  updatedAt:  timestamp('updated_at', { withTimezone: true }).notNull().defaultNow(),
}, (t) => [
  index('contact_host_idx').on(t.hostUserId),
  uniqueIndex('contact_host_email_idx').on(t.hostUserId, t.email),
])
