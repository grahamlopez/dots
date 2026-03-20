/**
 * data.test.ts — Unit tests for the usage extension data layer.
 *
 * Run with:  npx tsx --test ~/.pi/agent/extensions/usage/data.test.ts
 */

import assert from "node:assert/strict";
import * as fsp from "node:fs/promises";
import * as os from "node:os";
import * as path from "node:path";
import { test } from "node:test";

import {
  aggregateByModel,
  aggregateByPeriod,
  filterByDate,
  getAllTimeSummary,
  getISOWeekStart,
  scanSessions,
} from "./data.ts";
import type { UsageRecord } from "./types.ts";

// ============================================================================
// Test helpers
// ============================================================================

function makeRecord(overrides: Partial<UsageRecord> = {}): UsageRecord {
  return {
    model: "claude-3-5-sonnet",
    provider: "anthropic",
    timestamp: new Date("2024-03-15T10:00:00Z"),
    tokens: { input: 100, output: 50, cacheRead: 20, cacheWrite: 10, total: 180 },
    cost: { input: 0.001, output: 0.002, cacheRead: 0.0005, cacheWrite: 0.001, total: 0.0045 },
    sessionId: "sess-1",
    sessionFilePath: "/fake/path.jsonl",
    cwd: "/home/user",
    sessionName: "test session",
    sessionStart: new Date("2024-03-15T09:00:00Z"),
    ...overrides,
  };
}

// ============================================================================
// getISOWeekStart
// ============================================================================

test("getISOWeekStart: Friday → preceding Monday", () => {
  // 2024-03-15 is a Friday
  assert.equal(
    getISOWeekStart(new Date("2024-03-15T00:00:00Z")).toISOString().slice(0, 10),
    "2024-03-11"
  );
});

test("getISOWeekStart: Monday → same day", () => {
  assert.equal(
    getISOWeekStart(new Date("2024-03-11T00:00:00Z")).toISOString().slice(0, 10),
    "2024-03-11"
  );
});

test("getISOWeekStart: Sunday → preceding Monday (Sunday ends the week in ISO)", () => {
  // 2024-03-10 is a Sunday — belongs to the week starting 2024-03-04
  assert.equal(
    getISOWeekStart(new Date("2024-03-10T00:00:00Z")).toISOString().slice(0, 10),
    "2024-03-04"
  );
});

// ============================================================================
// ISO week year boundary (via aggregateByPeriod)
// ============================================================================

test("aggregateByPeriod: 2024-12-30 and 2025-01-05 both land in 2025-W01", () => {
  // 2024-12-30 is the Monday of the week whose Thursday (2025-01-02) falls in 2025 → 2025-W01
  // 2025-01-05 is the Sunday of that same week
  // 2024-12-29 is Sunday of the prior week → 2024-W52
  const records = [
    makeRecord({ timestamp: new Date("2024-12-30T00:00:00Z") }),
    makeRecord({ timestamp: new Date("2025-01-05T00:00:00Z") }),
    makeRecord({ timestamp: new Date("2024-12-29T00:00:00Z") }),
  ];

  const report = aggregateByPeriod(records, "week");
  const keys = report.periods.map((p) => p.key);

  assert.ok(keys.includes("2025-W01"), `expected 2025-W01 in: ${keys.join(", ")}`);
  assert.ok(keys.includes("2024-W52"), `expected 2024-W52 in: ${keys.join(", ")}`);
  assert.equal(report.periods.length, 2);

  const w01 = report.periods.find((p) => p.key === "2025-W01")!;
  assert.equal(w01.messageCount, 2);
});

// ============================================================================
// aggregateByModel
// ============================================================================

