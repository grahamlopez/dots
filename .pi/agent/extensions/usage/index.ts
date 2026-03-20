/**
 * Usage extension — /cost and /usage commands with live session cost tracking.
 *
 * Commands:
 *   /cost              — one-line summary: today | this week | all time | session
 *   /usage             — interactive report selector
 *   /usage model       — jump to model report
 *   /usage today       — jump to daily report
 *   /usage week        — jump to weekly report
 *   /usage session     — jump to session report
 *
 * Footer status shows current session cost, updated after each assistant message.
 */

import type { AssistantMessage } from "@mariozechner/pi-ai";
import type { ExtensionAPI, ExtensionContext, Theme } from "@mariozechner/pi-coding-agent";
import { DynamicBorder, getAgentDir } from "@mariozechner/pi-coding-agent";
import {
  Container,
  Key,
  type SelectItem,
  SelectList,
  Text,
  matchesKey,
  truncateToWidth,
} from "@mariozechner/pi-tui";
import * as path from "node:path";

import {
  aggregateByModel,
  aggregateByPeriod,
  aggregateBySession,
  filterByDate,
  getAllTimeSummary,
  getISOWeekStart,
  scanSessions,
} from "./data.ts";
import type { TokenCounts, UsageRecord } from "./types.ts";

/**
 * pi-ai's Usage type omits cache fields that are present in the serialized JSON.
 * Cast m.usage to this type once to avoid scattered `as any` casts.
 */
type CacheAwareUsage = {
  input: number;
  output: number;
  cacheRead?: number;
  cacheWrite?: number;
  totalTokens?: number;
  cost: { input?: number; output?: number; cacheRead?: number; cacheWrite?: number; total: number };
};

// ============================================================================
// Formatting helpers
// ============================================================================

function formatCost(n: number): string {
  if (n >= 1) return `$${n.toFixed(2)}`;
  return `$${n.toFixed(4)}`;
}

function formatTokens(n: number): string {
  if (n >= 1_000_000) return `${(n / 1_000_000).toFixed(1)}M`;
  if (n >= 1_000) return `${(n / 1_000).toFixed(1)}K`;
  return `${n}`;
}

function formatDate(d: Date): string {
  return d.toISOString().slice(0, 10);
}

/** Cap a string to max chars, appending "…" if truncated. */
function cap(s: string, max: number): string {
  if (!s) return "";
  return s.length <= max ? s : s.slice(0, max - 1) + "…";
}

/** Cache-hit percent: cacheRead / (input + cacheRead + cacheWrite). */
function cacheHitPct(tokens: TokenCounts): number {
  const base = tokens.input + tokens.cacheRead + tokens.cacheWrite;
  return base > 0 ? Math.round((tokens.cacheRead / base) * 100) : 0;
}

// ============================================================================
// Scrollable table viewer component
// ============================================================================

const MAX_VISIBLE_ROWS = 20;

interface TableSpec {
  title: string;
  headers: string[];
  /** Raw (no ANSI) data rows. */
  rows: string[][];
  /** Raw (no ANSI) totals row. */
  totals?: string[];
  /** Style a padded data cell. rowIndex = index into rows[]. */
  styleCell?: (paddedValue: string, rowIndex: number, colIndex: number) => string;
  /** Style a padded totals cell. */
  styleTotals?: (paddedValue: string, colIndex: number) => string;
}

class TableViewer {
  private spec: TableSpec;
  private theme: Theme;
  private onClose: () => void;
  private scrollOffset = 0;
  private numCols: number;
  private colWidths: number[];
  private cachedWidth?: number;
  private cachedLines?: string[];

  constructor(spec: TableSpec, theme: Theme, onClose: () => void) {
    this.spec = spec;
    this.theme = theme;
    this.onClose = onClose;
    this.numCols = spec.headers.length;

    // Column widths: max of header, data, and totals values
    this.colWidths = spec.headers.map((h) => h.length);
    for (const row of spec.rows) {
      for (let c = 0; c < this.numCols; c++) {
        this.colWidths[c] = Math.max(this.colWidths[c], (row[c] ?? "").length);
      }
    }
    if (spec.totals) {
      for (let c = 0; c < this.numCols; c++) {
        this.colWidths[c] = Math.max(this.colWidths[c], (spec.totals[c] ?? "").length);
      }
    }
  }

  private buildRowLine(
    values: string[],
    styleFn: (paddedValue: string, colIndex: number) => string
  ): string {
    const parts: string[] = [];
    for (let c = 0; c < this.numCols; c++) {
      const raw = values[c] ?? "";
      const padded = raw.padEnd(this.colWidths[c]);
      parts.push(styleFn(padded, c));
    }
    return "  " + parts.join("  ");
  }

