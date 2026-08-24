# User Onboarding

User Onboarding covers the complete authentication and first-run experience — from account creation and sign-in to email verification, password reset, and the guided wizard that takes a new user to their first live booking link. A great onboarding removes friction, builds confidence, and delivers the "aha moment" — the point where the user first understands the product's value.

---

## Overview

Schduled's onboarding has one goal: get the user to a shareable booking link as fast as possible. Every step that doesn't serve that goal is removed.

The full authentication and onboarding sequence covers:
1. Account creation (sign up — email/password, Google OAuth)
2. Sign in (returning users — email/password, Google OAuth, magic link)
3. Email verification (6-digit code for email+password sign-ups)
4. Password reset (forgot password → secure email link → new password)
5. Calendar connection
6. Timezone confirmation
7. First event type setup
8. Booking page preview and link share

Target completion time for new user wizard (steps 5–8): **under 3 minutes** for a motivated user.

---

## User Stories

**New User (Sign Up)**
- As a new user, I want to sign up with Google OAuth, so that I do not have to create and remember a new password. *(MVP)*
- As a new user, I want to sign up with email and password if I prefer not to use OAuth, so that I have full control over my account credentials. *(MVP)*
- As a new user, I want to receive an email verification code immediately after signing up, so that my email address is confirmed before I can start using the app. *(MVP)*
- As a new user, I want my name and photo pre-filled from my Google or Microsoft account, so that I do not have to enter basic profile information manually. *(MVP)*
- As a new user, I want a step-by-step guided setup that takes under 3 minutes, so that I have a shareable booking link the same day I sign up. *(MVP)*
- As a new user, I want to connect my calendar during onboarding, so that my availability is accurate from the very first booking. *(MVP)*
- As a new user, I want to see a live preview of my booking page before sharing it, so that I can confirm it looks right before sending the link to anyone. *(MVP)*
- As a new user, I want to skip optional setup steps and come back to them later, so that I can get to my booking link faster without being blocked by non-essential configuration. *(MVP)*

**Returning User (Sign In)**
- As a returning user, I want to sign in with the same Google account I signed up with, so that I never need a password. *(MVP)*
- As a returning user, I want a "Remember me" option on sign-in, so that I stay logged in for 30 days on my own device without signing in every time. *(MVP)*
- As a returning user, I want to receive a magic link by email if I prefer passwordless sign-in, so that I can access my account without remembering a password. *(MVP)*

**Forgot Password**
- As a user who forgot my password, I want to request a password reset email, so that I can regain access to my account without contacting support. *(MVP)*
- As a user resetting my password, I want the reset link to expire after 60 minutes, so that I know my account is protected if I do not use it immediately. *(MVP)*
- As a user resetting my password, I want all my existing sessions to be signed out after the reset, so that my account is secured if someone else triggered the reset. *(MVP)*

---

## Step 1 — Account Creation

### Sign-Up Methods

| Method | Description |
|--------|-------------|
| Google OAuth | One-click signup with Google account; no password needed |
| Email + Password | Traditional email and password registration |

### Google OAuth Flow
1. User clicks "Sign up with Google"
2. Redirected to Google's OAuth consent screen
3. User approves Schduled access
4. Returned to Schduled — account created instantly
5. Profile name and photo pre-filled from Google account
6. No email verification step required (email already verified by Google)

### Email + Password Flow
1. User enters name, email address, and password
2. Schduled sends a verification email with a 6-digit code
3. User enters code on verification screen
4. Account created and onboarding continues

### Password Requirements
- Minimum 8 characters
- At least 1 uppercase letter
- At least 1 number or special character
- Strength indicator shown in real-time

### Email Validation on Signup

Before creating an account with an email address, Schduled performs two server-side checks:

**1. Disposable Domain Check**
- The email's domain is looked up in the `disposable_email_domains` table (seeded with ~50,000 known throwaway providers: mailinator.com, guerrillamail.com, 10minutemail.com, etc.)
- If the domain is disposable: signup is blocked immediately
- Error shown: "Please use a permanent email address — temporary email services are not allowed."
- Existing accounts with disposable emails are NOT blocked (only new signups)
- The blocklist is refreshed daily via the `DISPOSABLE_EMAILS_REFRESH` pg-boss cron job

