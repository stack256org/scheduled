# Bug: separate `/orbit` admin panel doesn't fit the self-hosted single-admin model

**Found:** 2026-07-16, raised directly by the project owner while reviewing the app for open-source self-hosting readiness.

**Where:**
- `app/(orbit)/` — the entire admin panel: overview, users, users/[id], audit, queues, email, settings, its own `layout.tsx`.
- `app/(orbit-public)/orbit/login/` — a second, separate login page and form.
- `app/api/orbit/verify/route.ts` — a post-Google-OAuth role check specific to the admin login.
- `components/admin/` (`admin-sidebar.tsx`, `admin-mobile-nav.tsx`, `orbit-page-header.tsx`) and `components/orbit/*` — the panel's own shell + page components.
- `middleware.ts` — an `ADMIN_PREFIXES = ["/orbit"]` branch redirecting to `/orbit/login`.
- `components/scaffold/sidebar-nav.tsx` — a conditional "Admin Panel" shortcut link.
- `app/api/newsletter/route.ts`, `app/(orbit)/orbit/subscribers/`, `components/orbit/subscribers-table.tsx`, `app/actions/subscribers.ts`, the `newsletterSubscriber` DB table, and the `NewsletterForm` block in `components/landing/landing-footer.tsx` — an unrelated newsletter/subscribers feature that the project owner also asked to drop entirely (not part of the admin panel, but decided in the same pass).

**What's broken (product-level, not a code defect):**
Schduled shipped with two fully separate experiences layered onto one account: `/dashboard` (the regular app) and `/orbit` (a parallel admin panel with its own layout, its own sidebar, and its own login page at `/orbit/login`, itself routing through a dedicated `/api/orbit/verify` post-auth check). For a self-hosted, single-admin deployment — the model this project actually targets, per `INITIAL_ADMIN_EMAIL` bootstrap and the single `role: "user" | "admin"` column on the shared `user` table — that separation is pure overhead:

- An admin account was already a full regular `user` row; `/orbit/login` authenticated through the *same* Better Auth client as `/login`, differing only in its post-login redirect. The "two panels" framing was cosmetic, not architectural.
- It doubled the surface area for anything auth-related (two login forms, two post-auth redirect paths, two places sign-out could point to) for zero actual isolation benefit — an admin was never anything other than the same account with `role: "admin"`.
- It duplicated two settings screens that already existed correctly elsewhere: an "Account" password card at `/orbit/settings#account` (real one already at `/profile/security`) and an "Appearance" theme picker at `/orbit/settings#appearance` (the header `ThemeToggle` already existed, just without a "System" option).
- The newsletter/subscribers feature (public footer signup form → `newsletter_subscriber` table → `/orbit/subscribers` admin viewer) had no product use for a self-hosted single-admin deployment and was cut alongside the panel.

**How it was found:** Direct product-direction request from the project owner, following a multi-round planning discussion that produced `docs/ADMIN-PANEL-REMOVAL-PLAN.md` (finalized v3) — see that file for the full locked-in scope and the alternatives considered (an invite-based multi-admin model was explored and explicitly rejected in favor of keeping the existing single-admin bootstrap unchanged).

**Root cause:** The admin panel was originally built as a structurally separate app (own route groups, own layout, own login) instead of an access-control concern layered onto the one app that already existed — appropriate for a multi-tenant SaaS with a real admin/user trust boundary, but unnecessary indirection for a single-admin, self-hosted deployment where the "admin" is just the operator's own account.
