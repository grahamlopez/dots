/**
 * Planner Extension — structured planning + deterministic task dispatch
 *
 * Workflow:
 *   1. /plan — enter planning mode (read-only exploration)
 *   2. Agent explores codebase, calls submit_plan with structured JSON
 *   3. /plan-execute — dispatches tasks to isolated subagent processes
 *
 * The key insight: the planning agent makes decisions, the middleware
 * (this extension) deterministically scopes context, and the implementation
 * agents execute with just their task brief — no full plan, no re-reasoning.
 *
 * In tmux (default): each sub-agent opens in its own pane in a dedicated
 * execution window, so you can watch it work and steer when needed.
 * Results are read back from the sub-agent's session file.
 *
 * Commands:
 *   /plan          — toggle planning mode
 *   /plan-execute  — run all pending tasks (or /plan-execute task-1 for one)
 *   /plan-status   — show plan progress
 *   /plan-clear    — clear the current plan
 *
 * Shortcut:
 *   Ctrl+Alt+P — toggle planning mode
 */

import * as crypto from "node:crypto";
import * as fs from "node:fs";
import * as path from "node:path";
import { isToolCallEventType, type ExtensionAPI, type ExtensionContext } from "@mariozechner/pi-coding-agent";
import { Container, Key, Spacer, Text } from "@mariozechner/pi-tui";
import type { AutocompleteItem } from "@mariozechner/pi-tui";
import { PlanSchema, type Plan, type PlanState, type Task, type TaskResult, type TaskStatus } from "./types.js";
import { assembleTaskBrief } from "./brief.js";
import { parseOutput, spawnImplementer } from "./runner.js";
import {
	isTmuxAvailable,
	resetExecutionWindow,
	getOriginalWindowId,
	selectWindow,
	spawnInTmuxPane,
} from "./tmux-runner.js";
import {
	cleanupWorktree,
	commitIfDirty,
	createTaskWorktree,
	isGitRepo,
	mergeBack,
	symlinkDeps,
	type WorktreeInfo,
} from "./worktree.js";

// ---------------------------------------------------------------------------
// Bash safety — adapted from plan-mode example
// ---------------------------------------------------------------------------

const DESTRUCTIVE = [
	/\brm\b/i,
	/\brmdir\b/i,
	/\bmv\b/i,
	/\bcp\b/i,
	/\bmkdir\b/i,
	/\btouch\b/i,
	/\bchmod\b/i,
	/\bchown\b/i,
	/\bln\b/i,
	/\btee\b/i,
	/\btruncate\b/i,
	/(^|[^<])>(?!>)/,
	/>>/,
	/\bnpm\s+(install|uninstall|update|ci|link|publish)/i,
	/\byarn\s+(add|remove|install|publish)/i,
	/\bpnpm\s+(add|remove|install|publish)/i,
	/\bgit\s+(add|commit|push|pull|merge|rebase|reset|checkout|branch\s+-[dD]|stash|cherry-pick|revert)/i,
	/\bsudo\b/i,
	/\bkill\b/i,
	/\bpkill\b/i,
];

const SAFE = [
	/^\s*cat\b/,
	/^\s*head\b/,
	/^\s*tail\b/,
	/^\s*less\b/,
	/^\s*more\b/,
	/^\s*grep\b/,
	/^\s*rg\b/,
	/^\s*find\b/,
	/^\s*fd\b/,
	/^\s*ls\b/,
	/^\s*pwd\b/,
	/^\s*tree\b/,
	/^\s*wc\b/,
	/^\s*sort\b/,
	/^\s*uniq\b/,
	/^\s*diff\b/,
	/^\s*file\b/,
	/^\s*stat\b/,
	/^\s*du\b/,
	/^\s*df\b/,
	/^\s*echo\b/,
	/^\s*printf\b/,
	/^\s*env\b/,
	/^\s*which\b/,
	/^\s*type\b/,
	/^\s*uname\b/,
	/^\s*whoami\b/,
	/^\s*date\b/,
	/^\s*uptime\b/,
	/^\s*git\s+(status|log|diff|show|branch|remote|config\s+--get)/i,
	/^\s*git\s+ls-/i,
	/^\s*npm\s+(list|ls|view|info|outdated|audit)/i,
	/^\s*node\s+--version/i,
	/^\s*jq\b/,
	/^\s*sed\s+-n/i,
	/^\s*awk\b/,
	/^\s*curl\b/,
	/^\s*wget\b/,
	/^\s*bat\b/,
	/^\s*exa\b/,
	/^\s*tsc\b/,
	/^\s*python3?\s+--version/i,
];

function isSafeCommand(cmd: string): boolean {
	return !DESTRUCTIVE.some((p) => p.test(cmd)) && SAFE.some((p) => p.test(cmd));
}

// ---------------------------------------------------------------------------
// Status icons/colors
// ---------------------------------------------------------------------------

const STATUS_ICON: Record<TaskStatus, string> = {
	pending: "○",
	running: "⏳",
	done: "✓",
	failed: "✗",
	skipped: "⊘",
};

const STATUS_COLOR: Record<TaskStatus, string> = {
	pending: "muted",
	running: "warning",
	done: "success",
	failed: "error",
	skipped: "dim",
};

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

function slugify(text: string): string {
	return text
		.toLowerCase()
		.replace(/[^a-z0-9]+/g, "-")
		.replace(/^-|-$/g, "")
		.slice(0, 60);
}