**2. MX Record Check**
- After the disposable domain check passes, a DNS MX record lookup is performed for the email's domain
- If no MX record exists (domain cannot receive email): signup is blocked
- Error shown: "That email domain doesn't appear to be able to receive email. Please double-check your address."
- This catches typos like `@gmial.com` or `@hotmial.com` before the user fills out the entire onboarding wizard only to get stuck at verification

> Both checks happen server-side on the sign-up form submission — never on the client. OAuth sign-ups skip the MX check (Google/Microsoft have already verified the email).

### Email Verification Code — Details
- Code is 6 digits, valid for **15 minutes** from the time of sending
- If code expires: "Your verification code has expired. Click here to resend."
- Resend button available after 60 seconds (maximum 3 resends per session)
- Max attempts before lockout: 5 wrong codes → account creation blocked for 10 minutes
- Code is single-use: once entered correctly, it cannot be reused

### Terms and Privacy
- Checkbox: "I agree to the Terms of Service and Privacy Policy"
- Required before account creation proceeds
- Links open in new tab (do not interrupt the onboarding flow)

---

## Step 2 — Calendar Connection

The most critical onboarding step. Without a connected calendar, Schduled cannot show real availability or write bookings.

### Calendar Provider Selection Screen
User sees a clean screen with calendar provider options:

| Provider | Notes |
|----------|-------|
| Google Calendar | Most common; recommended for Gmail users |
| Outlook / Office 365 | For Microsoft 365 work and school accounts |
| Apple Calendar / iCloud | *(Post-MVP — Phase 2)* For iPhone/Mac users using iCloud calendar |
| Skip for now | Allowed but discouraged — shows a warning |

### OAuth Connection Flow (Google / Outlook)
1. User clicks their calendar provider
2. Opens provider OAuth window
3. User logs in and approves calendar permissions
4. Returned to Schduled — connection confirmed
5. Schduled lists all calendars found on the account
6. User selects:
   - **Which calendars to check for conflicts** (toggle per calendar)
   - **Which calendar to add new bookings to** (radio selection)
7. Connection status shows green: "✓ Google Calendar connected"

### Apple Calendar (iCloud) Connection *(Post-MVP — Phase 2)*
> Apple Calendar connection requires an app-specific password (no standard OAuth). This is a Phase 2 feature due to protocol complexity.

1. User clicks "Apple Calendar"
2. Shown instructions: "Go to appleid.apple.com → Security → App-Specific Passwords → Generate"
3. User enters iCloud email and the generated app-specific password
4. Schduled connects via CalDAV and lists available calendars
5. User selects which calendars to check and write to

### Why Calendar Connection Matters (Shown to User)
A brief one-line explanation displayed during this step:
> "Schduled checks your calendar so invitees only see times when you're actually free — no more double bookings."

### Skip Option
- User can skip calendar connection via "I'll connect later" button
- **Booking pages are deactivated immediately** when calendar is skipped — invitees visiting the booking URL see "This calendar is currently unavailable" until the host connects a calendar
- This prevents the phantom availability problem: without a real calendar, Schduled cannot check for conflicts, so accepting bookings would risk double-bookings the host only discovers when checking their calendar
- Warning shown with concrete example:
  > "Without a connected calendar, you may get booked during a dentist appointment — and only find out when you check your calendar. Your booking pages will be paused until you connect."
- Dashboard shows a persistent banner: "⚠️ Your booking pages are paused — connect a calendar to start accepting bookings"
- "Connect Calendar" shortcut button in the banner takes the user directly to the calendar connection screen
- Booking pages automatically re-activate the moment a calendar is connected

---

## Step 3 — Timezone Confirmation

### Auto-Detection
- Schduled detects the user's timezone from their browser automatically
- Shows detected timezone: "We detected your timezone as Asia/Kolkata (IST, UTC+5:30)"
- User confirms with "Yes, that's correct" or changes it

### Manual Selection
- If timezone is wrong or not detected, user selects from a searchable dropdown
- Dropdown includes all IANA timezones with city names
- Current time preview updates as user selects: "Your current time: 3:45 PM"

### Why It Matters (Shown to User)
> "Your timezone ensures your availability is shown correctly to people around the world."

---

## Step 4 — First Event Type Setup

Guided creation of the user's first event type. Keeps it simple — only the essential fields, with smart defaults pre-filled.

### Fields Shown in Onboarding (Simplified)

