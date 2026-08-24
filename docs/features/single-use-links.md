# Single Use Links — Feature Spec

**Phase:** 2 (post-MVP)
**Priority:** P1 — high value for B2B / paid users

---

## What It Is

A **single use link** is a unique, one-time booking URL that the host generates and sends to a specific person. Once that person books a meeting, the link is permanently invalidated and cannot be used again.

Contrast with a regular booking link:

| | Regular link | Single use link |
|---|---|---|
| URL pattern | `/{username}/{slug}` | `/book/{token}` |
| Who can use it | Anyone, unlimited times | One specific person, once |
| Expiry | Never | Immediately after 1 booking |
| Use case | Public scheduling page | Private, targeted invitations |

---

## User Story

> As a host, I want to generate a private booking link for a specific person so that only they can book that meeting slot and the link cannot be shared or reused.

---

## Design

### Generate flow (host side)

1. Host opens an event type
2. In the `⋮` dropdown on the event type card: **"Create single use link"**
3. A dialog opens showing the generated URL with a **Copy** button
4. Host sends the URL to the specific invitee via email/chat

### Booking flow (invitee side)

1. Invitee opens `/book/{token}`
2. Page looks identical to the regular booking calendar
3. After booking is confirmed → link is **immediately marked as used**
4. If anyone (including the same person) tries to open the used link:
   - Show an elegant **"This link has expired"** page
   - Offer: "If you need to schedule a meeting, contact {hostName}"

### Link expiry states

| State | What shows |
|---|---|
| `active` | Normal booking calendar |
| `used` | "This link has already been used" page |
| `expired` (past expiry date) | "This link has expired" page |
| Not found | 404 page |

---

## Database Schema

New table: `single_use_link`

```sql
CREATE TABLE single_use_link (
  id            TEXT PRIMARY KEY DEFAULT cuid2(),
  host_user_id  TEXT NOT NULL REFERENCES "user"(id) ON DELETE CASCADE,
  event_type_id TEXT NOT NULL REFERENCES event_type(id) ON DELETE CASCADE,
  token         TEXT NOT NULL UNIQUE,          -- URL-safe random token (32 chars)
  label         TEXT,                          -- optional: "For John Smith"
  status        TEXT NOT NULL DEFAULT 'active', -- active | used | expired
  expires_at    TIMESTAMP,                     -- NULL = never expires
  used_at       TIMESTAMP,
  booking_id    TEXT REFERENCES booking(id),  -- set after use
  created_at    TIMESTAMP NOT NULL DEFAULT now()
);

CREATE INDEX single_use_link_token_idx ON single_use_link(token);
CREATE INDEX single_use_link_host_idx ON single_use_link(host_user_id);
```

Drizzle schema location: `db/schema/single-use-links.ts`

---

## API Routes

### `GET /book/[token]` (public page)
- Load `single_use_link` by token
- If `status !== 'active'` → show expired/used page
- If `expires_at` is set and past → mark as `expired`, show expired page
- Otherwise → render identical booking calendar (pass `singleUseLinkId` to booking API)

### `POST /api/bookings` (extend existing)
- Accept optional `singleUseLinkId` in body
- After successful booking → update `single_use_link` set `status = 'used'`, `used_at = now()`, `booking_id = <new booking id>`
- This must happen in the same transaction as booking creation (or immediately after with idempotency)

### `POST /api/single-use-links` (authenticated — host only)
- Body: `{ eventTypeId, label?, expiresAt? }`
- Generate cryptographically random token: `crypto.randomBytes(24).toString('base64url')`
- Insert into `single_use_link` table
- Return: `{ url: "https://app.com/book/{token}", token }`

### `GET /api/single-use-links?eventTypeId=` (authenticated)
- List all links for an event type
- Shows status, created date, used date, label

### `DELETE /api/single-use-links/[token]` (authenticated)
- Mark link as `expired` (soft delete)

---

## UI Components

### EventTypeCard — "Create single use link" in dropdown
```
⋮ More
  ├── Edit
  ├── Copy link
  ├── Create single use link   ← NEW
  ├── Duplicate
  └── Delete
```

### SingleUseLinkDialog
- Dialog that opens after generating
- Shows: the URL + Copy button
- Optional label field ("Who is this for?" e.g. "John Smith")
- Optional expiry date picker
- List of previously generated links for this event type (with status badges)

### `/book/[token]/expired` page
```
[Clock icon]
This link has expired

This scheduling link was for a one-time meeting
and has already been used (or expired).

If you'd like to schedule time with {hostName},
please reach out to them directly.
```

---

## Token Generation

```ts
import crypto from 'crypto'

function generateSingleUseToken(): string {
  return crypto.randomBytes(24).toString('base64url') // 32-char URL-safe string
}
```

- `base64url` is URL-safe (no `+`, `/`, `=`)
- 24 bytes = 192 bits of entropy — effectively unguessable

---

## Edge Cases

| Case | Handling |
|---|---|
| Two people open the link simultaneously | First booking wins (DB unique constraint on booking insert); second person sees "slot unavailable" |
| Host tries to book their own single use link | Allowed — booking confirms, link marked used |
| Booking cancelled after single use link was used | Link stays `used` — do NOT reactivate (prevents abuse) |
| Event type deleted | `ON DELETE CASCADE` removes all its single use links |

---

## Build Order (Phase 2)

1. DB migration — add `single_use_link` table
2. `db/schema/single-use-links.ts` + relations
3. `POST /api/single-use-links` — generate token
4. `GET /api/single-use-links` — list for event type
5. `DELETE /api/single-use-links/[token]` — deactivate
6. `app/(booking)/book/[token]/page.tsx` — public booking page (reuse BookingCalendar)
7. `app/(booking)/book/[token]/expired/page.tsx` — expired state page
8. Extend `POST /api/bookings` — accept + mark `singleUseLinkId`
9. `SingleUseLinkDialog` component
10. Add "Create single use link" to EventTypeCard dropdown
11. Add single use links list to event type settings page
