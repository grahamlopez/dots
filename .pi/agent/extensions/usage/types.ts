/**
 * types.ts — Report interfaces for the usage extension.
 *
 * All monetary values are in USD (dollars). Token counts are integers.
 * This module has zero runtime dependencies — pure type declarations.
 */

// ---------------------------------------------------------------------------
// Primitives
// ---------------------------------------------------------------------------

/** Token counts for a single message or aggregated across many messages. */
export interface TokenCounts {
  input: number;
  output: number;
  cacheRead: number;
  cacheWrite: number;
  total: number;
}

/** Cost breakdown in USD for a single message or aggregated group. */
export interface CostBreakdown {
  input: number;
  output: number;
  cacheRead: number;
  cacheWrite: number;
  total: number;
}

/** Optional date range for filtering records before aggregation. */
export interface DateFilter {
  from?: Date;
  to?: Date;
}

// ---------------------------------------------------------------------------
// UsageRecord — one assistant message extracted from a session file
// ---------------------------------------------------------------------------

/**
 * A single usage record extracted from one `assistant` message in a session.
 * Session metadata is denormalized onto every record so that any subset of
 * records can be independently aggregated.
 */
export interface UsageRecord {
  // ── Message-level fields ──────────────────────────────────────────────
  model: string;
  provider: string;
  /** Derived from AssistantMessage.timestamp (Unix ms → Date). */
  timestamp: Date;
  tokens: TokenCounts;
  cost: CostBreakdown;

  // ── Session metadata ──────────────────────────────────────────────────
  /** UUID from the session header (not the entry id). */
  sessionId: string;
  /** Absolute path to the .jsonl file. */
  sessionFilePath: string;
  /** Working directory recorded in the session header. */
  cwd: string;
  /**
   * Display name from the latest `session_info` entry in the file,
   * or undefined if none was set.
   */
  sessionName: string | undefined;
  /** Parsed from the session header `timestamp` field (ISO string → Date). */
  sessionStart: Date;
}

// ---------------------------------------------------------------------------
// UsageByModel
// ---------------------------------------------------------------------------

/** Aggregated statistics for a single model+provider combination. */
export interface ModelStats {
  model: string;
  provider: string;
  messageCount: number;
  tokens: TokenCounts;
  cost: CostBreakdown;
}

/** Per-model breakdown, sorted by total cost descending. */
export interface UsageByModel {
  /** One entry per unique provider/model pair. */
  models: ModelStats[];
  totals: {
    messageCount: number;
    tokens: TokenCounts;
    cost: CostBreakdown;
  };
}

// ---------------------------------------------------------------------------
// UsageByPeriod
// ---------------------------------------------------------------------------

export type PeriodGranularity = "day" | "week";

/**
 * One row in a period-based report.
 * - `key` is `"YYYY-MM-DD"` for day granularity, `"YYYY-Www"` for ISO weeks.
 * - `start` / `end` bound the period (end is exclusive).
 */
export interface PeriodRow {
  key: string;
  start: Date;
  /** Exclusive end of the period (start + 1 day or start + 7 days). */
  end: Date;
  messageCount: number;
  tokens: TokenCounts;
  cost: CostBreakdown;
  /** Per-model breakdown keyed by `"provider/model"`. */
  byModel: Record<string, ModelStats>;
}

/** Period-based usage report (day or ISO-week granularity). */
export interface UsageByPeriod {
  granularity: PeriodGranularity;
  /** Sorted chronologically by `start`. */
  periods: PeriodRow[];
  totals: {
    messageCount: number;
    tokens: TokenCounts;
    cost: CostBreakdown;
  };
}

// ---------------------------------------------------------------------------
// UsageBySession
// ---------------------------------------------------------------------------

/** Aggregated usage for one session file. */
export interface SessionUsage {
  sessionId: string;
  sessionFilePath: string;
  cwd: string;
  sessionName: string | undefined;
  /** From the session header timestamp. */
  sessionStart: Date;
  /** Timestamp of the last assistant message in the session. */
  sessionEnd: Date;
  messageCount: number;
  tokens: TokenCounts;
  cost: CostBreakdown;
  /** Per-model breakdown keyed by `"provider/model"`. */
  byModel: Record<string, ModelStats>;
}

/** All-sessions breakdown. */
export interface UsageBySession {
  /** Sorted chronologically by `sessionStart`. */
  sessions: SessionUsage[];
  totals: {
    messageCount: number;
    tokens: TokenCounts;
    cost: CostBreakdown;
  };
}

// ---------------------------------------------------------------------------
// AllTimeUsage
// ---------------------------------------------------------------------------

/** Grand-total summary over all (filtered) records. */
export interface AllTimeUsage {
  messageCount: number;
  sessionCount: number;
  firstMessageAt: Date | null;
  lastMessageAt: Date | null;
  tokens: TokenCounts;
  cost: CostBreakdown;
  /** Per-model breakdown keyed by `"provider/model"`. */
  byModel: Record<string, ModelStats>;
}