| Field | Default | User Action |
|-------|---------|-------------|
| Event name | "30-Minute Meeting" | Edit or keep |
| Duration | 30 minutes | Select from: 15 / 30 / 45 / 60 / Custom |
| Location | Google Meet (if Google connected) | Select location type |
| Available hours | Mon–Fri, 9:00 AM – 5:00 PM | Confirm or adjust |

### What Is Hidden During Onboarding
Advanced settings are hidden to avoid overwhelming new users:
- Buffer times
- Minimum notice period
- Custom questions
- Booking window
- Date overrides

These are accessible after onboarding from the Event Type settings.

### Availability Preview
After confirming hours, a mini calendar preview shows the first few available slots. This gives instant visual confirmation that the setup is working correctly.

---

## Step 5 — Booking Page Preview and Share

The final onboarding step shows the user their live booking page and gives them their link.

### Booking Page Preview
- Full-screen preview of the booking page as an invitee would see it
- Shows host name, profile photo, event type name, duration, and available slots
- "This is what your invitees will see" label

### Your Booking Link
- Displays the user's booking URL: `schduled.com/yourname/30-minute-meeting`
- **Copy Link** button — one click to copy to clipboard
- **Share via Email** — opens default email client with link pre-filled
- **Share on LinkedIn** — opens LinkedIn share dialog (optional)

### "You're all set!" Confirmation
- Checkmark animation and "You're ready to accept bookings!"
- Clear CTA: "Go to Dashboard" — takes user to the main Schduled dashboard

---

## Post-Onboarding: Dashboard First Visit

First time on the dashboard after onboarding, user sees a brief checklist of recommended next steps:

| Step | Status |
|------|--------|
| ✅ Connect your calendar | Done during onboarding |
| ✅ Create your first event type | Done during onboarding |
| ☐ Add a profile photo | Link to Profile Settings |
| ☐ Share your booking link | Link to copy booking URL |
| ☐ Set up a reminder email | Link to Notifications settings |

Checklist dismissible once all steps complete or manually dismissed.

---

## Re-Onboarding (Returning Incomplete Users) *(Post-MVP — Phase 2)*

> **MVP behaviour:** Users who close mid-onboarding see a simple "Finish setting up your account" link on the dashboard. Clicking it takes them to the onboarding step they left off at — no separate flow needed.
>
> The full re-onboarding flow (step-aware resume, progress-aware banner, skip-step tracking) is Phase 2. A simple link is sufficient at launch and avoids building a complex state machine before knowing how many users actually drop off mid-onboarding.

---

## Onboarding Progress Indicator

Throughout onboarding, a progress bar or step indicator is shown — e.g., "Step 1 of 5: Connect your calendar" with filled dots for completed steps and empty dots for remaining steps.

- Shows current step and total steps
- Clicking a previous step allows going back
- No skipping forward (steps must be completed in order, except the optional "skip calendar" path)

---

## Error States During Onboarding

| Error | Message Shown | Recovery |
|-------|--------------|----------|
| OAuth denied (user cancelled) | "Calendar not connected. You can connect later in Settings." | Continue without calendar |
| Google account already registered | "An account already exists with this Google account. Sign in instead." | Link to sign in |
| Email already registered | "That email is already registered. Sign in or reset your password." | Link to sign in / forgot password |
| Calendar connection failed (API error) | "We couldn't connect your calendar. Try again or skip for now." | Retry or skip |
| iCloud app-specific password wrong | "Incorrect app-specific password. Please try again." | Retry with correct password |
| Verification code expired | "Your code has expired. Please request a new one." | Resend code |
| Verification code wrong (5× attempts) | "Too many incorrect attempts. Please wait 10 minutes." | Wait and retry |

---

## Authentication — Sign-In Flow (Returning Users)

Sign-in is separate from onboarding but lives on the same `/sign-in` page. Returning users are routed here after their first session.

### Sign-In Methods

| Method | Description |
|--------|-------------|
| Google OAuth | "Sign in with Google" — one click, no password |
| Email + Password | Enter registered email and password |
| Magic Link (passwordless) | Enter email → receive a one-click sign-in link via email |

### Email + Password Sign-In Flow
1. User enters email and password
2. Schduled verifies credentials server-side (bcrypt password comparison)
3. On success: session created; user redirected to dashboard
4. On failure: "Incorrect email or password" (no indication which is wrong — security best practice)

### Google OAuth Sign-In Flow
1. User clicks "Sign in with Google"
2. Redirected to Google's OAuth screen (Google may remember the user, making this one-click)
3. On success: Schduled matches the Google email to an existing account
4. If no account found: "No account found with this Google account. Sign up instead." — link to sign-up

