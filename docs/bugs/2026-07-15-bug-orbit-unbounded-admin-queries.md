# Bug: unbounded/client-paginated Orbit admin queries

**Found:** 2026-07-15, flagged in `PROJECT_REVIEW.md`'s Performance Review and Biggest Weaknesses sections.

**Where:** `app/(orbit)/orbit/users/page.tsx` and `app/(orbit)/orbit/audit/page.tsx`.

**What's broken:**
- `/orbit/users` ran `db.select(...).from(user).orderBy(desc(user.createdAt))` with **no `.limit()` at all** — every registered user's row shipped to the browser on every page load, then `components/orbit/users-table.tsx` sliced it client-side for display.
- `/orbit/audit` capped the query at the most recent 500 rows server-side, but had **no further server-side pagination** — an admin could never page past row 500 of the audit log, and all 500 rows were still fetched and shipped on every load regardless of what the admin was actually looking at.
- Both pages were inconsistent with the main user-facing Bookings page (`app/(app)/bookings/page.tsx`), which already correctly implements URL-driven server-side `.limit()/.offset()` pagination with a `count()` query.

**How it was found:** Explicitly called out in the generated `PROJECT_REVIEW.md` (§13 Performance Review, §24 Technical Debt) after a codebase-wide review; confirmed by reading both page files directly.

**Root cause:** These two admin pages were built by fetching the full (or a large fixed slice of the) dataset server-side and delegating search/filter/pagination entirely to client-side JS, rather than following the URL-searchParams-driven server pagination pattern already established on the Bookings page.
