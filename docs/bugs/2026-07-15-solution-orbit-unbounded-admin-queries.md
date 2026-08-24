# Solution: unbounded/client-paginated Orbit admin queries

**Fixed:** 2026-07-15

**Files changed:**
- `app/(orbit)/orbit/users/page.tsx` — now reads `{ q, filter, page }` from `searchParams`, builds a Drizzle `WHERE` clause (search across name/email, status filter), and runs a real `.limit(PAGE_SIZE).offset(...)` query alongside a `count()` query for the total.
- `app/(orbit)/orbit/audit/page.tsx` — same pattern, plus a shared filter-building helper (`lib/audit-query.ts`) so the page query and the CSV/JSON export action can never drift out of sync on what "the current filters" means.
- `components/orbit/users-table.tsx` / `components/orbit/audit-table.tsx` — converted from stateful client components (owning search/filter/page state and slicing the full array in the browser) to presentational components that just render the current page and link to `?page=N` for navigation — mirroring `app/(app)/bookings/page.tsx`'s established pattern exactly (same debounced-search component shape, same `PaginationLink href={pageHref(p)}` pattern).
- `components/orbit/users-search.tsx`, `components/orbit/audit-filters.tsx` (new) — URL-syncing search/filter controls, replacing the removed local `useState`.
- `app/actions/orbit-audit.ts` (new) — a dedicated `exportAuditLogsAction` so CSV/JSON export still works against the full filtered set (capped at 5,000 rows, with a toast if truncated) without requiring every row to be resident on the page itself.

**Why this fixes the root cause:** Both pages now fetch only the current page's rows from Postgres, with the browser never holding more than one page's worth of data. Bulk actions (suspend/delete) on the Users page still operate correctly since they only ever needed the *currently rendered* page's rows, not the full dataset.

**How it was verified:** Live, not just typechecked. Created a temporary admin session, drove both pages with Playwright:
- Confirmed the search box and filter dropdown update the URL (`?q=...`, `?filter=admins`) rather than local state.
- Confirmed `Page 1 of 1 · 5 users` / `Page X of Y · N logs` render from real server-computed totals.
- Downloaded a real CSV export via the new export action and confirmed its contents.

`tsc --noEmit` clean throughout.