  render(width: number): string[] {
    if (this.cachedLines && this.cachedWidth === width) return this.cachedLines;

    const th = this.theme;
    const lines: string[] = [];
    const dim = (s: string) => truncateToWidth(th.fg("dim", s), width);

    // Top border
    lines.push(truncateToWidth(th.fg("accent", "─".repeat(width)), width));
    // Title
    lines.push(truncateToWidth(" " + th.fg("accent", th.bold(this.spec.title)), width));

    if (this.spec.rows.length === 0) {
      lines.push(dim("  (no data)"));
    } else {
      // Headers
      lines.push(
        truncateToWidth(this.buildRowLine(this.spec.headers, (v) => th.fg("dim", v)), width)
      );
      // Header separator
      lines.push(dim("─".repeat(width)));

      // Data rows
      const styleCell = this.spec.styleCell ?? ((v) => v);
      const visibleRows = this.spec.rows.slice(
        this.scrollOffset,
        this.scrollOffset + MAX_VISIBLE_ROWS
      );
      for (let i = 0; i < visibleRows.length; i++) {
        const rowIndex = this.scrollOffset + i;
        const rowLine = this.buildRowLine(visibleRows[i], (v, c) => styleCell(v, rowIndex, c));
        lines.push(truncateToWidth(rowLine, width));
      }

      // Totals row
      if (this.spec.totals) {
        lines.push(dim("─".repeat(width)));
        const styleTotals =
          this.spec.styleTotals ??
          ((v, c) =>
            c === 0
              ? th.fg("accent", th.bold(v))
              : th.fg("dim", th.bold(v)));
        lines.push(
          truncateToWidth(
            this.buildRowLine(this.spec.totals, (v, c) => styleTotals(v, c)),
            width
          )
        );
      }
    }

    // Bottom border
    lines.push(truncateToWidth(th.fg("accent", "─".repeat(width)), width));

    // Footer: scroll info + help
    const helpParts: string[] = [];
    if (this.spec.rows.length > MAX_VISIBLE_ROWS) {
      const start = this.scrollOffset + 1;
      const end = Math.min(this.scrollOffset + MAX_VISIBLE_ROWS, this.spec.rows.length);
      helpParts.push(`${start}–${end} of ${this.spec.rows.length}  ↑↓ scroll`);
    }
    helpParts.push("enter/esc close");
    lines.push(truncateToWidth(th.fg("dim", " " + helpParts.join(" • ")), width));

    this.cachedWidth = width;
    this.cachedLines = lines;
    return lines;
  }

  handleInput(data: string): void {
    if (matchesKey(data, Key.up)) {
      if (this.scrollOffset > 0) {
        this.scrollOffset--;
        this.invalidate();
      }
    } else if (matchesKey(data, Key.down)) {
      if (this.scrollOffset + MAX_VISIBLE_ROWS < this.spec.rows.length) {
        this.scrollOffset++;
        this.invalidate();
      }
    } else if (matchesKey(data, Key.escape) || matchesKey(data, Key.enter)) {
      this.onClose();
    }
  }

  invalidate(): void {
    this.cachedWidth = undefined;
    this.cachedLines = undefined;
  }
}

/** Open a TableViewer inside ctx.ui.custom and resolve when the user closes it. */
function showTable(ctx: ExtensionContext, mkSpec: (theme: Theme) => TableSpec): Promise<void> {
  return ctx.ui.custom<void>((_tui, theme, _kb, done) =>
    new TableViewer(mkSpec(theme), theme, () => done(undefined))
  );
}

// ============================================================================
// Report builders
// ============================================================================

async function showModelReport(ctx: ExtensionContext, records: UsageRecord[]): Promise<void> {
  const report = aggregateByModel(records);
  const models = report.models;
  const t = report.totals;

  const headers = ["Model", "Provider", "Msgs", "Input", "Output", "Cache%", "Cost"];
  const rows: string[][] = models.map((m) => [
    cap(m.model, 40),
    cap(m.provider, 15),
    `${m.messageCount}`,
    formatTokens(m.tokens.input),
    formatTokens(m.tokens.output),
    `${cacheHitPct(m.tokens)}%`,
    formatCost(m.cost.total),
  ]);
  const totals = [
    "TOTAL",
    "",
    `${t.messageCount}`,
    formatTokens(t.tokens.input),
    formatTokens(t.tokens.output),
    `${cacheHitPct(t.tokens)}%`,
    formatCost(t.cost.total),
  ];

  return showTable(ctx, (theme) => ({
    title: "Usage by Model",
    headers,
    rows,
    totals,
    styleCell: (v, rowIndex, col) => {
      if (col === 0) return theme.fg("accent", v);
      if (col === 5) return theme.fg("dim", v); // Cache%
      if (col === 6) return theme.fg((models[rowIndex]?.cost.total ?? 0) >= 10 ? "warning" : "success", v);
      return theme.fg("dim", v);
    },
    styleTotals: (v, col) => {
      if (col === 0) return theme.fg("accent", theme.bold(v));
      if (col === 6) return theme.fg(t.cost.total >= 10 ? "warning" : "success", theme.bold(v));
      return theme.fg("dim", theme.bold(v));
    },
  }));
}

