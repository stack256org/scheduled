# Schduled — System Architecture

This document describes the complete system architecture of Schduled: how the components are structured, how data flows between them, and why each architectural decision was made.

> **Architecture:** Two-process pattern — Next.js web server + pg-boss worker, both sharing one PostgreSQL database.

---

## High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              BROWSER                                        │
│  React UI (Server Components + Client Components)                           │
│  - Booking pages (unauthenticated)                                          │
│  - Host dashboard (authenticated)                                           │
│  - Admin panel (admin-only)                                                 │
└───────────────┬──────────────────────────────────┬──────────────────────────┘
                │ HTTP                             │ HTTP
                ▼                                 ▼
┌───────────────────────────┐     ┌───────────────────────────┐
│   Next.js Server          │     │   Next.js API Routes      │
│   (Server Components)     │     │   /api/**                 │
│   - Renders HTML          │     │   - Auth endpoints        │
│   - Server Actions        │     │   - Booking POST          │
│   - Page data fetching    │     │   - Calendar OAuth        │
│   - Admin pages           │     │   - Slot availability     │
└───────────┬───────────────┘     └────────────┬──────────────┘
            │                                  │
            └──────────────┬───────────────────┘
                           │ Drizzle ORM
                           ▼
┌──────────────────────────────────────────────────────────────┐
│                    PostgreSQL Database                       │
│                                                              │
│  public.*    ← App tables (Drizzle manages schema)           │
│  pgboss.*    ← Job queue tables (pg-boss manages itself)     │
└──────────────────────────────────────────────────────────────┘
                           ▲
                           │ postgres driver (separate pool)
┌──────────────────────────┴───────────────────────────────────┐
│                    pg-boss Worker Process                    │
│                    (pnpm worker)                             │
│                                                              │
│  16 job handlers                                             │
│  4 cron schedules                                            │
│  - EMAIL_SEND        → Nodemailer SMTP                       │
│  - CALENDAR_*        → Google Calendar / MS Graph            │
│  - VIDEO_LINK_*      → Zoom API                              │
│  - BOOKING_REMINDER_* → Schedules future email sends         │
│  - CALENDAR_SYNC     → Cron: 5-min free/busy cache refresh   │
└──────────────────────────────────────────────────────────────┘
```

---

## Two-Process Architecture

Schduled runs as **two separate processes** that share one PostgreSQL database:

| Process | Command | Responsibilities |
|---------|---------|-----------------|
| **Next.js Server** | `pnpm dev` or `pnpm start` | Serve web UI, handle API requests, render Server Components, execute Server Actions |
| **pg-boss Worker** | `pnpm worker` | Process background jobs: send emails, write calendar events, generate video links, run cron tasks |

**Why two processes?**

1. **Long-running tasks** (calendar sync, email sending) would block or timeout in an API route
2. **Retry logic** — pg-boss handles retries automatically; the worker doesn't need the HTTP context
3. **Crash isolation** — if the worker crashes, the web server continues serving traffic; jobs queue until the worker restarts
4. **Separation of concerns** — the Next.js server handles user-facing latency; the worker handles throughput

**In development:** `concurrently "pnpm next dev" "pnpm tsx src/lib/worker/index.ts"` runs both from one terminal using the `dev` script in `package.json`.

**In production:** Two separate processes (pm2 / systemd / Docker containers). The worker auto-restarts on crash.

### PostgreSQL Connection Pool — Shared Between Processes

Both the Next.js server and the pg-boss worker connect to the **same PostgreSQL database** using the same `DATABASE_URL`. Each process opens its own connection pool. PostgreSQL's default `max_connections` is 100 — with two pools this can be exhausted quickly under load.

**Production requirement:** Set PostgreSQL `max_connections = 200` and configure a connection pooler (PgBouncer) in front of the database. Without this, both processes compete for connections and queries will fail with "too many clients" errors under concurrent load.

**Development:** Default `max_connections` is fine — single developer, low concurrency.

---

## Request Flow: Booking a Meeting

The most critical flow in the system — from invitee clicking a time slot to confirmation emails sent.

```
Browser                   Next.js                  PostgreSQL           pg-boss Worker
   │                         │                          │                     │
   │ GET /jane/30min-call     │                          │                     │
   │─────────────────────────▶│                          │                     │
   │  Server Component fetches│ SELECT event_type,       │                     │
   │  available slots         │ availability, calendars  │                     │
   │                         │──────────────────────────▶│                     │
   │                         │◀──────────────────────────│                     │
   │◀─────────────────────────│                          │                     │
   │  Booking page rendered   │                          │                     │
   │                         │                          │                     │
   │ POST /api/bookings       │                          │                     │
   │ { slot, name, email }    │                          │                     │
   │─────────────────────────▶│                          │                     │
   │                         │ BEGIN TRANSACTION         │                     │
   │                         │ pg_advisory_xact_lock()  │                     │
   │                         │ check idempotency_keys   │                     │
   │                         │ check calendar_events_cache                     │
   │                         │ INSERT bookings          │                     │
   │                         │ INSERT email_outbox ×2   │                     │
   │                         │ INSERT audit_logs        │                     │
   │                         │ INSERT idempotency_keys  │                     │
   │                         │──────────────────────────▶│                     │
   │                         │ COMMIT                    │                     │
   │                         │                          │                     │
   │                         │ boss.send(EMAIL_SEND ×2) │                     │
   │                         │ boss.send(VIDEO_LINK_GENERATE)                 │
   │                         │ boss.send(CALENDAR_WRITE)│                     │
   │                         │ boss.sendAfter(REMINDER_24H, REMINDER_1H)      │
   │                         │──────────────────────────▶│                     │
   │◀─────────────────────────│                          │                     │
   │  200 { booking, link }   │                          │                     │
   │                         │                          │                     │
   │  (invitee sees           │                          │                     │
   │   confirmation page)     │                          │                     │
   │                         │                          │ ◀── picks up jobs    │
   │                         │                          │     EMAIL_SEND       │
   │                         │                          │     CALENDAR_WRITE   │
   │                         │                          │     VIDEO_LINK_GENERATE
```

**Key guarantee:** The booking record is committed before any external API call. If Zoom is down, the booking exists and the job retries. The invitee always gets a confirmed booking.

---

## Authentication Flow

```
┌────────────────────────────────────────────────────────────┐
│                    Better Auth                             │
│                                                            │
│  ┌──────────────┐   ┌──────────────┐   ┌──────────────┐  │
│  │ Google OAuth │   │ Email + Pass │   │ Magic Link   │  │
│  └──────┬───────┘   └──────┬───────┘   └──────┬───────┘  │
│         └──────────────────┴──────────────────┘           │
│                            │                               │
│              Better Auth handler (/api/auth/[...all])     │
│                            │                               │
│         ┌──────────────────┴──────────────────┐           │
│         │          PostgreSQL                  │           │
│         │  user, session, account, verification│           │
│         └─────────────────────────────────────┘           │
└────────────────────────────────────────────────────────────┘
         │
         ▼
src/middleware.ts
- Every request checks session via auth.api.getSession()
- /admin/* → redirect to /sign-in if no session
- /admin/* → redirect to /dashboard if session but session.user.role !== 'admin'
- /dashboard/* → redirect to /sign-in if no session
- Incomplete onboarding → redirect to /onboarding/[step]
```

**Permission hierarchy:**

```
Public routes            /[username]/[eventSlug]  (booking pages)
                         /[username]/              (profile overview)
                         /api/bookings            (booking POST)
                         /api/slots               (slot availability)
                         ↕
Authenticated routes     /dashboard/*             (host dashboard)
                         /settings/*              (profile settings)
                         /api/auth/*              (session management)
                         ↕
Admin-only routes        /admin/*                 (admin panel)
                         /api/admin/*             (admin API)
```

---

## Database Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                  public schema (Drizzle manages)            │
│                                                             │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  AUTH (Better Auth managed)                          │  │
│  │  users  sessions  accounts  verifications            │  │
│  └──────────────────────────────────────────────────────┘  │
│                                                             │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  USER PROFILE                                        │  │
│  │  user_profiles  user_branding  username_redirects    │  │
│  └──────────────────────────────────────────────────────┘  │
│                                                             │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  SCHEDULING CORE                                     │  │
│  │  event_types  event_type_durations                   │  │
│  │  availability_schedules  availability_windows        │  │
│  │  availability_overrides  cancellation_policies       │  │
│  │  event_type_questions                                │  │
│  └──────────────────────────────────────────────────────┘  │
│                                                             │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  CALENDAR & VIDEO                                    │  │
│  │  connected_calendars  calendar_events_cache          │  │
│  │  video_connections                                   │  │
│  └──────────────────────────────────────────────────────┘  │
│                                                             │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  BOOKINGS                                            │  │
│  │  bookings  booking_answers  booking_guests           │  │
│  └──────────────────────────────────────────────────────┘  │
│                                                             │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  NOTIFICATIONS                                       │  │
│  │  notification_preferences  workflow_jobs             │  │
│  │  email_outbox  email_events                          │  │
│  └──────────────────────────────────────────────────────┘  │
│                                                             │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  PLATFORM                                            │  │
│  │  audit_logs  platform_settings                       │  │
│  │  idempotency_keys  disposable_email_domains          │  │
│  └──────────────────────────────────────────────────────┘  │
│                                                             │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│                  pgboss schema (pg-boss manages)            │
│                                                             │
│  job  schedule  subscription  version  ...                  │
│  (never modified via Drizzle migrations)                    │
└─────────────────────────────────────────────────────────────┘
```

**Total: 30 app tables** (22 original + 8 new platform tables)

---

## Server Components vs. Client Components

Following Next.js App Router conventions:

```
Server Components (default — no 'use client')
├── All data-fetching pages (booking page, dashboard, admin)
├── Server Actions for mutations ('use server')
├── Direct Drizzle ORM calls (no API round-trip)
└── Never exposed to browser bundle

Client Components ('use client' required)
├── Interactive forms (react-hook-form)
├── Date picker (booking calendar)
├── Toast notifications (sonner)
├── Theme toggle (next-themes)
└── Any component with useState / useEffect
```

**Rule:** Start every component as a Server Component. Only add `'use client'` when the component needs browser APIs, event handlers, or React state/effects.

---

## Server Actions vs. API Routes

| Use | When |
|-----|------|
| **Server Actions** (`'use server'`) | Mutations from the authenticated host dashboard (create event type, update availability, cancel booking from dashboard, change settings). No `fetch()` call needed — callable directly from Server or Client Components. |
| **API Routes** (`route.ts`) | Public endpoints (booking POST from unauthenticated invitees, slot availability GET, OAuth callbacks, calendar OAuth redirects, Zoom OAuth callback). Must be HTTP-accessible. |
| **Never** | Inline DB calls from Client Components. Always go through Server Actions or API Routes. |

### Server Action Standard Pattern

Every Server Action in Schduled must follow this pattern — no exceptions.

**Return type:** discriminated union `{ error: string } | { ok: true }`. Never throw to the client. Never return `null` or `undefined`. Never return a plain boolean.

```typescript
// Standard return type — add extra fields to the ok branch when needed
type ActionResult<T = Record<string, never>> =
  | { error: string }
  | ({ ok: true } & T)
```

**Full action template:**

```typescript
// src/app/actions/event-types.ts
'use server'

import { headers } from 'next/headers'
import { auth } from '@/lib/auth'
import { db } from '@/lib/db'
import { eventTypes } from '@/lib/db/schema'
import { createEventTypeSchema } from '@/lib/validators'
import { createId } from '@paralleldrive/cuid2'
import { DbAudit } from '@/lib/db/audit'

export async function createEventTypeAction(
  input: unknown,
): Promise<ActionResult<{ eventTypeId: string }>> {
  try {
    // 1. Auth check — always first
    const session = await auth.api.getSession({ headers: await headers() })
    if (!session) return { error: 'Unauthorized' }

    // 2. Input validation — always before DB
    const parsed = createEventTypeSchema.safeParse(input)
    if (!parsed.success) return { error: parsed.error.issues[0].message }

    // 3. Business logic
    const id = createId()
    await db.insert(eventTypes).values({ id, userId: session.user.id, ...parsed.data })

    // 4. Audit log
    await DbAudit.log({
      actorUserId: session.user.id,
      actorEmail: session.user.email,
      action: 'event_type.created',
      targetType: 'event_type',
      targetId: id,
      source: 'web',
    })

    // 5. Return success with data
    return { ok: true, eventTypeId: id }

  } catch (err) {
    // 6. Never let errors bubble to the client — log server-side, return generic message
    console.error('[action:createEventType]', err)
    return { error: 'Something went wrong. Please try again.' }
  }
}
```

**Client-side usage:**

```typescript
// In a Client Component or Server Component
const result = await createEventTypeAction(formData)

if ('error' in result) {
  toast.error(result.error)
  return
}

// result.ok === true here — TypeScript narrows the type
router.push(`/dashboard/event-types/${result.eventTypeId}`)
```

**Rules:**
1. Always wrap in `try/catch` — never let unhandled errors reach the client
2. Auth check is always the first thing inside the try block
3. Zod validate input before touching the DB
4. Log errors with a `[action:actionName]` prefix so they're easy to grep in logs
5. Generic error message to client — never expose DB errors, stack traces, or internal state

### API Route Standard Pattern

API routes use a shared set of helpers from `src/lib/api/helpers.ts`. These keep every route handler concise and consistent — auth checks and response formatting are never written inline.

```typescript
// src/lib/api/helpers.ts
import { auth } from '@/lib/auth'

// Typed JSON response — avoids repeating Response.json(..., { status }) everywhere
export function jsonResponse(status: number, body: Record<string, unknown>) {
  return Response.json(body, { status })
}

// Throws a 401 Response if no session — caught by the route's try/catch and re-thrown
export async function requireSession(request: Request) {
  const session = await auth.api.getSession({ headers: request.headers })
  if (!session) throw jsonResponse(401, { error: 'Unauthorized' })
  return session
}

// Throws 403 if session exists but user is not an admin
export async function requireAdmin(request: Request) {
  const session = await requireSession(request)
  if (session.user.role !== 'admin') throw jsonResponse(403, { error: 'Forbidden' })
  return session
}
```

**Full API route template:**

```typescript
// app/api/event-types/[id]/route.ts
import { jsonResponse, requireSession } from '@/lib/api/helpers'
import { extractRequestContext } from '@/lib/db/audit'
import { applyRateLimit } from '@/lib/rate-limit'

export async function DELETE(
  request: Request,
  { params }: { params: { id: string } },
) {
  // 1. Rate limit (public routes only — skip for authenticated routes if not needed)
  // const limited = applyRateLimit(request)
  // if (limited) return limited

  try {
    // 2. Auth — throws 401 Response if not signed in
    const session = await requireSession(request)

    // 3. Validate params / body
    const { id } = await params
    if (!id) return jsonResponse(400, { error: 'Missing event type ID' })

    // 4. Business logic
    await DbEventTypes.delete(id, session.user.id)

    // 5. Audit log
    const { ipAddress, userAgent } = extractRequestContext(request.headers)
    await DbAudit.log({
      actorUserId: session.user.id,
      actorEmail:  session.user.email,
      action:      'event_type.deleted',
      targetType:  'event_type',
      targetId:    id,
      source:      'api',
      ipAddress,
      userAgent,
    })

    return jsonResponse(200, { ok: true })

  } catch (err) {
    // Re-throw Response objects (from requireSession / requireAdmin)
    if (err instanceof Response) return err
    console.error('[api:DELETE /event-types/:id]', err)
    return jsonResponse(500, { error: 'Internal server error' })
  }
}
```

**Key differences from Server Actions:**

| | Server Actions | API Routes |
|--|---------------|------------|
| Auth helper | `auth.api.getSession({ headers: await headers() })` | `requireSession(request)` — throws a Response |
| Error handling | Return `{ error }` | Return `jsonResponse(4xx/5xx, { error })` |
| Rate limiting | Not needed (authenticated only) | Apply on public routes (`/api/bookings`, `/api/slots`) |
| `source` in audit log | `'web'` | `'api'` |

---

## Email Architecture

```
Any mutation that sends an email:
    │
    ▼
1. Server Action / API Route
   → INSERT email_outbox row (status = 'pending')
   → (inside same DB transaction as main mutation)
    │
    ▼ (after transaction commit)
2. boss.send('EMAIL_SEND', { emailOutboxId })
    │
    ▼
3. pg-boss worker: EMAIL_SEND handler
   → Fetch email_outbox row
   → Render React Email template (renderAsync(Template, data))
   → Send via Nodemailer transporter
   → Update email_outbox.status = 'sent'
   → Insert email_events row
    │
    ├── On failure: pg-boss retries 3× (30s → 60s → 120s backoff)
    └── After 3 failures: status = 'failed', errorMessage = last error
```

**Why this pattern:**
- Email delivery never blocks the user response
- SMTP failures are retried automatically without user action
- Full delivery history visible in admin panel per user
- The DB transaction guarantees the email row is created atomically with the booking

---

## Calendar Sync Architecture

```
Every 5 minutes (CALENDAR_SYNC cron):
    │
    ▼
Worker: CALENDAR_SYNC handler
    → SELECT all connected_calendars WHERE status = 'connected'
    │
    ├── For each calendar:
    │   → Check if token is expired
    │   │
    │   ├── If expired: CALENDAR_TOKEN_REFRESH job
    │   │   → Refresh OAuth token from provider
    │   │   → Update connected_calendars.accessToken
    │   │   └── On 3 refresh failures: CALENDAR_DISCONNECT_ALERT job
    │   │
    │   └── If valid: Call provider API
    │       → Fetch events for next 60 days
    │       → UPSERT calendar_events_cache
    │
Slot generation (when invitee loads booking page):
    → READ calendar_events_cache (no live API call at page load)
    → Calculate available slots from availability schedule
    → Filter out busy cache entries
    → Return slots to booking page
```

**Why caching?** Querying Google Calendar / Outlook on every booking page load would:
1. Require the host's token on every unauthenticated page load (security risk)
2. Hit provider API rate limits at scale
3. Slow the booking page (200ms+ per provider API call)

The 5-minute stale tolerance is acceptable: a calendar event created within 5 minutes before a booking attempt is extremely rare, and the final conflict check inside the booking transaction re-verifies against live data.

---

## Admin Panel Architecture

```
/admin/* routes  →  src/middleware.ts  →  requirePlatformAdmin()
                                              │
                                              ▼
/admin                    Admin Dashboard (stats cards)
/admin/audit-log          Audit Log viewer (audit_logs table)
/admin/users              User list (Better Auth Admin Plugin)
/admin/users/[id]         User detail (ban, impersonate, sessions, emails)
/admin/jobs               Job queue (pgboss.job table, read-only)
/admin/settings           Platform settings (platform_settings singleton)

All pages: Server Components + Drizzle ORM + Better Auth Admin Plugin API
No client-side data fetching for list pages — all rendered server-side
```

---

## Environment Variables — `src/lib/env.ts`

All environment variables are validated at startup via a Zod schema in `src/lib/env.ts`. **Never access `process.env.X` directly** — always import from this file:

```typescript
// src/lib/env.ts
import { z } from 'zod'

const envSchema = z.object({
  // Core
  DATABASE_URL:              z.string().url(),
  BETTER_AUTH_SECRET:        z.string().min(32),
  BETTER_AUTH_URL:           z.string().url(),
  NEXT_PUBLIC_APP_URL:       z.string().url(),
  // Google OAuth + Calendar + Meet
  GOOGLE_CLIENT_ID:          z.string(),
  GOOGLE_CLIENT_SECRET:      z.string(),
  // Microsoft Graph — Outlook calendar + Teams meetings
  MICROSOFT_CLIENT_ID:       z.string(),
  MICROSOFT_CLIENT_SECRET:   z.string(),
  // Zoom
  ZOOM_CLIENT_ID:            z.string(),
  ZOOM_CLIENT_SECRET:        z.string(),
  ZOOM_REDIRECT_URI:         z.string().url(),
  // File storage — 'local' (default, no creds) or 's3' (Cloudflare R2 / AWS S3)
  STORAGE_DRIVER:            z.enum(['local', 's3']).default('local'),
  // S3/R2 credentials — only required when STORAGE_DRIVER=s3
  S3_ACCESS_KEY_ID:          z.string().optional(),
  S3_SECRET_ACCESS_KEY:      z.string().optional(),
  S3_BUCKET:                 z.string().optional(),
  S3_REGION:                 z.string().optional(),
  S3_ENDPOINT:               z.string().optional(),  // blank for AWS S3; set for R2/MinIO/B2
  S3_PUBLIC_URL:             z.string().optional(),  // CDN URL; leave blank to use endpoint URL
  // SMTP transactional email
  SMTP_HOST:                 z.string(),
  SMTP_PORT:                 z.coerce.number().default(587),
  SMTP_SECURE:               z.coerce.boolean().default(false),
  SMTP_USER:                 z.string(),
  SMTP_PASS:                 z.string(),
  SMTP_FROM_EMAIL:           z.string().email(),
  SMTP_FROM_NAME:            z.string(),
  // Encryption key for OAuth tokens stored at rest (AES-256-GCM)
  // Generate: openssl rand -hex 32  (produces exactly 64 hex chars = 32 bytes)
  // Keep separate from BETTER_AUTH_SECRET — rotating auth secret must not rotate encryption key
  ENCRYPT_KEY:               z.string().length(64),
  // Runtime
  NODE_ENV:                  z.enum(['development', 'production', 'test']).default('development'),
})

export const env = envSchema.parse(process.env)
```

If any variable is missing or invalid, `envSchema.parse()` throws a `ZodError` at startup — the server crashes immediately with a clear error message listing the missing vars. This prevents the app from starting in a misconfigured state. The `env` export is tree-shaken in client bundles — never import on the client side (it will throw in the browser).

**Usage everywhere in the codebase:**
```typescript
import { env } from '@/lib/env'
// Use env.DATABASE_URL, env.SMTP_HOST, etc. — never process.env.X
```

---

## Security Architecture

### Token Storage

| Data | Storage | Encryption |
|------|---------|-----------|
| Session tokens | PostgreSQL `sessions.token` | Hashed (not raw) |
| Google OAuth access/refresh tokens | `connected_calendars.accessToken` / `.refreshToken` | AES-256-GCM |
| Zoom OAuth access/refresh tokens | `video_connections.accessToken` / `.refreshToken` | AES-256-GCM |
| Passwords | `accounts` table (Better Auth) | bcrypt (handled by Better Auth) |
| Booking cancel/reschedule tokens | `bookings.cancelToken` / `.rescheduleToken` | Not encrypted (random cuid2, single-use) |

### Input Validation

- Every API route validates input with Zod before any DB operation
- Every Server Action validates input before mutation
- HTML stripped from all text inputs (prevent XSS)
- Booking form email validated with Zod + disposable domain check + MX check

All text inputs go through `src/lib/validators.ts` before hitting Zod — these strip unsafe characters and enforce length limits at the boundary.

```typescript
// src/lib/validators.ts
// Centralized input sanitizers — call these at API/action boundaries before any DB write

export function validateName(name: unknown): string | null {
  if (typeof name !== 'string') return null
  const trimmed = name.trim()
  if (trimmed.length < 1 || trimmed.length > 64) return null
  if (/[\x00-\x1F\x7F]/.test(trimmed)) return null  // no control characters
  return trimmed
}

export function validateUsername(username: unknown): string | null {
  if (typeof username !== 'string') return null
  const trimmed = username.trim().toLowerCase()
  if (!/^[a-z0-9-]{3,30}$/.test(trimmed)) return null
  return trimmed
}

export function validateEmail(email: unknown): string | null {
  if (typeof email !== 'string') return null
  const trimmed = email.trim().toLowerCase()
  if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(trimmed)) return null
  return trimmed
}

export function validateUrl(url: unknown): string | null {
  if (typeof url !== 'string') return null
  try {
    const parsed = new URL(url)
    if (!['http:', 'https:'].includes(parsed.protocol)) return null
    return parsed.toString()
  } catch {
    return null
  }
}

// Strip HTML tags — prevents stored XSS in user-submitted text (event descriptions, bio, etc.)
export function stripHtml(input: string): string {
  return input.replace(/<[^>]*>/g, '').trim()
}
```

**Usage pattern — validate at the boundary, Zod handles the schema:**

```typescript
// In a Server Action — validate raw input before passing to Zod
const cleanName = validateName(input.inviteeName)
if (!cleanName) return { error: 'Invalid name' }

const cleanEmail = validateEmail(input.inviteeEmail)
if (!cleanEmail) return { error: 'Invalid email address' }

// Then Zod for full schema validation
const parsed = bookingSchema.safeParse({ ...input, inviteeName: cleanName, inviteeEmail: cleanEmail })
```

### Rate Limiting

Public API routes (`POST /api/bookings`, `GET /api/slots`) require no authentication — any visitor can hit them. Without a rate limit, a single IP can scrape all available slots or flood the booking endpoint.

Schduled uses an **in-memory fixed-window counter** per IP. No Redis needed. The counter resets every `windowSeconds`. If the Next.js server restarts, counters reset — this is acceptable for the MVP rate limit goal.

```typescript
// src/lib/rate-limit.ts
const store = new Map<string, { count: number; resetAt: number }>()

export function applyRateLimit(
  request: Request,
  config = { limit: 20, windowSeconds: 60 },
): Response | null {
  const ip =
    request.headers.get('x-forwarded-for')?.split(',')[0].trim() ??
    request.headers.get('x-real-ip') ??
    'unknown'

  const now = Date.now()
  const entry = store.get(ip)

  if (!entry || entry.resetAt < now) {
    store.set(ip, { count: 1, resetAt: now + config.windowSeconds * 1000 })
    return null  // allowed
  }

  if (entry.count >= config.limit) {
    return Response.json(
      { error: 'Too many requests. Please try again shortly.' },
      { status: 429 },
    )
  }

  entry.count++
  return null  // allowed
}
```

**Apply in API routes:**

```typescript
// app/api/bookings/route.ts
import { applyRateLimit } from '@/lib/rate-limit'

export async function POST(request: Request) {
  const limited = applyRateLimit(request)
  if (limited) return limited  // returns 429 Response

  // ... rest of handler
}
```

**Rate limit targets:**

| Route | Limit | Why |
|-------|-------|-----|
| `POST /api/bookings` | 10 req / 60s per IP | Booking spam, form abuse |
| `GET /api/slots` | 30 req / 60s per IP | Slot scraping |
| All other public routes | No limit (authenticated or low-traffic) | — |

### Race Condition Prevention

- `pg_advisory_xact_lock(hostUserId + startTime)` inside booking transaction
- `idempotency_keys` prevents duplicate booking POSTs from network retries
- pg-boss `singletonKey` prevents duplicate background jobs per booking

---

## Database Patterns

### Transactions

All multi-row mutations (create booking, cancel booking, update settings) use `db.transaction()` to guarantee atomicity. If any step inside the transaction throws, PostgreSQL rolls everything back automatically.

```typescript
const result = await db.transaction(async (tx) => {
  // All reads and writes inside this callback share one connection
  // and are wrapped in BEGIN ... COMMIT
  const booking = await tx.insert(bookings).values(data).returning()
  await tx.insert(emailOutbox).values(emailRow)
  await tx.insert(auditLogs).values(auditRow)
  return booking
})
```

### `FOR UPDATE` — Row-Level Lock

Use `.for('update')` on a SELECT inside a transaction whenever you need to do a **check-then-write** on the same row. This prevents two concurrent requests from reading the same row, both seeing a "safe" state, and both writing — a classic TOCTOU race condition.

```typescript
// Example: check a booking's current status before cancelling it.
// Without FOR UPDATE, two concurrent cancellation requests could both
// read status='confirmed', both decide it's safe to cancel, and both
// write status='cancelled' — producing a duplicate cancellation email.
const result = await db.transaction(async (tx) => {
  const [booking] = await tx
    .select()
    .from(bookings)
    .where(eq(bookings.id, bookingId))
    .for('update')  // ← acquires row-level lock; held until transaction commits

  if (booking.status !== 'confirmed') {
    throw new Error('Booking is not in a cancellable state')
  }

  await tx
    .update(bookings)
    .set({ status: 'cancelled', cancelledAt: new Date() })
    .where(eq(bookings.id, bookingId))

  return booking
})
```

**When to use `FOR UPDATE`:**

| Situation | Use `FOR UPDATE`? |
|-----------|------------------|
| Cancel / reschedule a booking | Yes — check current status before writing |
| Update notification preferences | No — no concurrent race risk |
| Write to email_outbox inside a booking transaction | No — new INSERT, nothing to lock |
| Claim an email_outbox row for delivery (EMAIL_SEND job) | Yes — multiple worker threads could claim the same row |

**`FOR UPDATE` vs advisory locks:**

- `FOR UPDATE` — locks a **specific row**; use when you know the row ID up front
- `pg_advisory_xact_lock()` — locks by **arbitrary integer key**; use when the lock must span multiple tables (e.g. "no two bookings for this host at this time slot" — there is no single row to lock against)

For the booking creation flow, Schduled uses `pg_advisory_xact_lock(hashOf(hostId + slotTime))` because the row being protected doesn't exist yet at lock time.

---

## Audit Log Patterns

All audit helpers live in `src/lib/db/audit.ts`. The audit log is write-only — never UPDATE or DELETE rows.

### `extractRequestContext(headers)`

Pulls the client IP and user-agent from request headers. Call this at the top of any Server Action or API route handler that writes an audit row, so the log captures where the request came from.

```typescript
// src/lib/db/audit.ts
export function extractRequestContext(headers: Headers) {
  return {
    ipAddress:
      headers.get('x-forwarded-for')?.split(',')[0].trim() ??
      headers.get('x-real-ip') ??
      null,
    userAgent: headers.get('user-agent') ?? null,
  }
}
```

**Usage in a Server Action:**

```typescript
'use server'
import { headers } from 'next/headers'
import { extractRequestContext, DbAudit } from '@/lib/db/audit'

export async function cancelBookingAction(bookingId: string) {
  const reqHeaders = await headers()
  const { ipAddress, userAgent } = extractRequestContext(reqHeaders)

  // ... cancel logic ...

  await DbAudit.log({
    actorUserId: session.user.id,
    actorEmail:  session.user.email,
    action:      'booking.cancelled_by_host',
    targetType:  'booking',
    targetId:    bookingId,
    source:      'web',
    ipAddress,
    userAgent,
  })
}
```

**Usage in an API route:**

```typescript
// app/api/bookings/route.ts
export async function POST(request: Request) {
  const { ipAddress, userAgent } = extractRequestContext(request.headers)
  // pass into audit log as above
}
```

---

### `auditBatch(entries[])`

Use when a **single user action produces multiple audit rows** — for example, signup creates both a `user.signup` event and a `calendar.connected` event in the same flow. A single `db.insert(...).values([...])` is faster and atomic compared to multiple `DbAudit.log()` calls.

```typescript
// src/lib/db/audit.ts
export async function auditBatch(entries: Omit<AuditLogEntry, 'id'>[]): Promise<void> {
  if (entries.length === 0) return
  try {
    await db.insert(auditLogs).values(
      entries.map(e => ({ ...e, id: createId() }))
    )
  } catch (err) {
    // Never throw from audit helpers.
    // Audit failure must NOT roll back the main business transaction.
    console.error('[audit:batch]', err)
  }
}
```

**Usage — signup flow that creates multiple events:**

```typescript
await auditBatch([
  {
    actorUserId: user.id,
    actorEmail:  user.email,
    action:      'user.signup',
    targetType:  'user',
    targetId:    user.id,
    source:      'web',
    ipAddress,
    userAgent,
  },
  {
    actorUserId: user.id,
    actorEmail:  user.email,
    action:      'calendar.connected',
    targetType:  'calendar',
    targetId:    calendarId,
    source:      'web',
    ipAddress,
    userAgent,
  },
])
```

**When to use `auditBatch` vs `DbAudit.log`:**

| Situation | Use |
|-----------|-----|
| Single event from a single action | `DbAudit.log()` |
| Multiple events from one user action (signup, reschedule, onboarding complete) | `auditBatch()` |
| Event fired from a pg-boss worker job | `DbAudit.log()` with `source: 'worker'` |
| System automation with no human actor | `DbAudit.log()` with `source: 'system'`, `actorUserId: null` |

---

## Development Architecture Decision Log

| Decision | Chosen | Rejected | Why |
|----------|--------|---------|-----|
| ORM | Drizzle | Prisma | Thinner runtime, no generated client, SQL-first, schema = TypeScript |
| Job queue | pg-boss | Bull/BullMQ, Inngest | No Redis dep; same DB = atomic job+data creation |
| Auth | Better Auth | NextAuth, Clerk | Better admin plugin, built-in magic link, cleaner TypeScript API |
| Email | Nodemailer + React Email | Resend, Postmark | No vendor lock-in; works with any SMTP provider; self-hosted option |
| Linter | Biome | ESLint + Prettier | 10-50× faster, zero config conflicts |
| ID generation | cuid2 | UUID | URL-safe, shorter, timestamp-embedded, sortable |
| Storage | S3-compatible | Cloudinary | Multi-vendor (AWS/R2/B2/MinIO), presigned uploads, cost control |