### Magic Link (Passwordless) Sign-In Flow
1. User clicks "Email me a sign-in link"
2. Enters their registered email address
3. **Server checks if the user is banned before sending** — if banned and ban has not expired, the request is silently accepted (no error shown, no email sent). This prevents a banned user from discovering they are banned by probing the magic link endpoint.
4. Schduled sends an email with a secure one-click link (valid for 10 minutes, single-use)
5. User clicks the link → instantly signed in; link immediately invalidated
6. If link is expired: "This sign-in link has expired. Request a new one." → re-enter email
7. Use case: User forgot their password; user prefers not to manage passwords; shared/public device where typing a password is inconvenient

### Remember Me
- Checkbox on the sign-in form: "Remember me on this device"
- **Checked (default on trusted devices):** Session persists for 30 days; no re-login required
- **Unchecked:** Session expires when browser is closed (session cookie)
- Sessions are stored server-side; "Remember me" sets a durable refresh token in a secure `HttpOnly` cookie

---

## Forgot Password / Password Reset

For email+password users who have forgotten their password.

### Reset Flow
1. User clicks "Forgot your password?" on the sign-in page
2. Enters their registered email address
3. If email exists: password reset email sent immediately
4. If email not found: same success message shown ("Check your inbox") — prevents email enumeration
5. User receives email with a **secure one-time reset link** (valid for 60 minutes)
6. User clicks link → taken to "Set New Password" page
7. Enters new password (meets requirements) + confirms it
8. On success: password updated; all existing sessions invalidated; user signed in automatically
9. Confirmation: "Your password has been reset. You're now signed in."

### Reset Email Contents
- Subject: "Reset your Schduled password"
- Body: "We received a request to reset your password. Click the button below within 60 minutes."
- Large "Reset Password" button with the secure token link
- "If you didn't request this, you can safely ignore this email."
- No password shown in the email

### Reset Link Security
- Token is a cryptographically random 256-bit string (URL-safe base64)
- Stored as a hash in the database (not the raw token)
- Single-use: consumed on first visit to the reset page
- Expires after 60 minutes regardless of use
- On expiry: "This link has expired. Request a new password reset."

### Password Reset Limits
- Maximum 3 reset requests per email per hour to prevent abuse
- If limit reached: "Too many reset requests. Please try again in 1 hour."

---

## Two-Factor Authentication (2FA) — Login Challenge *(Post-MVP — Phase 2)*

When a user has 2FA enabled (configured in [user-profile-settings.md](user-profile-settings.md)), the login flow adds a second step.

> **Why Phase 2:** 2FA adds authentication complexity and support burden (locked-out users, backup code recovery) before product-market fit. Email/password + OAuth is secure enough at launch. Enable after user base is established.

### Login with 2FA — TOTP (Authenticator App)
1. User enters email + password (or signs in via OAuth)
2. Credentials are valid → instead of proceeding to dashboard, shown a 2FA challenge screen
3. Screen shows: "Enter the 6-digit code from your authenticator app"
4. User opens Google Authenticator / Authy, finds the Schduled entry
5. Enters the current 6-digit TOTP code (regenerates every 30 seconds)
6. On valid code: session created; user enters dashboard
7. On invalid code: "Incorrect code. Please try again." (up to 5 attempts)
8. After 5 failed attempts: account locked for 15 minutes

### Login with 2FA — Backup Code
- "Can't access your authenticator app?" link on the 2FA challenge screen
- User enters one of their 8 downloaded backup codes
- Backup codes are one-time use: used code is immediately invalidated
- On valid backup code: session created; warning shown: "You used a backup code. You have X codes remaining. Consider regenerating your backup codes."
- If all backup codes are used: user must contact support for account recovery

### 2FA — SMS (Post-MVP)
1. After valid password: "We sent a code to your phone ending in \*\*\*\*1234"
2. User enters 6-digit SMS code
3. Code valid for 5 minutes; resend available after 60 seconds
4. On valid code: session created

### Trusted Devices
- After successful 2FA login, option: "Trust this device for 30 days"
- If trusted: 2FA challenge skipped on this device for 30 days
- Trusted device list visible and revocable in Profile & Settings → Security → Active Sessions

---

## Session Management

### Session Lifecycle