async function showPeriodReport(
  ctx: ExtensionContext,
  records: UsageRecord[],
  granularity: "day" | "week"
): Promise<void> {
  const report = aggregateByPeriod(records, granularity);
  const periods = [...report.periods].reverse(); // most recent first
  const t = report.totals;

  const headers = ["Period", "Msgs", "Input", "Output", "Cache%", "Cost"];
  const rows: string[][] = periods.map((p) => [
    p.key,
    `${p.messageCount}`,
    formatTokens(p.tokens.input),
    formatTokens(p.tokens.output),
    `${cacheHitPct(p.tokens)}%`,
    formatCost(p.cost.total),
  ]);
  const totals = [
    "TOTAL",
    `${t.messageCount}`,
    formatTokens(t.tokens.input),
    formatTokens(t.tokens.output),
    `${cacheHitPct(t.tokens)}%`,
    formatCost(t.cost.total),
  ];

  const title = granularity === "day" ? "Usage by Day" : "Usage by Week";

  return showTable(ctx, (theme) => ({
    title,
    headers,
    rows,
    totals,
    styleCell: (v, rowIndex, col) => {
      if (col === 4) return theme.fg("dim", v); // Cache%
      if (col === 5) return theme.fg((periods[rowIndex]?.cost.total ?? 0) >= 10 ? "warning" : "success", v);
      return theme.fg("dim", v);
    },
    styleTotals: (v, col) => {
      if (col === 0) return theme.fg("accent", theme.bold(v));
      if (col === 5) return theme.fg(t.cost.total >= 10 ? "warning" : "success", theme.bold(v));
      return theme.fg("dim", theme.bold(v));
    },
  }));
}

async function showSessionReport(ctx: ExtensionContext, records: UsageRecord[]): Promise<void> {
  const report = aggregateBySession(records);
  const sessions = [...report.sessions].reverse(); // most recent first
  const t = report.totals;

  const headers = ["Session", "Date", "Msgs", "Cost"];
  const rows: string[][] = sessions.map((s) => [
    cap(s.sessionName ?? s.sessionId.slice(0, 16), 35),
    formatDate(s.sessionStart),
    `${s.messageCount}`,
    formatCost(s.cost.total),
  ]);
  const totals = [
    "TOTAL",
    `${sessions.length} sessions`,
    `${t.messageCount}`,
    formatCost(t.cost.total),
  ];

  return showTable(ctx, (theme) => ({
    title: "Usage by Session",
    headers,
    rows,
    totals,
    styleCell: (v, rowIndex, col) => {
      if (col === 0) return theme.fg("text", v); // session name
      if (col === 1) return theme.fg("dim", v);  // date
      if (col === 3) return theme.fg((sessions[rowIndex]?.cost.total ?? 0) >= 10 ? "warning" : "success", v);
      return theme.fg("dim", v);
    },
    styleTotals: (v, col) => {
      if (col === 0) return theme.fg("accent", theme.bold(v));
      if (col === 3) return theme.fg(t.cost.total >= 10 ? "warning" : "success", theme.bold(v));
      return theme.fg("dim", theme.bold(v));
    },
  }));
}