function planLabel(id: string, goal: string): string {
	return `${id}-${slugify(goal).slice(0, 15).replace(/-$/, "")}`;
}

function generatePlanMarkdown(plan: Plan): string {
	const lines: string[] = [];
	lines.push(`# ${plan.goal}`, "");
	lines.push("## Context", "", plan.context, "");
	if (plan.defaultModel) {
		lines.push(`**Default Model:** ${plan.defaultModel}`, "");
	}
	lines.push(`## Tasks (${plan.tasks.length})`, "");
	for (const t of plan.tasks) {
		const deps = t.dependsOn.length > 0 ? t.dependsOn.join(", ") : "none";
		lines.push(`### ${t.id}: ${t.title}`, "");
		lines.push(`**Goal:** ${t.goal}`, "");
		if (t.files.length > 0) {
			lines.push("**Files:**");
			for (const f of t.files) lines.push(`- \`${f}\``);
			lines.push("");
		}
		if (t.constraints.length > 0) {
			lines.push("**Constraints:**");
			for (const c of t.constraints) lines.push(`- ${c}`);
			lines.push("");
		}
		if (t.acceptance.length > 0) {
			lines.push("**Acceptance Criteria:**");
			for (const a of t.acceptance) lines.push(`- ${a}`);
			lines.push("");
		}
		lines.push(`**Depends on:** ${deps}`, "");
		if (t.model) lines.push(`**Model:** ${t.model}`, "");
	}
	return lines.join("\n");
}

function fmtNum(n: number): string {
	return n.toLocaleString();
}

function fmtCost(n: number): string {
	return `$${n.toFixed(4)}`;
}

interface UsageRow {
	label: string;
	input: number;
	output: number;
	cacheRead: number;
	cacheWrite: number;
	cost: number;
	turns: number;
	model?: string;
}

function formatUsageTable(rows: UsageRow[]): string {
	const total: UsageRow = { label: "**Total**", input: 0, output: 0, cacheRead: 0, cacheWrite: 0, cost: 0, turns: 0 };
	for (const r of rows) {
		total.input += r.input;
		total.output += r.output;
		total.cacheRead += r.cacheRead;
		total.cacheWrite += r.cacheWrite;
		total.cost += r.cost;
		total.turns += r.turns;
	}
	const lines: string[] = [];
	lines.push("| Phase | Input | Output | Cache Read | Cache Write | Cost | Turns | Model |");
	lines.push("|-------|------:|-------:|-----------:|------------:|-----:|------:|-------|");
	for (const r of rows) {
		lines.push(
			`| ${r.label} | ${fmtNum(r.input)} | ${fmtNum(r.output)} | ${fmtNum(r.cacheRead)} | ${fmtNum(r.cacheWrite)} | ${fmtCost(r.cost)} | ${r.turns} | ${r.model ?? ""} |`,
		);
	}
	lines.push(
		`| ${total.label} | **${fmtNum(total.input)}** | **${fmtNum(total.output)}** | **${fmtNum(total.cacheRead)}** | **${fmtNum(total.cacheWrite)}** | **${fmtCost(total.cost)}** | **${total.turns}** | |`,
	);
	return lines.join("\n");
}

// ---------------------------------------------------------------------------
// Extension
// ---------------------------------------------------------------------------