| Event | Behavior |
|-------|---------|
| Sign in (remember me on) | Session valid 30 days; refresh token rotates on use |
| Sign in (remember me off) | Session ends when browser closes |
| Session expiry | Redirect to sign-in page with message: "Your session has expired. Please sign in again." |
| Password changed | All existing sessions invalidated immediately |
| 2FA enabled/disabled | All existing sessions invalidated (security measure) |
| Account deleted | All sessions invalidated immediately |

### Refresh Token Rotation *(Post-MVP — Phase 2)*
- Better Auth handles the basic session lifecycle above — that is sufficient for MVP
- Full refresh token rotation (issuing a new refresh token on every use and detecting reuse as a theft signal) is security hardening, not a launch requirement
- Add in Phase 2 once there are real users whose accounts need protecting

### Active Sessions (Managed in Settings) *(Post-MVP — Phase 2)*
- Per-device session list (device type, browser, location, last active) is not required at launch
- Better Auth's `session.revokeAll()` call on password change is sufficient for MVP — it invalidates all sessions when the user changes their password
- Full session management UI (list all devices, revoke individual sessions, "sign out all other devices") ships in Phase 2

---

## Account Lockout & Security

### Failed Login Attempts
- After **5 consecutive failed password attempts** for the same email: account temporarily locked
- Lock duration: **15 minutes** (exponential backoff on repeat lockouts)
- User notified via email: "We noticed several failed sign-in attempts. Your account is temporarily locked."
- Email includes: time of attempts, approximate IP/location, link to reset password if this wasn't them

### Suspicious Login Detection *(Post-MVP — Phase 2)*
- New-device / new-location detection requires storing device fingerprints and IP geolocation — meaningful engineering work that isn't required for a working product at launch
- Add in Phase 2 after accumulating real user data to establish what "normal" looks like per account
- MVP security relies on: rate limiting on login endpoint, account lockout after 5 failed attempts, and Better Auth's built-in protections

### OAuth Account Linking
When a user tries to sign in with a social provider but the same email already exists in Schduled via a different method:
- **Email account + tries Google OAuth with same email:** "An account exists with this email. Sign in with your email and password, then connect Google in Settings."
- Accounts are NOT auto-merged to prevent account takeover attacks

---

## Logout

### Sign Out
- Available from the top-right user menu → "Sign out"
- Action: current session token invalidated server-side; access + refresh cookies cleared
- Redirected to the sign-in page
- No confirmation dialog for single sign-out (immediate)

### Sign Out All Devices
- Available in Profile & Settings → Security → "Sign out of all devices"
- Requires password confirmation before executing
- All sessions and refresh tokens invalidated
- Useful when: device lost or stolen, suspected account compromise

---

## Reference Implementations

| App | Sign-Up Methods | Onboarding Steps | Apple Calendar in Onboarding | Timezone Step | Post-Onboarding Checklist | Skip Calendar Option |
|-----|----------------|-----------------|------------------------------|---------------|--------------------------|----------------------|
| **Calendly** | Google, Microsoft, Email | Sign-up → calendar connect → availability → first event type → share link | ❌ Dropped Aug 2024 | ❌ No dedicated step — timezone set in profile | ❌ No checklist | ❌ No — must connect calendar to proceed |
| **Cal.com** | Google, GitHub, Email | Similar to Calendly; open source so customisable | ✅ Yes — iCloud CalDAV | ❌ No dedicated step | ❌ No | ✅ Yes |
| **SavvyCal** | Google, Email | Short: profile → calendar → availability → link | ✅ Yes | ❌ No | ❌ No | ✅ Yes |
| **Chili Piper** | SSO / Salesforce OAuth (B2B focused) | Guided setup for admin; not a self-serve consumer onboarding | ❌ No | ❌ No | ❌ No | N/A |
| **HubSpot Meetings** | Via HubSpot account | Connect Google/Outlook calendar; set availability; link auto-created | ❌ No | ❌ No | ❌ No | ❌ No |
| **Schduled** | Google OAuth, Magic Link, Email + Password *(all MVP)* | 5 steps: account → calendar → timezone → first event type → share link | ✅ **Phase 2 — iCloud CalDAV** (CalDAV requires app-specific passwords, lacks standard OAuth, complex protocol — Post-MVP) | ✅ **Dedicated timezone confirmation step** with auto-detect | ✅ Post-onboarding checklist on first dashboard visit | ✅ Skip allowed with clear warning about double-booking risk |

---