async function showCurrentSessionReport(ctx: ExtensionContext): Promise<void> {
  // Convert branch entries to UsageRecords so we can reuse aggregateByModel.
  // Session metadata fields are stubs — aggregateByModel only needs model/provider/tokens/cost.
  const records: UsageRecord[] = [];
  for (const e of ctx.sessionManager.getBranch()) {
    if (e.type === "message" && e.message.role === "assistant") {
      const m = e.message as AssistantMessage;
      const u = m.usage as unknown as CacheAwareUsage;
      records.push({
        model: m.model,
        provider: m.provider,
        timestamp: new Date(m.timestamp),
        tokens: {
          input: u.input,
          output: u.output,
          cacheRead: u.cacheRead ?? 0,
          cacheWrite: u.cacheWrite ?? 0,
          total: u.totalTokens ?? u.input + u.output + (u.cacheRead ?? 0) + (u.cacheWrite ?? 0),
        },
        cost: {
          input: u.cost.input ?? 0,
          output: u.cost.output ?? 0,
          cacheRead: u.cost.cacheRead ?? 0,
          cacheWrite: u.cost.cacheWrite ?? 0,
          total: u.cost.total,
        },
        sessionId: "", sessionFilePath: "", cwd: "", sessionName: undefined, sessionStart: new Date(0),
      });
    }
  }

  if (records.length === 0) {
    ctx.ui.notify("No assistant messages in the current session yet.", "info");
    return;
  }

  const report = aggregateByModel(records);
  const models = report.models;
  const t = report.totals;

  const headers = ["Model", "Provider", "Msgs", "Input", "Output", "Cache%", "Cost"];
  const rows: string[][] = models.map((m) => [
    cap(m.model, 40),
    cap(m.provider, 15),
    `${m.messageCount}`,
    formatTokens(m.tokens.input),
    formatTokens(m.tokens.output),
    `${cacheHitPct(m.tokens)}%`,
    formatCost(m.cost.total),
  ]);
  const totals = [
    "TOTAL",
    "",
    `${t.messageCount}`,
    formatTokens(t.tokens.input),
    formatTokens(t.tokens.output),
    `${cacheHitPct(t.tokens)}%`,
    formatCost(t.cost.total),
  ];

  return showTable(ctx, (theme) => ({
    title: "Current Session Usage",
    headers,
    rows,
    totals,
    styleCell: (v, rowIndex, col) => {
      if (col === 0) return theme.fg("accent", v);
      if (col === 5) return theme.fg("dim", v); // Cache%
      if (col === 6) return theme.fg((models[rowIndex]?.cost.total ?? 0) >= 10 ? "warning" : "success", v);
      return theme.fg("dim", v);
    },
    styleTotals: (v, col) => {
      if (col === 0) return theme.fg("accent", theme.bold(v));
      if (col === 6) return theme.fg(t.cost.total >= 10 ? "warning" : "success", theme.bold(v));
      return theme.fg("dim", theme.bold(v));
    },
  }));
}

// ============================================================================
// Report selector
// ============================================================================

async function showReportSelector(ctx: ExtensionContext, sessionsDir: string): Promise<void> {
  const items: SelectItem[] = [
    { value: "model", label: "By Model", description: "Token usage and cost per model (all time)" },
    { value: "day", label: "By Day", description: "Daily usage breakdown (most recent first)" },
    { value: "week", label: "By Week", description: "Weekly usage breakdown (most recent first)" },
    { value: "session", label: "By Session", description: "Per-session breakdown (most recent first)" },
    { value: "current", label: "Current Session", description: "Live usage for this session" },
  ];

  const choice = await ctx.ui.custom<string | null>((tui, theme, _kb, done) => {
    const container = new Container();
    container.addChild(new DynamicBorder((s: string) => theme.fg("accent", s)));
    container.addChild(
      new Text(theme.fg("accent", theme.bold(" Usage Report")), 1, 0)
    );

    const selectList = new SelectList(items, Math.min(items.length, 10), {
      selectedPrefix: (t) => theme.fg("accent", t),
      selectedText: (t) => theme.fg("accent", t),
      description: (t) => theme.fg("muted", t),
      scrollInfo: (t) => theme.fg("dim", t),
      noMatch: (t) => theme.fg("warning", t),
    });
    selectList.onSelect = (item) => done(item.value);
    selectList.onCancel = () => done(null);
    container.addChild(selectList);

    container.addChild(
      new Text(theme.fg("dim", " ↑↓ navigate • enter select • esc cancel"), 1, 0)
    );
    container.addChild(new DynamicBorder((s: string) => theme.fg("accent", s)));

    return {
      render: (w) => container.render(w),
      invalidate: () => container.invalidate(),
      handleInput: (data) => {
        selectList.handleInput(data);
        tui.requestRender();
      },
    };
  });

  if (!choice) return;

  await runReport(ctx, choice, sessionsDir);
}

async function runReport(
  ctx: ExtensionContext,
  choice: string,
  sessionsDir: string
): Promise<void> {
  if (choice === "current") {
    await showCurrentSessionReport(ctx);
    return;
  }

  let records: UsageRecord[];
  try {
    records = await scanSessions(sessionsDir);
  } catch (err) {
    ctx.ui.notify(`Failed to scan sessions: ${err}`, "error");
    return;
  }

  switch (choice) {
    case "model":
      await showModelReport(ctx, records);
      break;
    case "day":
      await showPeriodReport(ctx, records, "day");
      break;
    case "week":
      await showPeriodReport(ctx, records, "week");
      break;
    case "session":
      await showSessionReport(ctx, records);
      break;
    default:
      ctx.ui.notify(`Unknown report type: ${choice}`, "error");
  }
}

