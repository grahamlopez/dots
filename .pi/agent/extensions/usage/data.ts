/**
 * data.ts — Session scanning and usage aggregation layer.
 *
 * Zero dependency on @mariozechner/pi-coding-agent or @mariozechner/pi-tui.
 * Uses only node:fs, node:path, and pure TypeScript.
 *
 * Primary entry point: scanSessions(dir, filter?) → UsageRecord[]
 * Then pass the records to any aggregation function.
 */

import * as fsp from "node:fs/promises";
import * as path from "node:path";

import type {
  AllTimeUsage,
  CostBreakdown,
  DateFilter,
  ModelStats,
  PeriodGranularity,
  PeriodRow,
  SessionUsage,
  TokenCounts,
  UsageByModel,
  UsageByPeriod,
  UsageBySession,
  UsageRecord,
} from "./types.ts";

// ============================================================================
// Public API
// ============================================================================

/**
 * Recursively scan `sessionsDir` for *.jsonl files, parse each one, and
 * return a flat array of UsageRecords enriched with session metadata.
 *
 * Date filtering (via `filter`) is applied to each assistant message's
 * timestamp before the record is included. This keeps memory usage low
 * when scanning many sessions with a narrow date window.
 */
export async function scanSessions(
  sessionsDir: string,
  filter?: DateFilter
): Promise<UsageRecord[]> {
  const files = await findJsonlFiles(sessionsDir);
  const nested = await Promise.all(files.map((f) => parseSessionFile(f, filter)));
  return nested.flat();
}

/**
 * Filter an existing array of records by date range.
 * Useful when you want to scan once and then aggregate multiple slices.
 */
export function filterByDate(
  records: UsageRecord[],
  filter: DateFilter
): UsageRecord[] {
  return records.filter((r) => {
    if (filter.from && r.timestamp < filter.from) return false;
    if (filter.to && r.timestamp > filter.to) return false;
    return true;
  });
}

/**
 * Aggregate records by model+provider.
 * Returns models sorted by total cost descending.
 */
export function aggregateByModel(records: UsageRecord[]): UsageByModel {
  const modelMap = new Map<string, ModelStats>();

  for (const record of records) {
    const key = modelKey(record);
    let stats = modelMap.get(key);
    if (!stats) {
      stats = {
        model: record.model,
        provider: record.provider,
        messageCount: 0,
        tokens: zeroTokens(),
        cost: zeroCost(),
      };
      modelMap.set(key, stats);
    }
    stats.messageCount++;
    addTokens(stats.tokens, record.tokens);
    addCost(stats.cost, record.cost);
  }

  const models = Array.from(modelMap.values()).sort(
    (a, b) => b.cost.total - a.cost.total
  );

  const totals = buildTotals(records);
  return { models, totals };
}

/**
 * Aggregate records by time period.
 * - `'day'`  → key format `"YYYY-MM-DD"` (UTC)
 * - `'week'` → key format `"YYYY-Www"` (ISO 8601 week, Monday start)
 *
 * Periods are sorted chronologically.
 */
export function aggregateByPeriod(
  records: UsageRecord[],
  granularity: PeriodGranularity
): UsageByPeriod {
  const periodMap = new Map<string, PeriodRow>();

  for (const record of records) {
    const key =
      granularity === "day"
        ? getDayKey(record.timestamp)
        : getISOWeekKey(record.timestamp);

    let row = periodMap.get(key);
    if (!row) {
      const { start, end } = getPeriodBounds(record.timestamp, granularity);
      row = {
        key,
        start,
        end,
        messageCount: 0,
        tokens: zeroTokens(),
        cost: zeroCost(),
        byModel: {},
      };
      periodMap.set(key, row);
    }

    row.messageCount++;
    addTokens(row.tokens, record.tokens);
    addCost(row.cost, record.cost);

    const mk = modelKey(record);
    if (!row.byModel[mk]) {
      row.byModel[mk] = {
        model: record.model,
        provider: record.provider,
        messageCount: 0,
        tokens: zeroTokens(),
        cost: zeroCost(),
      };
    }
    row.byModel[mk].messageCount++;
    addTokens(row.byModel[mk].tokens, record.tokens);
    addCost(row.byModel[mk].cost, record.cost);
  }

  const periods = Array.from(periodMap.values()).sort(
    (a, b) => a.start.getTime() - b.start.getTime()
  );

  // Totals from the period rows (avoids double-iterating records)
  const totals = aggregatePeriodTotals(periods);

  return { granularity, periods, totals };
}