## MVP Scope

**In MVP — Onboarding:**
- Google OAuth and Email + Password signup
- Google Calendar and Outlook connection during onboarding
- Timezone auto-detection and confirmation
- First event type creation (simplified 4-field form)
- Booking page preview with copyable link
- Post-onboarding dashboard checklist

**In MVP — Authentication:**
- Email + Password sign-in with "Remember me"
- Google OAuth sign-in
- Magic link (passwordless) sign-in
- Forgot password / reset password flow (email link, 60-minute expiry)
- Email verification for new accounts (6-digit code, 15-minute expiry, resend)
- Account lockout after 5 failed attempts (15-minute lock)
- Session expiry with redirect to sign-in
- Logout (current device)
- OAuth account collision detection (no auto-merge)

**Post-MVP:**
- Apple Calendar / iCloud connection (CalDAV with app-specific password) *(Phase 2 — complex protocol, lacks OAuth)*
- 2FA login challenge (TOTP authenticator app)
- 2FA backup codes
- SMS 2FA
- Trusted devices (skip 2FA for 30 days)
- Suspicious login detection and email alert
- Active sessions list and per-session sign-out
- Refresh token rotation (security hardening)
- Re-onboarding flow for incomplete signups
- Social share (LinkedIn, Twitter) of new booking page
- Team invitation during onboarding (for team accounts)


---

## Audit Logging

Every sign-up, sign-in, sign-out, and password reset event is written to the `audit_logs` table automatically. This enables the admin panel audit log viewer to show the full account lifecycle per user.

| Event | Audit Action | source |
|-------|-------------|--------|
| New account created | `user.signup` | `'web'` |
| Successful sign-in | `user.signin` | `'web'` |
| Sign-out | `user.signout` | `'web'` |
| Password reset completed | `user.password_reset` | `'web'` |

All audit records include `actorUserId`, `actorIp`, `source: 'web'` (all auth events are Server Actions or Next.js API routes with a logged-in session context). See `database-schema.md` for `auditSourceEnum`.

---

## Tech Stack

- **Better Auth** — handles all sign-up methods (email/password, Google OAuth), magic link sign-in, email verification codes, session creation, and account lockout. The admin plugin exposes user management to custom Next.js admin pages. See **Better Auth Configuration** section below for required config options.
- **Next.js App Router** — onboarding is a 5-step wizard built as sequential pages. Middleware checks `onboardingDone` on each request and redirects incomplete users back to their current step.
- **PostgreSQL + Drizzle ORM** — stores the user account, current `onboardingStep`, and `onboardingDone` flag. Drizzle schema extends Better Auth's built-in users table with Schduled-specific fields (username, timezone, onboarding progress).
- **`disposable_email_domains` table** — seeded blocklist of ~50,000 throwaway email provider domains. Checked on every email+password signup before account creation. Refreshed daily via `DISPOSABLE_EMAILS_REFRESH` pg-boss cron.
- **DNS MX check** — Node.js `dns.resolveMx()` verifies the signup email domain can receive mail before creating the account. Catches domain typos. Skipped for OAuth sign-ups.
- **pg-boss** — schedules the welcome email (`EMAIL_SEND` job) immediately after signup so delivery is async and retried on SMTP failure without blocking the onboarding response. Also schedules `DISPOSABLE_EMAILS_REFRESH` cron daily.
- **`audit_logs` table** — every sign-up, sign-in, and password reset event writes an immutable row. Visible in the admin panel audit log.
- **Nodemailer (SMTP)** — delivers the email verification code during sign-up and the welcome email after onboarding completes (via `EMAIL_SEND` job).
- **React Email** — renders the verification code email, password reset email, and welcome email as styled React components compiled to HTML before sending via Nodemailer.

---

## Better Auth Configuration

The auth config lives in `src/lib/auth.ts`. Three settings are required — each closes a specific security or data gap.

### Required Configuration Options

| Option | What it does | What breaks without it |
|--------|-------------|------------------------|
| `overrideUserInfoOnSignIn: true` | Re-fetches Google name + photo on every sign-in | User's Schduled profile photo never updates when they change their Google photo |
| `session.cookieCache.maxAge: 60` | Caches session in the cookie for 60s, avoiding a DB query on every request | Every page load hits the DB for a session lookup; also: bans never propagate without this bound |
| Magic link ban check | Suppresses link delivery to banned users | Banned users can still receive magic links and sign in without error |
