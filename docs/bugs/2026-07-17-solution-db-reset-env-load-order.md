# Solution: `pnpm db:reset` env load-order fix

**What changed:** `db/reset.ts` — replaced the static
`import { env } from "@/lib/env"` with a dynamic `await import("@/lib/env")`
placed *after* the `process.loadEnvFile()` call.

```ts
if (existsSync(".env")) {
  process.loadEnvFile();
}

// Dynamic import so lib/env validates process.env *after* loadEnvFile above;
// a static import is hoisted and would run validation before .env is loaded.
const { env } = await import("@/lib/env");
```

**Why it fixes the root cause:** A dynamic `import()` is evaluated at the point
it appears in the module body, not hoisted. By the time `lib/env.ts` runs its
`safeParse(process.env)`, `process.loadEnvFile()` has already loaded `.env` into
`process.env`, so all required vars are present and validation passes. Top-level
`await` is valid here since the file is an ES module.

**How it was verified:** Ran `pnpm db:reset` — it dropped the public/drizzle
schemas ("Database reset complete.") and `drizzle-kit migrate` then reported
"migrations applied successfully!". No env validation error.
