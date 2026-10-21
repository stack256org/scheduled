// Container HEALTHCHECK for the single Schduled image (see Dockerfile).
//
// The image runs as the web server, the worker, or both (SCHDULED_ROLE, see
// scripts/docker-entrypoint.sh), so what "healthy" means depends on the role:
//
//   app     GET /api/health (does a real SELECT 1 against Postgres)
//   worker  the heartbeat file scripts/worker.ts rewrites every 15s — catches a
//           wedged event loop that "is the process alive" would miss
//   all     both
//
// docker-compose.yml overrides this per service, so it only decides the
// healthcheck for a platform that runs the image once.
import { statSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";

const role = process.env.SCHDULED_ROLE || "all";
const HEARTBEAT_MAX_AGE_MS = 60_000;

async function webHealthy() {
  try {
    const res = await fetch("http://127.0.0.1:3000/api/health");
    return res.ok;
  } catch {
    return false;
  }
}

function workerHealthy() {
  try {
    const age = Date.now() - statSync(join(tmpdir(), "worker-heartbeat")).mtimeMs;
    return age < HEARTBEAT_MAX_AGE_MS;
  } catch {
    return false;
  }
}

const checks = [];
if (role !== "worker") checks.push(webHealthy());
if (role === "worker" || role === "all") checks.push(Promise.resolve(workerHealthy()));

const results = await Promise.all(checks);
process.exit(results.every(Boolean) ? 0 : 1);