test("aggregateByModel: groups by provider/model, sorts by cost descending, totals match", () => {
  const records = [
    makeRecord({
      model: "sonnet", provider: "anthropic",
      cost: { input: 1, output: 2, cacheRead: 0, cacheWrite: 0, total: 3 },
      tokens: { input: 100, output: 50, cacheRead: 0, cacheWrite: 0, total: 150 },
    }),
    makeRecord({
      model: "haiku", provider: "anthropic",
      cost: { input: 0.1, output: 0.1, cacheRead: 0, cacheWrite: 0, total: 0.2 },
      tokens: { input: 50, output: 25, cacheRead: 0, cacheWrite: 0, total: 75 },
    }),
    makeRecord({
      model: "sonnet", provider: "anthropic",
      cost: { input: 2, output: 1, cacheRead: 0, cacheWrite: 0, total: 3 },
      tokens: { input: 120, output: 60, cacheRead: 0, cacheWrite: 0, total: 180 },
    }),
  ];

  const report = aggregateByModel(records);

  assert.equal(report.models.length, 2);
  // sorted by total cost descending
  assert.equal(report.models[0].model, "sonnet");
  assert.equal(report.models[0].messageCount, 2);
  assert.equal(report.models[0].cost.total, 6);
  assert.equal(report.models[1].model, "haiku");
  assert.equal(report.models[1].messageCount, 1);

  // totals match sum of models
  assert.equal(report.totals.messageCount, 3);
  assert.ok(Math.abs(report.totals.cost.total - 6.2) < 1e-9);
  assert.equal(report.totals.tokens.total, 405);
});

// ============================================================================
// filterByDate
// ============================================================================

test("filterByDate: from-only excludes earlier records", () => {
  const records = [
    makeRecord({ timestamp: new Date("2024-01-01T00:00:00Z") }),
    makeRecord({ timestamp: new Date("2024-06-15T00:00:00Z") }),
    makeRecord({ timestamp: new Date("2024-12-31T00:00:00Z") }),
  ];

  const result = filterByDate(records, { from: new Date("2024-07-01T00:00:00Z") });
  assert.equal(result.length, 1);
  assert.equal(result[0].timestamp.toISOString().slice(0, 10), "2024-12-31");
});

test("filterByDate: to-only excludes later records", () => {
  const records = [
    makeRecord({ timestamp: new Date("2024-01-01T00:00:00Z") }),
    makeRecord({ timestamp: new Date("2024-06-15T00:00:00Z") }),
    makeRecord({ timestamp: new Date("2024-12-31T00:00:00Z") }),
  ];

  const result = filterByDate(records, { to: new Date("2024-07-01T00:00:00Z") });
  assert.equal(result.length, 2);
});

test("filterByDate: empty filter passes all records", () => {
  const records = [
    makeRecord({ timestamp: new Date("2024-01-01T00:00:00Z") }),
    makeRecord({ timestamp: new Date("2024-12-31T00:00:00Z") }),
  ];
  assert.equal(filterByDate(records, {}).length, 2);
});

// ============================================================================
// getAllTimeSummary consistency
// ============================================================================

test("getAllTimeSummary totals match aggregateByModel totals", () => {
  const records = [
    makeRecord({
      model: "a", provider: "p",
      cost: { input: 1, output: 2, cacheRead: 0, cacheWrite: 0, total: 3 },
      tokens: { input: 100, output: 50, cacheRead: 0, cacheWrite: 0, total: 150 },
    }),
    makeRecord({
      model: "b", provider: "p", sessionId: "sess-2",
      cost: { input: 0.5, output: 0.5, cacheRead: 0, cacheWrite: 0, total: 1 },
      tokens: { input: 80, output: 40, cacheRead: 0, cacheWrite: 0, total: 120 },
    }),
  ];

  const summary = getAllTimeSummary(records);
  const byModel = aggregateByModel(records);

  assert.equal(summary.messageCount, byModel.totals.messageCount);
  assert.ok(Math.abs(summary.cost.total - byModel.totals.cost.total) < 1e-9);
  assert.equal(summary.tokens.total, byModel.totals.tokens.total);
  assert.equal(summary.sessionCount, 2); // distinct sessionIds: sess-1, sess-2
});

// ============================================================================
// scanSessions — integration tests with real temp files
// ============================================================================