/**
 * Aggregate records by session.
 * Sessions are sorted chronologically by `sessionStart`.
 */
export function aggregateBySession(records: UsageRecord[]): UsageBySession {
  const sessionMap = new Map<string, SessionUsage>();

  for (const record of records) {
    let session = sessionMap.get(record.sessionId);
    if (!session) {
      session = {
        sessionId: record.sessionId,
        sessionFilePath: record.sessionFilePath,
        cwd: record.cwd,
        sessionName: record.sessionName,
        sessionStart: record.sessionStart,
        sessionEnd: record.timestamp,
        messageCount: 0,
        tokens: zeroTokens(),
        cost: zeroCost(),
        byModel: {},
      };
      sessionMap.set(record.sessionId, session);
    }

    session.messageCount++;
    addTokens(session.tokens, record.tokens);
    addCost(session.cost, record.cost);

    if (record.timestamp > session.sessionEnd) {
      session.sessionEnd = record.timestamp;
    }
    // All records from the same file share the same sessionName (last
    // session_info entry wins — resolved during file parsing).
    if (record.sessionName !== undefined) {
      session.sessionName = record.sessionName;
    }

    const mk = modelKey(record);
    if (!session.byModel[mk]) {
      session.byModel[mk] = {
        model: record.model,
        provider: record.provider,
        messageCount: 0,
        tokens: zeroTokens(),
        cost: zeroCost(),
      };
    }
    session.byModel[mk].messageCount++;
    addTokens(session.byModel[mk].tokens, record.tokens);
    addCost(session.byModel[mk].cost, record.cost);
  }

  const sessions = Array.from(sessionMap.values()).sort(
    (a, b) => a.sessionStart.getTime() - b.sessionStart.getTime()
  );

  const totals = buildTotals(records);
  return { sessions, totals };
}

/**
 * Compute an all-time summary over the provided records.
 */
export function getAllTimeSummary(records: UsageRecord[]): AllTimeUsage {
  const tokens = zeroTokens();
  const cost = zeroCost();
  const byModel: Record<string, ModelStats> = {};
  const sessionIds = new Set<string>();
  let firstMessageAt: Date | null = null;
  let lastMessageAt: Date | null = null;

  for (const record of records) {
    addTokens(tokens, record.tokens);
    addCost(cost, record.cost);
    sessionIds.add(record.sessionId);

    if (!firstMessageAt || record.timestamp < firstMessageAt) {
      firstMessageAt = record.timestamp;
    }
    if (!lastMessageAt || record.timestamp > lastMessageAt) {
      lastMessageAt = record.timestamp;
    }

    const mk = modelKey(record);
    if (!byModel[mk]) {
      byModel[mk] = {
        model: record.model,
        provider: record.provider,
        messageCount: 0,
        tokens: zeroTokens(),
        cost: zeroCost(),
      };
    }
    byModel[mk].messageCount++;
    addTokens(byModel[mk].tokens, record.tokens);
    addCost(byModel[mk].cost, record.cost);
  }

  return {
    messageCount: records.length,
    sessionCount: sessionIds.size,
    firstMessageAt,
    lastMessageAt,
    tokens,
    cost,
    byModel,
  };
}

// ============================================================================
// File scanning helpers
// ============================================================================

async function findJsonlFiles(dir: string): Promise<string[]> {
  const files: string[] = [];
  try {
    const entries = await fsp.readdir(dir, { withFileTypes: true });
    for (const entry of entries) {
      const fullPath = path.join(dir, entry.name);
      if (entry.isDirectory()) {
        const sub = await findJsonlFiles(fullPath);
        for (const f of sub) files.push(f);
      } else if (entry.isFile() && entry.name.endsWith(".jsonl")) {
        files.push(fullPath);
      }
    }
  } catch {
    // Unreadable directory — skip silently
  }
  return files;
}

