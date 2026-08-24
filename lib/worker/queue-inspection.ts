import { dbClient } from "@/lib/db";

export interface QueueSummaryRow {
  count: number;
  name: string;
  state: string;
}

export async function getQueueSummary(): Promise<QueueSummaryRow[]> {
  try {
    const rows = await dbClient<QueueSummaryRow[]>`
      select name, state, count(*)::int as count
      from pgboss.job
      group by name, state
      order by name, state
    `;
    return rows;
  } catch {
    return [];
  }
}

export interface QueueJobRow {
  completedOn: string | null;
  createdOn: string | null;
  data: unknown;
  id: string;
  output: unknown;
  retryCount: number;
  retryLimit: number;
  startedOn: string | null;
  state: string;
}

export interface QueueStateCount {
  count: number;
  state: string;
}

// `pgboss.job` is partitioned on `name`, so every query MUST filter by name.
export async function getQueueJobs({
  queue,
  state,
  search,
  page,
  pageSize,
}: {
  queue: string;
  state?: string;
  search?: string;
  page: number;
  pageSize: number;
}): Promise<{ rows: QueueJobRow[]; total: number }> {
  const offset = Math.max(0, (page - 1) * pageSize);
  const term = search?.trim();
  const like = term ? `%${term}%` : null;
  // Reusable WHERE fragment so the page query and the count query stay in sync.
  const where = dbClient`
    where name = ${queue}
    ${state ? dbClient`and state = ${state}` : dbClient``}
    ${
      like
        ? dbClient`and (id::text ilike ${like} or coalesce(output->>'message', '') ilike ${like})`
        : dbClient``
    }
  `;
  try {
    const rows = await dbClient<QueueJobRow[]>`
      select
        id,
        state,
        retry_count   as "retryCount",
        retry_limit   as "retryLimit",
        created_on    as "createdOn",
        started_on    as "startedOn",
        completed_on  as "completedOn",
        data,
        output
      from pgboss.job
      ${where}
      order by created_on desc
      limit ${pageSize} offset ${offset}
    `;
    const [{ total }] = await dbClient<{ total: number }[]>`
      select count(*)::int as total from pgboss.job ${where}
    `;
    return { rows, total };
  } catch {
    return { rows: [], total: 0 };
  }
}

export async function getQueueStateCounts(
  queue: string
): Promise<QueueStateCount[]> {
  try {
    const rows = await dbClient<QueueStateCount[]>`
      select state, count(*)::int as count
      from pgboss.job
      where name = ${queue}
      group by state
      order by state
    `;
    return rows;
  } catch {
    return [];
  }
}

export interface QueueStats {
  lastProcessedOn: string | null;
  states: QueueStateCount[];
  total: number;
}

export async function getQueueStats(queue: string): Promise<QueueStats> {
  try {
    const states = await getQueueStateCounts(queue);
    const total = states.reduce((sum, s) => sum + s.count, 0);
    const [{ lastProcessedOn }] = await dbClient<
      { lastProcessedOn: string | null }[]
    >`
      select max(completed_on) as "lastProcessedOn"
      from pgboss.job
      where name = ${queue}
    `;
    return { states, total, lastProcessedOn };
  } catch {
    return { states: [], total: 0, lastProcessedOn: null };
  }
}
