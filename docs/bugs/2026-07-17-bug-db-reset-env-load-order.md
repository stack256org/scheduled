# Bug: `pnpm db:reset` fails with "Invalid environment variables"

**What's broken:** Running `pnpm db:reset` throws immediately with Zod
validation errors claiming `DATABASE_URL`, `APP_SECRET`, and
`NEXT_PUBLIC_APP_URL` are `undefined`, even though all three are correctly set
in `.env`.

**Where:** `db/reset.ts` (the `tsx db/reset.ts` half of the `db:reset` script),
in combination with `lib/env.ts` which validates `process.env` at module load.

**How it was found:** User ran `pnpm db:reset` on a working tree with a
populated `.env`; the error listed the three required vars as missing.

**Root cause:** `db/reset.ts` statically imported `@/lib/env` on line 3, then
called `process.loadEnvFile()` on line 6. ES module static imports are hoisted
and their modules fully evaluated *before* any of the importing module's body
runs. So `lib/env.ts` ran `envSchema.safeParse(process.env)` before
`process.loadEnvFile()` had a chance to populate `process.env` from `.env` —
the vars were genuinely absent at validation time.