/**
 * Parse a single .jsonl file and return its UsageRecords.
 *
 * Session format (from session.md):
 *   - Line 0:  session header  { type:"session", id, timestamp (ISO), cwd, ... }
 *   - Lines 1+: entries       { type, id, parentId, timestamp (ISO), ... }
 *     - type:"message"        .message.role === "assistant"  → usage
 *     - type:"session_info"   .name                         → session name
 *
 * AssistantMessage.timestamp is Unix milliseconds (number).
 * The session header timestamp is an ISO string.
 */
async function parseSessionFile(
  filePath: string,
  filter?: DateFilter
): Promise<UsageRecord[]> {
  let content: string;
  try {
    content = await fsp.readFile(filePath, "utf8");
  } catch {
    return [];
  }

  const lines = content.split("\n");

  // ── Parse header (first non-empty line) ──────────────────────────────────
  let headerLine = "";
  let lineStart = 0;
  for (let i = 0; i < lines.length; i++) {
    const trimmed = lines[i].trim();
    if (trimmed) {
      headerLine = trimmed;
      lineStart = i + 1;
      break;
    }
  }
  if (!headerLine) return [];

  let header: Record<string, unknown>;
  try {
    header = JSON.parse(headerLine) as Record<string, unknown>;
  } catch {
    return [];
  }
  if (header["type"] !== "session") return [];

  const sessionId = (header["id"] as string) ?? "";
  const cwd = (header["cwd"] as string) ?? "";
  const sessionStart = new Date(header["timestamp"] as string);

  // ── Two-pass scan: collect entries, find final session name ──────────────
  // Pass 1: collect parsed entries and final session name
  let sessionName: string | undefined;
  const entries: Record<string, unknown>[] = [];

  for (let i = lineStart; i < lines.length; i++) {
    const trimmed = lines[i].trim();
    if (!trimmed) continue;
    let entry: Record<string, unknown>;
    try {
      entry = JSON.parse(trimmed) as Record<string, unknown>;
    } catch {
      continue;
    }
    if (entry["type"] === "session_info" && entry["name"]) {
      sessionName = entry["name"] as string;
    }
    entries.push(entry);
  }

  // Pass 2: build UsageRecords from assistant messages
  const records: UsageRecord[] = [];

  for (const entry of entries) {
    if (entry["type"] !== "message") continue;
    const msg = entry["message"] as Record<string, unknown> | undefined;
    if (!msg || msg["role"] !== "assistant") continue;

    const rawUsage = msg["usage"] as Record<string, unknown> | undefined;
    if (!rawUsage) continue;

    // AssistantMessage.timestamp is Unix ms (number)
    const rawTs = msg["timestamp"];
    const timestamp =
      typeof rawTs === "number"
        ? new Date(rawTs)
        : typeof rawTs === "string"
        ? new Date(rawTs)
        : new Date(entry["timestamp"] as string); // fallback to entry timestamp

    if (isNaN(timestamp.getTime())) continue;

    // Apply date filter
    if (filter?.from && timestamp < filter.from) continue;
    if (filter?.to && timestamp > filter.to) continue;

    const rawCost = rawUsage["cost"] as Record<string, unknown> | undefined;

    records.push({
      model: (msg["model"] as string) ?? "",
      provider: (msg["provider"] as string) ?? "",
      timestamp,
      tokens: {
        input: numOf(rawUsage["input"]),
        output: numOf(rawUsage["output"]),
        cacheRead: numOf(rawUsage["cacheRead"]),
        cacheWrite: numOf(rawUsage["cacheWrite"]),
        total: numOf(rawUsage["totalTokens"]),
      },
      cost: {
        input: numOf(rawCost?.["input"]),
        output: numOf(rawCost?.["output"]),
        cacheRead: numOf(rawCost?.["cacheRead"]),
        cacheWrite: numOf(rawCost?.["cacheWrite"]),
        total: numOf(rawCost?.["total"]),
      },
      sessionId,
      sessionFilePath: filePath,
      cwd,
      sessionName, // final name from last session_info in this file
      sessionStart,
    });
  }

  return records;
}

// ============================================================================
// Period helpers
// ============================================================================

/** UTC day key: "YYYY-MM-DD" */
function getDayKey(date: Date): string {
  const y = date.getUTCFullYear();
  const m = String(date.getUTCMonth() + 1).padStart(2, "0");
  const d = String(date.getUTCDate()).padStart(2, "0");
  return `${y}-${m}-${d}`;
}

