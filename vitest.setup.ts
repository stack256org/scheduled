import { existsSync } from "node:fs";

// lib/env.ts validates process.env at import time — load .env the same way
// scripts/worker.ts and scripts/make-admin.ts do, so tests that transitively
// import lib/db (a real Postgres connection) don't fail on missing config.
if (existsSync(".env")) {
  process.loadEnvFile();
}