// ============================================================================
// Extension entry point
// ============================================================================

export default function usageExtension(pi: ExtensionAPI) {
  let currentSessionCost = 0;

  /** Reconstruct current session cost from branch entries. */
  function reconstructCost(ctx: ExtensionContext): number {
    let cost = 0;
    for (const e of ctx.sessionManager.getBranch()) {
      if (e.type === "message" && e.message.role === "assistant") {
        const m = e.message as AssistantMessage;
        cost += m.usage.cost.total;
      }
    }
    return cost;
  }

  /** Update the footer status with the current session cost. */
  function updateStatus(ctx: ExtensionContext): void {
    const display = formatCost(currentSessionCost);
    ctx.ui.setStatus("usage", ctx.ui.theme.fg("dim", `${display} session`));
  }

  // ── Session lifecycle: reconstruct cost ──────────────────────────────────

  pi.on("session_start", async (_event, ctx) => {
    currentSessionCost = reconstructCost(ctx);
    updateStatus(ctx);
  });

  pi.on("session_switch", async (_event, ctx) => {
    currentSessionCost = reconstructCost(ctx);
    updateStatus(ctx);
  });

  pi.on("session_fork", async (_event, ctx) => {
    currentSessionCost = reconstructCost(ctx);
    updateStatus(ctx);
  });

  pi.on("session_tree", async (_event, ctx) => {
    currentSessionCost = reconstructCost(ctx);
    updateStatus(ctx);
  });

  // ── Track cost live after each assistant message ─────────────────────────

  pi.on("message_end", async (event, ctx) => {
    if ((event.message as any)?.role === "assistant") {
      currentSessionCost = reconstructCost(ctx);
      updateStatus(ctx);
    }
  });

  // ── /cost command ────────────────────────────────────────────────────────

  pi.registerCommand("cost", {
    description: "Quick cost summary: today | this week | all time | session",
    handler: async (_args, ctx) => {
      const sessionsDir = path.join(getAgentDir(), "sessions");

      let allRecords: UsageRecord[];
      try {
        allRecords = await scanSessions(sessionsDir);
      } catch (err) {
        ctx.ui.notify(`Failed to scan sessions: ${err}`, "error");
        return;
      }

      const now = new Date();

      // Today (UTC midnight → now)
      const todayStart = new Date(
        Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate())
      );
      const todayCost = filterByDate(allRecords, { from: todayStart }).reduce(
        (sum, r) => sum + r.cost.total,
        0
      );

      // This week (ISO Monday → now)
      const weekStart = getISOWeekStart(now);
      const weekCost = filterByDate(allRecords, { from: weekStart }).reduce(
        (sum, r) => sum + r.cost.total,
        0
      );

      // All-time
      const allTimeCost = getAllTimeSummary(allRecords).cost.total;

      const msg =
        `Today: ${formatCost(todayCost)}` +
        ` | This week: ${formatCost(weekCost)}` +
        ` | All time: ${formatCost(allTimeCost)}` +
        ` | Session: ${formatCost(currentSessionCost)}`;

      ctx.ui.notify(msg, "info");
    },
  });

  // ── /usage command ───────────────────────────────────────────────────────

  pi.registerCommand("usage", {
    description: "Interactive usage/cost report viewer",
    getArgumentCompletions: (prefix: string) => {
      const options = ["model", "today", "week", "session"];
      const filtered = options.filter((o) => o.startsWith(prefix));
      return filtered.length > 0 ? filtered.map((v) => ({ value: v, label: v })) : null;
    },
    handler: async (args, ctx) => {
      const sessionsDir = path.join(getAgentDir(), "sessions");
      const sub = args?.trim().toLowerCase();

      if (sub === "model") {
        await runReport(ctx, "model", sessionsDir);
        return;
      }
      if (sub === "today") {
        await runReport(ctx, "day", sessionsDir);
        return;
      }
      if (sub === "week") {
        await runReport(ctx, "week", sessionsDir);
        return;
      }
      if (sub === "session") {
        await runReport(ctx, "session", sessionsDir);
        return;
      }
      if (sub === "current") {
        await showCurrentSessionReport(ctx);
        return;
      }

      // No subcommand: show interactive selector
      await showReportSelector(ctx, sessionsDir);
    },
  });
}