/**
 * Return the Monday (UTC) that starts the ISO week containing `date`.
 * ISO weeks start on Monday; Sunday is the last day of the week.
 */
export function getISOWeekStart(date: Date): Date {
  const d = new Date(
    Date.UTC(date.getUTCFullYear(), date.getUTCMonth(), date.getUTCDate())
  );
  const day = d.getUTCDay(); // 0=Sun, 1=Mon, …, 6=Sat
  // Monday offset: subtract (day-1) days, or 6 days for Sunday
  d.setUTCDate(d.getUTCDate() - (day === 0 ? 6 : day - 1));
  return d;
}

/**
 * ISO 8601 week key: "YYYY-Www".
 *
 * The ISO week year is determined by Thursday of the week
 * (weeks that span year boundaries belong to the year that contains Thursday).
 */
function getISOWeekKey(date: Date): string {
  const monday = getISOWeekStart(date);

  // Thursday of this week determines the ISO year
  const thursday = new Date(monday);
  thursday.setUTCDate(monday.getUTCDate() + 3);
  const isoYear = thursday.getUTCFullYear();

  // First Monday of ISO week 1 of isoYear = Monday on or before Jan 4
  const jan4 = new Date(Date.UTC(isoYear, 0, 4));
  const jan4Day = jan4.getUTCDay();
  const firstMonday = new Date(jan4);
  firstMonday.setUTCDate(jan4.getUTCDate() - (jan4Day === 0 ? 6 : jan4Day - 1));

  const weekNum =
    Math.round(
      (monday.getTime() - firstMonday.getTime()) / (7 * 24 * 60 * 60 * 1000)
    ) + 1;

  return `${isoYear}-W${String(weekNum).padStart(2, "0")}`;
}

function getPeriodBounds(
  date: Date,
  granularity: PeriodGranularity
): { start: Date; end: Date } {
  if (granularity === "day") {
    const start = new Date(
      Date.UTC(date.getUTCFullYear(), date.getUTCMonth(), date.getUTCDate())
    );
    const end = new Date(start);
    end.setUTCDate(start.getUTCDate() + 1);
    return { start, end };
  } else {
    const start = getISOWeekStart(date);
    const end = new Date(start);
    end.setUTCDate(start.getUTCDate() + 7);
    return { start, end };
  }
}

// ============================================================================
// Aggregation helpers
// ============================================================================

function modelKey(record: UsageRecord): string {
  return `${record.provider}/${record.model}`;
}

function buildTotals(records: UsageRecord[]): {
  messageCount: number;
  tokens: TokenCounts;
  cost: CostBreakdown;
} {
  const tokens = zeroTokens();
  const cost = zeroCost();
  for (const r of records) {
    addTokens(tokens, r.tokens);
    addCost(cost, r.cost);
  }
  return { messageCount: records.length, tokens, cost };
}

function aggregatePeriodTotals(periods: PeriodRow[]): {
  messageCount: number;
  tokens: TokenCounts;
  cost: CostBreakdown;
} {
  const tokens = zeroTokens();
  const cost = zeroCost();
  let messageCount = 0;
  for (const p of periods) {
    messageCount += p.messageCount;
    addTokens(tokens, p.tokens);
    addCost(cost, p.cost);
  }
  return { messageCount, tokens, cost };
}

// ============================================================================
// Arithmetic helpers
// ============================================================================

function zeroTokens(): TokenCounts {
  return { input: 0, output: 0, cacheRead: 0, cacheWrite: 0, total: 0 };
}

function zeroCost(): CostBreakdown {
  return { input: 0, output: 0, cacheRead: 0, cacheWrite: 0, total: 0 };
}

function addTokens(a: TokenCounts, b: TokenCounts): void {
  a.input += b.input;
  a.output += b.output;
  a.cacheRead += b.cacheRead;
  a.cacheWrite += b.cacheWrite;
  a.total += b.total;
}

function addCost(a: CostBreakdown, b: CostBreakdown): void {
  a.input += b.input;
  a.output += b.output;
  a.cacheRead += b.cacheRead;
  a.cacheWrite += b.cacheWrite;
  a.total += b.total;
}

/** Safely coerce a JSON value to a finite number (0 on failure). */
function numOf(v: unknown): number {
  const n = Number(v);
  return isFinite(n) ? n : 0;
}
