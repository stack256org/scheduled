import type { Job } from "pg-boss";

export async function handlePlatformHealthcheck(
  jobs: Job<Record<string, never>>[]
) {
  for (const job of jobs) {
    console.log(`[worker] platform healthcheck ok (${job.id})`);
  }
}