export default function plannerExtension(pi: ExtensionAPI) {
	let state: PlanState | null = null;
	let planMode = false;
	let planningUsage = { input: 0, output: 0, cacheRead: 0, cacheWrite: 0, cost: 0, turns: 0 };
	let planningModel: string | undefined;
	let modelRegistry: ExtensionContext["modelRegistry"] | null = null;

	// -----------------------------------------------------------------------
	// Model resolution helpers
	// -----------------------------------------------------------------------

	/** Resolve the effective model for a task, returning both the value and its source. */
	function resolveTaskModel(task: Task, executeLevelModel?: string): { model: string | undefined; source: string } {
		if (executeLevelModel) return { model: executeLevelModel, source: "--model" };
		if (task.model) return { model: task.model, source: "task" };
		if (state?.plan.defaultModel) return { model: state.plan.defaultModel, source: "plan default" };
		return { model: undefined, source: "sub-agent default" };
	}

	/** Build a pre-execution model summary showing what each task will use. */
	function formatModelSummary(tasks: Task[], executeLevelModel?: string): string {
		const lines: string[] = [];
		for (const t of tasks) {
			const { model, source } = resolveTaskModel(t, executeLevelModel);
			const display = model ?? "(sub-agent default)";
			lines.push(`  ${t.id}: ${t.title} → ${display} (${source})`);
		}
		return lines.join("\n");
	}

	// -----------------------------------------------------------------------
	// State helpers
	// -----------------------------------------------------------------------

	function save() {
		if (state) pi.appendEntry("planner-state", { ...state });
	}

	/** Find tasks that are pending and have all dependencies completed. */
	function getReady(): Task[] {
		if (!state) return [];
		return state.plan.tasks.filter((t) => {
			if (state!.statuses[t.id] !== "pending") return false;
			return t.dependsOn.every((d) => state!.statuses[d] === "done");
		});
	}

	/** Mark all transitive dependents of a failed task as skipped. */
	function skipDependents(failedId: string) {
		if (!state) return;
		const queue = [failedId];
		const visited = new Set<string>();
		while (queue.length > 0) {
			const id = queue.shift()!;
			for (const t of state.plan.tasks) {
				if (t.dependsOn.includes(id) && !visited.has(t.id)) {
					visited.add(t.id);
					if (state.statuses[t.id] === "pending") {
						state.statuses[t.id] = "skipped";
					}
					queue.push(t.id);
				}
			}
		}
	}

	/** After a task succeeds, reset any skipped tasks whose deps are now all done. */
	function resetReadySkipped() {
		if (!state) return;
		let changed = true;
		while (changed) {
			changed = false;
			for (const t of state.plan.tasks) {
				if (state.statuses[t.id] === "skipped") {
					if (t.dependsOn.every((d) => state!.statuses[d] === "done")) {
						state.statuses[t.id] = "pending";
						changed = true;
					}
				}
			}
		}
	}

	// -----------------------------------------------------------------------
	// UI
	// -----------------------------------------------------------------------

	function updateUI(ctx: ExtensionContext) {
		const th = ctx.ui.theme;

		if (!state) {
			ctx.ui.setStatus("planner", planMode ? th.fg("warning", "📝 plan") : undefined);
			ctx.ui.setWidget("planner", undefined);
			return;
		}

		const tasks = state.plan.tasks;
		const counts: Record<TaskStatus, number> = { pending: 0, running: 0, done: 0, failed: 0, skipped: 0 };
		for (const t of tasks) counts[state.statuses[t.id]]++;

		// Footer status
		if (planMode) {
			ctx.ui.setStatus("planner", th.fg("warning", "📝 plan"));
		} else if (counts.running > 0) {
			ctx.ui.setStatus("planner", th.fg("accent", `⚡ ${counts.done}/${tasks.length}`));
		} else if (counts.done + counts.failed + counts.skipped === tasks.length) {
			const color = counts.failed > 0 ? "warning" : "success";
			const icon = counts.failed > 0 ? "⚠" : "✓";
			ctx.ui.setStatus("planner", th.fg(color, `${icon} ${counts.done}/${tasks.length}`));
		} else {
			ctx.ui.setStatus("planner", th.fg("accent", `📋 ${tasks.length} tasks`));
		}

		// Widget — task list
		const lines = tasks.map((t) => {
			const s = state!.statuses[t.id];
			const icon = th.fg(STATUS_COLOR[s] as any, STATUS_ICON[s]);
			const title = s === "done" ? th.fg("muted", th.strikethrough(t.title)) : t.title;
			const cost = state!.results[t.id]?.usage.cost;
			const suffix = cost ? th.fg("dim", ` $${cost.toFixed(3)}`) : "";
			return `${icon} ${th.fg("dim", t.id)} ${title}${suffix}`;
		});
		ctx.ui.setWidget("planner", lines);
	}

	// -----------------------------------------------------------------------
	// Task execution
	// -----------------------------------------------------------------------

	/**
	 * Run a single task. When useWorktree is true, the task runs in an
	 * isolated git worktree and merges back on completion.
	 *
	 * When useTmux is true, the task runs in an interactive pi instance
	 * in its own tmux pane — the user can watch and steer it. Results
	 * are read from the sub-agent's session file after it exits.
	 *
	 * Merge-back is serialized via mergeQueue — only one merge runs at a
	 * time to keep main's history linear and ensure each rebase sees the
	 * latest HEAD.
	 */

	let mergeQueue: Promise<void> = Promise.resolve();

	async function runTask(task: Task, ctx: ExtensionContext, useWorktree: boolean = false, useTmux: boolean = false, executeLevelModel?: string): Promise<void> {
		state!.statuses[task.id] = "running";
		updateUI(ctx);

		const brief = assembleTaskBrief(task, state!.plan, state!.results);

		// Resolve effective model: executeLevelModel > task.model > plan.defaultModel > omit
		const { model: effectiveModel } = resolveTaskModel(task, executeLevelModel);

		let wt: WorktreeInfo | null = null;
		let taskCwd = ctx.cwd;

		try {
			// --- Set up worktree if requested ---
			if (useWorktree) {
				wt = createTaskWorktree(ctx.cwd, state!.planId, task.id);
				symlinkDeps(ctx.cwd, wt.path);
				taskCwd = wt.path;
			}

			// --- Run the subagent (tmux pane or headless) ---
			const output = useTmux
				? await spawnInTmuxPane({
						cwd: taskCwd,
						prompt: brief,
						taskId: task.id,
						taskTitle: task.title,
						planLabel: planLabel(state!.planId, state!.plan.goal),
						model: effectiveModel,
					})
				: await spawnImplementer({
						cwd: taskCwd,
						prompt: brief,
						model: effectiveModel,
					});

			const { summary, filesChanged, notes } = parseOutput(output.messages);
			const isError = output.exitCode !== 0;

			state!.results[task.id] = {
				taskId: task.id,
				title: task.title,
				exitCode: output.exitCode,
				summary,
				filesChanged,
				notes,
				error: isError ? output.stderr.slice(0, 500) || summary : undefined,
				usage: output.usage,
				model: output.model,
			};

			if (isError) {
				state!.statuses[task.id] = "failed";
				skipDependents(task.id);
			} else if (wt) {
				// --- Merge back (serialized through the queue) ---
				await (mergeQueue = mergeQueue.then(async () => {
					commitIfDirty(wt!.path, task.id, task.title);
					const result = mergeBack(ctx.cwd, wt!);

					if (!result.success) {
						const conflictMsg = result.conflictFiles?.length
							? `Conflicts in: ${result.conflictFiles.join(", ")}`
							: result.conflicts || "Unknown merge conflict";

						state!.results[task.id].error = conflictMsg;
						state!.statuses[task.id] = "failed";
						skipDependents(task.id);

						pi.sendMessage(
							{
								customType: "planner-task-result",
								content:
									`**⚠ ${task.id}: ${task.title} — merge conflict**\n\n${conflictMsg}` +
									`\n\nWorktree left at \`${wt!.path}\` for manual resolution.`,
								display: true,
							},
							{ triggerTurn: false },
						);
						return; // Don't clean up — user needs the worktree
					}

					// Clean up on successful merge
					cleanupWorktree(ctx.cwd, wt!);
					wt = null; // Prevent double-cleanup in finally
				}));

				if (state!.statuses[task.id] !== "failed") {
					state!.statuses[task.id] = "done";
					resetReadySkipped();
				}
			} else {
				state!.statuses[task.id] = "done";
				resetReadySkipped();
			}

			// Notify in the TUI (unless merge conflict already sent a message)
			if (state!.statuses[task.id] !== "failed" || !wt) {
				const isErr = state!.statuses[task.id] === "failed";
				const icon = isErr ? "✗" : "✓";
				const cost = output.usage.cost > 0 ? ` ($${output.usage.cost.toFixed(3)})` : "";
				const modelTag = ` [${effectiveModel ?? "(default)"}]`;
				let content = `**${icon} ${task.id}: ${task.title}${cost}${modelTag}**\n\n${summary}`;
				if (notes) content += `\n\n**Notes:** ${notes}`;
				pi.sendMessage(
					{
						customType: "planner-task-result",
						content,
						display: true,
					},
					{ triggerTurn: false },
				);
			}
		} catch (err: any) {
			state!.results[task.id] = {
				taskId: task.id,
				title: task.title,
				exitCode: 1,
				summary: "",
				filesChanged: [],
				notes: "",
				error: err.message,
				usage: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0, cost: 0, turns: 0 },
			};
			state!.statuses[task.id] = "failed";
			skipDependents(task.id);
		} finally {
			// Clean up worktree on failure (but not on merge conflict — user needs it)
			if (wt && state!.statuses[task.id] === "failed" && !state!.results[task.id]?.error?.includes("onflict")) {
				cleanupWorktree(ctx.cwd, wt);
			}
		}

		save();
		updateUI(ctx);
	}

	// -----------------------------------------------------------------------
	// submit_plan tool
	// -----------------------------------------------------------------------

	pi.registerTool({
		name: "submit_plan",
		label: "Submit Plan",
		description: "Submit a structured implementation plan for deterministic task dispatch to isolated subagents.",
		promptSnippet: "Submit a structured plan with tasks, dependencies, goals, and acceptance criteria",
		parameters: PlanSchema,

		async execute(_id, plan, _signal, _onUpdate, ctx) {
			// Validate dependency references
			const ids = new Set(plan.tasks.map((t: Task) => t.id));
			for (const t of plan.tasks) {
				for (const d of t.dependsOn) {
					if (!ids.has(d)) throw new Error(`Task '${t.id}' depends on unknown task '${d}'`);
				}
			}

			// Cycle detection (DFS)
			const visited = new Set<string>();
			const stack = new Set<string>();
			const taskMap = new Map(plan.tasks.map((t: Task) => [t.id, t]));

			function hasCycle(id: string): boolean {
				if (stack.has(id)) return true;
				if (visited.has(id)) return false;
				visited.add(id);
				stack.add(id);
				for (const d of taskMap.get(id)?.dependsOn ?? []) {
					if (hasCycle(d)) return true;
				}
				stack.delete(id);
				return false;
			}

			for (const t of plan.tasks) {
				if (hasCycle(t.id)) throw new Error(`Dependency cycle detected involving '${t.id}'`);
			}

			// Initialize plan state
			const planId = crypto.createHash("sha1").update(`${plan.goal}:${Date.now()}`).digest("hex").slice(0, 4);
			const statuses: Record<string, TaskStatus> = {};
			for (const t of plan.tasks) statuses[t.id] = "pending";
			state = {
				plan,
				planId,
				statuses,
				results: {},
				planningUsage: { ...planningUsage },
				planningModel,
				planFile: undefined,
			};

			// Write human-readable plan to docs/plans/
			const plansDir = path.join(ctx.cwd, "docs", "plans");
			let planWritten = false;

			const planFileName = `${planLabel(planId, plan.goal)}.md`;

			if (fs.existsSync(plansDir)) {
				const planFile = path.join(plansDir, planFileName);
				fs.writeFileSync(planFile, generatePlanMarkdown(plan), "utf-8");
				state.planFile = path.relative(ctx.cwd, planFile);
				planWritten = true;
			} else if (ctx.hasUI) {
				const ok = await ctx.ui.confirm(
					"Create plans directory?",
					`\`docs/plans/\` doesn't exist in this project. Create it to save a human-readable plan?`,
				);
				if (ok) {
					fs.mkdirSync(plansDir, { recursive: true });
					const planFile = path.join(plansDir, planFileName);
					fs.writeFileSync(planFile, generatePlanMarkdown(plan), "utf-8");
					state.planFile = path.relative(ctx.cwd, planFile);
					planWritten = true;
				}
			}

			// Exit plan mode now that we have a plan
			if (planMode) planMode = false;

			save();
			updateUI(ctx);

			const fileMsg = planWritten ? ` Plan saved to \`${state.planFile}\`.` : "";
			return {
				content: [
					{
						type: "text",
						text: `Plan "${plan.goal}" submitted with ${plan.tasks.length} tasks.${fileMsg} Use /plan-execute to run.`,
					},
				],
				details: { plan },
			};
		},

		renderCall(args, theme) {
			const n = args.tasks?.length ?? 0;
			return new Text(
				theme.fg("toolTitle", theme.bold("submit_plan ")) +
					theme.fg("accent", `${n} tasks`) +
					(args.goal ? theme.fg("dim", ` — ${args.goal}`) : ""),
				0,
				0,
			);
		},

		renderResult(result, { expanded }, theme) {
			const plan = result.details?.plan as Plan | undefined;
			if (!plan) {
				return new Text(result.content[0]?.type === "text" ? result.content[0].text : "", 0, 0);
			}

			if (!expanded) {
				let text =
					theme.fg("success", "✓ ") +
					theme.fg("toolTitle", theme.bold(plan.goal)) +
					theme.fg("dim", ` (${plan.tasks.length} tasks)`);
				if (plan.defaultModel) {
					text += theme.fg("dim", ` · model: ${plan.defaultModel}`);
				}
				for (const t of plan.tasks) {
					const deps =
						t.dependsOn.length > 0
							? theme.fg("dim", ` → ${t.dependsOn.join(", ")}`)
							: theme.fg("dim", " (independent)");
					text += `\n  ${theme.fg("muted", t.id)} ${t.title}${deps}`;
				}
				text += `\n\n${theme.fg("muted", "/plan-execute to run · Ctrl+O to expand")}`;
				return new Text(text, 0, 0);
			}

			const c = new Container();
			c.addChild(
				new Text(theme.fg("success", "✓ ") + theme.fg("toolTitle", theme.bold(plan.goal)), 0, 0),
			);
			c.addChild(new Text(theme.fg("dim", plan.context), 0, 0));
			if (plan.defaultModel) {
				c.addChild(new Text(theme.fg("dim", `Default model: ${plan.defaultModel}`), 0, 0));
			}

			for (const t of plan.tasks) {
				c.addChild(new Spacer(1));
				const deps = t.dependsOn.length > 0 ? theme.fg("dim", ` → ${t.dependsOn.join(", ")}`) : "";
				c.addChild(new Text(theme.fg("accent", `${t.id}: ${t.title}`) + deps, 0, 0));
				c.addChild(new Text(theme.fg("toolOutput", t.goal), 0, 0));
				if (t.files.length > 0) {
					c.addChild(new Text(theme.fg("dim", `Files: ${t.files.join(", ")}`), 0, 0));
				}
				if (t.constraints.length > 0) {
					c.addChild(new Text(theme.fg("warning", `Constraints: ${t.constraints.join(" · ")}`), 0, 0));
				}
				if (t.acceptance.length > 0) {
					c.addChild(new Text(theme.fg("muted", `Done when: ${t.acceptance.join(" · ")}`), 0, 0));
				}
			}

			c.addChild(new Spacer(1));
			c.addChild(new Text(theme.fg("muted", "/plan-execute to run"), 0, 0));
			return c;
		},
	});

	// -----------------------------------------------------------------------
	// /plan — toggle planning mode
	// -----------------------------------------------------------------------

	pi.registerCommand("plan", {
		description: "Toggle planning mode. Use '/plan compact' to compact brainstorm context first.",

		getArgumentCompletions: (prefix: string): AutocompleteItem[] | null => {
			const items = [{ value: "compact", label: "compact — compact conversation before planning" }];
			const filtered = items.filter((i) => i.value.startsWith(prefix));
			return filtered.length > 0 ? filtered : null;
		},

		handler: async (args, ctx) => {
			const arg = args.trim().toLowerCase();

			// Toggle off
			if (planMode && arg !== "compact") {
				planMode = false;
				ctx.ui.notify("Plan mode OFF.", "info");
				updateUI(ctx);
				return;
			}

			// Toggle on (with optional compaction)
			planMode = true;
			planningUsage = { input: 0, output: 0, cacheRead: 0, cacheWrite: 0, cost: 0, turns: 0 };
			planningModel = undefined;
			updateUI(ctx);

			if (arg === "compact") {
				ctx.ui.notify("Compacting brainstorm context, then entering plan mode...", "info");
				ctx.compact({
					customInstructions:
						"Summarize the brainstorming session. Preserve all decisions made, architectural choices, " +
						"constraints agreed upon, and the overall goal. Discard exploratory tangents and rejected ideas. " +
						"The summary will be used by a planning agent to create an implementation plan.",
					onComplete: () => {
						ctx.ui.notify("Plan mode ON — brainstorm compacted. Explore codebase and build a plan.", "success");
					},
					onError: (err) => {
						ctx.ui.notify(`Compaction failed: ${err.message}. Plan mode still active.`, "warning");
					},
				});
			} else {
				ctx.ui.notify("Plan mode ON — explore codebase and build a plan.", "info");
			}
		},
	});

	// -----------------------------------------------------------------------
	// /plan-execute — dispatch tasks to subagents
	// -----------------------------------------------------------------------

	pi.registerCommand("plan-execute", {
		description: "Execute plan tasks. Usage: /plan-execute [--hierarchical] [--no-tmux] [--model <model>] [task-id]",

		getArgumentCompletions: (prefix: string): AutocompleteItem[] | null => {
			if (!state) return null;

			// If the user just typed "--model ", complete with available model IDs
			const modelArgMatch = prefix.match(/^--model\s+(.*)$/);
			if (modelArgMatch) {
				const modelPrefix = modelArgMatch[1];
				const models = modelRegistry?.getAvailable() ?? [];
				const items: AutocompleteItem[] = models.map((m) => ({
					value: `--model ${m.provider}/${m.id}`,
					label: `${m.provider}/${m.id} — ${m.name}`,
				}));
				const filtered = items.filter((i) => i.value.startsWith(`--model ${modelPrefix}`));
				return filtered.length > 0 ? filtered : null;
			}

			const items: AutocompleteItem[] = [
				{ value: "--hierarchical", label: "--hierarchical — serial execution, no worktrees" },
				{ value: "--no-tmux", label: "--no-tmux — headless execution (no tmux panes)" },
				{ value: "--model", label: "--model <model> — override model for all tasks" },
				...state.plan.tasks.map((t) => ({
					value: t.id,
					label: `${t.id} — ${t.title} [${state!.statuses[t.id]}]`,
				})),
			];
			const filtered = items.filter((i) => i.value.startsWith(prefix));
			return filtered.length > 0 ? filtered : null;
		},

		handler: async (args, ctx) => {
			if (!state) {
				ctx.ui.notify("No plan. Use /plan to create one, then submit_plan.", "error");
				return;
			}

			await ctx.waitForIdle();

			// Parse args: flags and optional task-id
			const parts = args.trim().split(/\s+/).filter(Boolean);
			const hierarchical = parts.includes("--hierarchical");
			const noTmux = parts.includes("--no-tmux");

			// Parse --model <value> flag
			let executeLevelModel: string | undefined;
			const modelIdx = parts.indexOf("--model");
			if (modelIdx !== -1) {
				executeLevelModel = parts[modelIdx + 1];
				if (!executeLevelModel || executeLevelModel.startsWith("--")) {
					ctx.ui.notify("--model requires a value, e.g. --model claude-sonnet-4-5", "error");
					return;
				}
				// Remove --model and its value from parts for targetId detection
				parts.splice(modelIdx, 2);
			}

			const targetId = parts.find((p) => !p.startsWith("--")) || null;

			// Tmux mode: default on when inside tmux, opt-out with --no-tmux
			const useTmux = !noTmux && isTmuxAvailable();

			// Determine whether to use worktrees for parallel tasks.
			// Default: use worktrees if in a git repo (safe parallel execution).
			// --hierarchical: serial execution, no worktrees (simpler, slower).
			const inGitRepo = isGitRepo(ctx.cwd);
			const useWorktrees = inGitRepo && !hierarchical;

			// --- Tmux window lifecycle ---
			let originalWindowId: string | undefined;
			if (useTmux) {
				resetExecutionWindow();
				originalWindowId = getOriginalWindowId();
			}

			try {
				// --- Single task mode ---
				if (targetId) {
					const task = state.plan.tasks.find((t) => t.id === targetId);
					if (!task) {
						ctx.ui.notify(`Unknown task: ${targetId}`, "error");
						return;
					}

					const unmet = task.dependsOn.filter((d) => state!.statuses[d] !== "done");
					if (unmet.length > 0) {
						ctx.ui.notify(`Cannot run ${targetId}: waiting on ${unmet.join(", ")}`, "error");
						return;
					}

					// Reset if previously failed/skipped
					if (state.statuses[task.id] === "failed" || state.statuses[task.id] === "skipped") {
						state.statuses[task.id] = "pending";
					}

					// Confirm re-run of completed tasks
					if (state.statuses[task.id] === "done") {
						if (ctx.hasUI) {
							const ok = await ctx.ui.confirm("Re-run?", `${task.title} already completed. Re-run?`);
							if (!ok) return;
						}
						state.statuses[task.id] = "pending";
					}

					const { model: taskModel, source: taskModelSource } = resolveTaskModel(task, executeLevelModel);
					ctx.ui.notify(`Executing: ${task.id}: ${task.title}\nModel: ${taskModel ?? "(sub-agent default)"} (${taskModelSource})`, "info");
					await runTask(task, ctx, false, useTmux, executeLevelModel);
					return;
				}

				// --- Full plan execution (pool-based DAG scheduler) ---
				const pending = state.plan.tasks.filter((t) => state!.statuses[t.id] === "pending");
				if (pending.length === 0) {
					ctx.ui.notify(
						"No pending tasks. Use /plan-clear to reset or /plan-execute <task-id> to re-run one.",
						"info",
					);
					return;
				}

				if (!inGitRepo && !hierarchical) {
					ctx.ui.notify(
						"⚠ Not a git repo — parallel tasks will share the working directory. " +
							"Use /plan-execute --hierarchical for serial execution, or initialize a git repo.",
						"warning",
					);
				}

				const tmuxLabel = useTmux ? ", tmux" : "";
				const mode = useWorktrees
					? `parallel (worktrees${tmuxLabel})`
					: hierarchical
						? `serial${tmuxLabel}`
						: `parallel (shared dir${tmuxLabel})`;
				const modelSummary = formatModelSummary(pending, executeLevelModel);
				ctx.ui.notify(`Executing: ${state.plan.goal} (${pending.length} tasks, ${mode})\n\nModels:\n${modelSummary}`, "info");

				const MAX_CONCURRENCY = hierarchical ? 1 : 4;
				let running = 0;

				// When using worktrees, all tasks get their own worktree for isolation.
				// Merge-back is serialized via mergeQueue in runTask to keep history linear.
				await new Promise<void>((resolveAll) => {
					function tryStart() {
						while (running < MAX_CONCURRENCY) {
							const ready = getReady();
							if (ready.length === 0) {
								if (running === 0) resolveAll();
								return;
							}
							const task = ready[0];
							running++;
							// Use worktrees when parallel AND in a git repo
							const worktreeForTask = useWorktrees && MAX_CONCURRENCY > 1;
							runTask(task, ctx, worktreeForTask, useTmux, executeLevelModel).finally(() => {
								running--;
								tryStart();
							});
						}
					}
					tryStart();
				});
			} finally {
				// Switch back to the planner window when execution completes
				if (useTmux && originalWindowId) {
					selectWindow(originalWindowId);
				}
			}

			// --- Final summary ---
			const counts: Record<TaskStatus, number> = { pending: 0, running: 0, done: 0, failed: 0, skipped: 0 };
			for (const t of state.plan.tasks) counts[state.statuses[t.id]]++;

			let summary = `## Plan Execution Complete\n\n${counts.done}/${state.plan.tasks.length} done`;
			if (counts.failed > 0) summary += `, ${counts.failed} failed`;
			if (counts.skipped > 0) summary += `, ${counts.skipped} skipped`;
			if (counts.pending > 0) summary += `, ${counts.pending} still pending`;
			summary += "\n\n";

			for (const t of state.plan.tasks) {
				const s = state.statuses[t.id];
				const r = state.results[t.id];
				summary += `${STATUS_ICON[s]} **${t.id}**: ${t.title} [${s}]`;
				if (r?.summary) summary += ` — ${r.summary}`;
				if (r?.error) summary += ` — ERROR: ${r.error.slice(0, 200)}`;
				if (r?.usage.cost) summary += ` ($${r.usage.cost.toFixed(3)})`;
				summary += "\n";
			}

			// --- Token usage table ---
			const usageRows: UsageRow[] = [];
			if (state.planningUsage && state.planningUsage.turns > 0) {
				usageRows.push({
					label: "Planning",
					...state.planningUsage,
					model: state.planningModel,
				});
			}
			for (const t of state.plan.tasks) {
				const r = state.results[t.id];
				if (r) {
					// Show actual model from spawner, or fall back to resolved model, or (default)
					const { model: resolvedModel } = resolveTaskModel(t, executeLevelModel);
					usageRows.push({
						label: `${t.id}: ${t.title}`,
						input: r.usage.input,
						output: r.usage.output,
						cacheRead: r.usage.cacheRead,
						cacheWrite: r.usage.cacheWrite,
						cost: r.usage.cost,
						turns: r.usage.turns,
						model: r.model ?? resolvedModel ?? "(default)",
					});
				}
			}
			if (usageRows.length > 0) {
				summary += `\n## Token Usage\n\n${formatUsageTable(usageRows)}\n`;
			}

			pi.sendMessage(
				{ customType: "planner-summary", content: summary, display: true },
				{ triggerTurn: false },
			);
		},
	});

	// -----------------------------------------------------------------------
	// /plan-status — show current plan progress
	// -----------------------------------------------------------------------

	pi.registerCommand("plan-status", {
		description: "Show current plan status and token usage",
		handler: async (_args, ctx) => {
			if (!state) {
				ctx.ui.notify("No plan.", "info");
				return;
			}

			const lines = [`Plan: ${state.plan.goal}`, ""];
			if (state.planFile) lines.push(`Plan file: ${state.planFile}`, "");
			for (const t of state.plan.tasks) {
				const s = state.statuses[t.id];
				const r = state.results[t.id];
				let line = `${STATUS_ICON[s]} ${t.id}: ${t.title} [${s}]`;
				if (r?.usage.cost) line += ` $${r.usage.cost.toFixed(3)}`;
				if (r?.error) line += ` — ${r.error.slice(0, 100)}`;
				lines.push(line);
			}

			// Token usage summary
			let totalInput = 0, totalOutput = 0, totalCacheRead = 0, totalCacheWrite = 0, totalCost = 0, totalTurns = 0;
			if (state.planningUsage) {
				totalInput += state.planningUsage.input;
				totalOutput += state.planningUsage.output;
				totalCacheRead += state.planningUsage.cacheRead;
				totalCacheWrite += state.planningUsage.cacheWrite;
				totalCost += state.planningUsage.cost;
				totalTurns += state.planningUsage.turns;
			}
			for (const r of Object.values(state.results)) {
				totalInput += r.usage.input;
				totalOutput += r.usage.output;
				totalCacheRead += r.usage.cacheRead;
				totalCacheWrite += r.usage.cacheWrite;
				totalCost += r.usage.cost;
				totalTurns += r.usage.turns;
			}
			if (totalTurns > 0) {
				lines.push("");
				lines.push(`Tokens: ${fmtNum(totalInput)} in / ${fmtNum(totalOutput)} out / ${fmtNum(totalCacheRead)} cache-read / ${fmtNum(totalCacheWrite)} cache-write`);
				lines.push(`Cost: ${fmtCost(totalCost)} (${totalTurns} turns)`);
			}

			ctx.ui.notify(lines.join("\n"), "info");
		},
	});

	// -----------------------------------------------------------------------
	// /plan-clear — clear the current plan
	// -----------------------------------------------------------------------

	pi.registerCommand("plan-clear", {
		description: "Clear the current plan and all results",
		handler: async (_args, ctx) => {
			if (state && ctx.hasUI) {
				const ok = await ctx.ui.confirm("Clear plan?", `This will clear "${state.plan.goal}" and all results.`);
				if (!ok) return;
			}
			state = null;
			planMode = false;
			updateUI(ctx);
			ctx.ui.notify("Plan cleared.", "info");
		},
	});

	// -----------------------------------------------------------------------
	// Events
	// -----------------------------------------------------------------------

	// Restore state on initial session load
	pi.on("session_start", async (_event, ctx) => {
		modelRegistry = ctx.modelRegistry;
		const entries = ctx.sessionManager.getEntries();
		const last = entries
			.filter((e: any) => e.type === "custom" && e.customType === "planner-state")
			.pop() as any;
		if (last?.data) {
			state = last.data;
			// Don't restore "running" status — those tasks were interrupted
			if (state) {
				for (const t of state.plan.tasks) {
					if (state.statuses[t.id] === "running") {
						state.statuses[t.id] = "pending";
					}
				}
			}
		}
		updateUI(ctx);
	});

	// Clear or restore state on /new and /resume
	pi.on("session_switch", async (event, ctx) => {
		if (event.reason === "new") {
			state = null;
			planMode = false;
		} else {
			// Resuming a session — restore plan state if it has one
			const entries = ctx.sessionManager.getEntries();
			const last = entries
				.filter((e: any) => e.type === "custom" && e.customType === "planner-state")
				.pop() as any;
			if (last?.data) {
				state = last.data;
				if (state) {
					for (const t of state.plan.tasks) {
						if (state.statuses[t.id] === "running") {
							state.statuses[t.id] = "pending";
						}
					}
				}
			} else {
				state = null;
				planMode = false;
			}
		}
		updateUI(ctx);
	});

	// Track token usage during planning mode
	pi.on("message_end", async (event) => {
		if (!planMode) return;
		const msg = event.message as any;
		if (msg.role === "assistant") {
			const u = msg.usage;
			if (u) {
				planningUsage.input += u.input || 0;
				planningUsage.output += u.output || 0;
				planningUsage.cacheRead += u.cacheRead || 0;
				planningUsage.cacheWrite += u.cacheWrite || 0;
				planningUsage.cost += u.cost?.total || 0;
				planningUsage.turns++;
			}
			if (!planningModel && msg.model) planningModel = msg.model;
		}
	});

	// Inject planning context when in plan mode
	pi.on("before_agent_start", async () => {
		if (!planMode) return;
		return {
			message: {
				customType: "planner-context",
				content: `[PLANNING MODE — read-only exploration]

You are in planning mode. Your job:

1. Explore the codebase thoroughly (read, grep, find, bash for read-only commands)
2. Understand the architecture and current state
3. Design an implementation plan
4. Submit it via the submit_plan tool

Guidelines for a good plan:
- Each task goal describes the desired OUTCOME, not step-by-step implementation instructions
- Files are starting points for the implementer to read — not restrictions or inlined content
- Constraints are only for genuine architectural decisions (patterns, conventions, types to use)
- Do NOT constrain implementation details like method signatures, variable names, or exact code
- Acceptance criteria must be concrete and testable (compiles, tests pass, endpoint works)
- Group tightly-coupled changes into one task (touching the same files = same task)
- Split at natural boundaries (different modules, different concerns, clear interfaces)
- Use dependsOn for tasks that consume interfaces/types/files created by earlier tasks
- Independent tasks will run in parallel — don't add unnecessary dependencies
- Use the skills field on tasks to list relevant skill names when the task matches a skill's description. Sub-agents have skill discovery — this ensures they load the right skills.
- Use defaultModel at the plan level to set a model for all tasks (e.g. 'claude-sonnet-4-5'). Individual tasks can override via their own model field. Omit defaultModel to use whatever model the caller specifies.

Do NOT make file changes. Focus on understanding the code and creating a solid plan.`,
				display: false,
			},
		};
	});

	// Block write tools in plan mode
	pi.on("tool_call", async (event) => {
		if (!planMode) return;

		if (event.toolName === "edit" || event.toolName === "write") {
			return { block: true, reason: "Plan mode: write tools disabled. Use /plan to exit planning mode." };
		}

		if (isToolCallEventType("bash", event)) {
			if (!isSafeCommand(event.input.command)) {
				return {
					block: true,
					reason: `Plan mode: destructive command blocked.\nCommand: ${event.input.command}`,
				};
			}
		}
	});

	// Keyboard shortcut
	pi.registerShortcut(Key.ctrlAlt("p"), {
		description: "Toggle plan mode",
		handler: async (ctx) => {
			planMode = !planMode;
			if (planMode) {
				planningUsage = { input: 0, output: 0, cacheRead: 0, cacheWrite: 0, cost: 0, turns: 0 };
				planningModel = undefined;
			}
			ctx.ui.notify(planMode ? "Plan mode ON" : "Plan mode OFF", "info");
			updateUI(ctx);
		},
	});
}