test("scanSessions: parses a minimal JSONL session file", async () => {
  const dir = await fsp.mkdtemp(path.join(os.tmpdir(), "pi-usage-test-"));
  try {
    const sessionId = "test-session-id";
    const lines = [
      JSON.stringify({
        type: "session", id: sessionId,
        timestamp: "2024-03-15T09:00:00.000Z", cwd: "/home/user",
      }),
      JSON.stringify({
        type: "session_info", id: "e1", parentId: null,
        timestamp: "2024-03-15T09:01:00.000Z", name: "My Session",
      }),
      JSON.stringify({
        type: "message", id: "e2", parentId: "e1",
        timestamp: "2024-03-15T10:00:00.000Z",
        message: {
          role: "assistant", model: "claude-3-5-sonnet", provider: "anthropic",
          timestamp: 1710496800000,
          usage: {
            input: 100, output: 50, cacheRead: 20, cacheWrite: 10, totalTokens: 180,
            cost: { input: 0.001, output: 0.002, cacheRead: 0.0005, cacheWrite: 0.001, total: 0.0045 },
          },
        },
      }),
    ];
    await fsp.writeFile(path.join(dir, "session.jsonl"), lines.join("\n") + "\n");

    const records = await scanSessions(dir);

    assert.equal(records.length, 1);
    assert.equal(records[0].sessionId, sessionId);
    assert.equal(records[0].sessionName, "My Session");
    assert.equal(records[0].model, "claude-3-5-sonnet");
    assert.equal(records[0].provider, "anthropic");
    assert.equal(records[0].cwd, "/home/user");
    assert.equal(records[0].tokens.input, 100);
    assert.equal(records[0].tokens.cacheRead, 20);
    assert.equal(records[0].tokens.total, 180);
    assert.ok(Math.abs(records[0].cost.total - 0.0045) < 1e-9);
  } finally {
    await fsp.rm(dir, { recursive: true });
  }
});

test("scanSessions: recurses into subdirectories and sums all records", async () => {
  const dir = await fsp.mkdtemp(path.join(os.tmpdir(), "pi-usage-test-"));
  try {
    const subDir = path.join(dir, "project-x");
    await fsp.mkdir(subDir);

    const writeSession = async (filePath: string, sessionId: string, msgCount: number) => {
      const lines = [
        JSON.stringify({ type: "session", id: sessionId, timestamp: "2024-03-15T09:00:00.000Z", cwd: "/cwd" }),
      ];
      for (let i = 0; i < msgCount; i++) {
        lines.push(JSON.stringify({
          type: "message", id: `e${i}`, parentId: null,
          timestamp: "2024-03-15T10:00:00.000Z",
          message: {
            role: "assistant", model: "m", provider: "p", timestamp: 1710496800000,
            usage: { input: 10, output: 5, totalTokens: 15, cost: { input: 0.001, output: 0.001, total: 0.002 } },
          },
        }));
      }
      await fsp.writeFile(filePath, lines.join("\n") + "\n");
    };

    await writeSession(path.join(dir, "sess1.jsonl"), "id-1", 3);
    await writeSession(path.join(subDir, "sess2.jsonl"), "id-2", 2);

    const records = await scanSessions(dir);
    assert.equal(records.length, 5); // 3 + 2
  } finally {
    await fsp.rm(dir, { recursive: true });
  }
});

test("scanSessions: sessionName comes from the last session_info in the file", async () => {
  const dir = await fsp.mkdtemp(path.join(os.tmpdir(), "pi-usage-test-"));
  try {
    const lines = [
      JSON.stringify({ type: "session", id: "s1", timestamp: "2024-03-15T09:00:00.000Z", cwd: "/c" }),
      JSON.stringify({ type: "session_info", id: "e1", parentId: null, timestamp: "2024-03-15T09:01:00.000Z", name: "First Name" }),
      JSON.stringify({
        type: "message", id: "e2", parentId: "e1", timestamp: "2024-03-15T10:00:00.000Z",
        message: { role: "assistant", model: "m", provider: "p", timestamp: 1710496800000,
          usage: { input: 1, output: 1, totalTokens: 2, cost: { input: 0, output: 0, total: 0 } } },
      }),
      JSON.stringify({ type: "session_info", id: "e3", parentId: "e2", timestamp: "2024-03-15T11:00:00.000Z", name: "Renamed Session" }),
    ];
    await fsp.writeFile(path.join(dir, "s.jsonl"), lines.join("\n") + "\n");

    const records = await scanSessions(dir);
    assert.equal(records.length, 1);
    // The message appears before the rename, but the final session_info wins
    assert.equal(records[0].sessionName, "Renamed Session");
  } finally {
    await fsp.rm(dir, { recursive: true });
  }
});
