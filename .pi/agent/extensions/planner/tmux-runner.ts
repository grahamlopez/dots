/**
 * Tmux pane runner — spawns implementation agents as interactive pi instances
 * in tmux panes, allowing the user to watch and steer each sub-agent.
 *
 * Each sub-agent gets:
 *   - Its own tmux pane in a dedicated execution window
 *   - Interactive pi with the implementer system prompt
 *   - The assembled task brief as its initial prompt
 *   - A session file in a temp directory (read back for structured results)
 *   - research and web_fetch tools (explicitly loaded via -e)
 *   - No parent extensions (--no-extensions) for a clean tool set
 *
 * Completion is detected by polling for an exit-code marker file.
 * Results are extracted from the session file via SessionManager.
 *
 * The execution window is created on the first task spawn. Subsequent tasks
 * split panes in the same window. Pane border titles show task IDs.
 */

import { execSync } from "node:child_process";
import * as fs from "node:fs";
import * as os from "node:os";
import * as path from "node:path";
import { SessionManager } from "@mariozechner/pi-coding-agent";
import type { Message } from "@mariozechner/pi-ai";
import type { SubagentOutput } from "./runner.js";
import { IMPLEMENTER_PROMPT } from "./runner.js";

// ---------------------------------------------------------------------------
// Tmux detection
// ---------------------------------------------------------------------------

export function isTmuxAvailable(): boolean {
	return !!process.env.TMUX;
}

// ---------------------------------------------------------------------------
// Execution window state
// ---------------------------------------------------------------------------

/** Pane ID of the first pane in the execution window (used as split target). */
let executionPaneId: string | null = null;

/** Window ID of the execution window (used for layout commands). */
let executionWindowId: string | null = null;

/** Reset state between /plan-execute invocations. */
export function resetExecutionWindow(): void {
	executionPaneId = null;
	executionWindowId = null;
}

/** Get the current tmux window ID (call before creating execution window). */
export function getOriginalWindowId(): string {
	return execSync("tmux display-message -p '#{window_id}'", { encoding: "utf-8" }).trim();
}

/** Switch tmux to a specific window. Safe to call even if window is gone. */
export function selectWindow(windowId: string): void {
	try {
		execSync(`tmux select-window -t ${windowId}`, { stdio: "ignore" });
	} catch {
		// Window may already be closed (all panes exited)
	}
}

// ---------------------------------------------------------------------------
// Shell helpers
// ---------------------------------------------------------------------------

function shellEscape(s: string): string {
	return `'${s.replace(/'/g, "'\\''")}'`;
}

function paneExists(paneId: string): boolean {
	try {
		const result = execSync(`tmux display-message -t ${paneId} -p '#{pane_id}'`, {
			encoding: "utf-8",
			stdio: ["ignore", "pipe", "ignore"],
		});
		return result.trim() === paneId;
	} catch {
		return false;
	}
}

function windowExists(windowId: string): boolean {
	try {
		execSync(`tmux display-message -t ${windowId} -p '#{window_id}'`, {
			encoding: "utf-8",
			stdio: ["ignore", "pipe", "ignore"],
		});
		return true;
	} catch {
		return false;
	}
}

/** Get any live pane in a window (for use as a split target). */
function getAnyPaneInWindow(windowId: string): string | null {
	try {
		const result = execSync(`tmux list-panes -t ${windowId} -F '#{pane_id}'`, {
			encoding: "utf-8",
			stdio: ["ignore", "pipe", "ignore"],
		});
		const first = result.trim().split("\n")[0];
		return first || null;
	} catch {
		return null;
	}
}

// ---------------------------------------------------------------------------
// Main entry point
// ---------------------------------------------------------------------------

export async function spawnInTmuxPane(opts: {
	cwd: string;
	prompt: string;
	taskId: string;
	taskTitle: string;
	planLabel: string;
	model?: string;
	signal?: AbortSignal;
}): Promise<SubagentOutput> {
	// 1. Create temp directory with all required files
	const tmpDir = fs.mkdtempSync(path.join(os.tmpdir(), `pi-plan-${opts.taskId}-`));
	const briefFile = path.join(tmpDir, "brief.md");
	const promptFile = path.join(tmpDir, "implementer.md");
	const sessionDir = path.join(tmpDir, "session");
	const exitCodeFile = path.join(tmpDir, "exit-code");
	const wrapperFile = path.join(tmpDir, "run.sh");

	fs.mkdirSync(sessionDir, { recursive: true });
	fs.writeFileSync(briefFile, opts.prompt, "utf-8");
	fs.writeFileSync(promptFile, IMPLEMENTER_PROMPT, "utf-8");

	// 2. Build the pi command arguments
	const piArgs = ["--no-extensions", "--append-system-prompt", promptFile, "--session-dir", sessionDir];

	// Explicitly load research and web_fetch extensions (allowed even with --no-extensions)
	const extDir = path.join(os.homedir(), ".pi/agent/extensions");
	piArgs.push("-e", path.join(extDir, "research.ts"));
	piArgs.push("-e", path.join(extDir, "web-fetch/index.ts"));

	if (opts.model) piArgs.push("--model", opts.model);
	piArgs.push(`@${briefFile}`);

	// 3. Write wrapper script (handles cleanup on any exit, including kill-pane)
	const wrapperContent = `#!/bin/bash
RESULT_FILE=${shellEscape(exitCodeFile)}
_cleanup() {
  if [ ! -f "$RESULT_FILE" ]; then
    echo 1 > "$RESULT_FILE"
  fi
}
trap _cleanup EXIT HUP TERM INT
pi ${piArgs.map(shellEscape).join(" ")}
echo $? > "$RESULT_FILE"
`;
	fs.writeFileSync(wrapperFile, wrapperContent, { mode: 0o755 });

	// 4. Create tmux pane
	let paneId: string;
	const runCmd = `bash ${shellEscape(wrapperFile)}`;

	try {
		// Determine the best strategy: new window, or split in existing window
		let splitTarget: string | null = null;

		if (executionPaneId) {
			if (paneExists(executionPaneId)) {
				// Happy path — the pane we last split from is still alive
				splitTarget = executionPaneId;
			} else if (executionWindowId && windowExists(executionWindowId)) {
				// The specific pane is gone but the window has other panes — find one
				splitTarget = getAnyPaneInWindow(executionWindowId);
			}
			// If both are gone, splitTarget stays null → we create a new window
		}

		if (!splitTarget) {
			// Create a new tmux window (first task, or previous window is gone)
			paneId = execSync(
				`tmux new-window -P -F '#{pane_id}' -n ${shellEscape(`plan:${opts.planLabel}`)} -c ${shellEscape(opts.cwd)} ${shellEscape(runCmd)}`,
				{ encoding: "utf-8" },
			).trim();
			executionPaneId = paneId;

			// Capture the window ID for layout and navigation
			executionWindowId = execSync(`tmux display-message -t ${paneId} -p '#{window_id}'`, {
				encoding: "utf-8",
			}).trim();

			// Enable pane border titles so task IDs are visible
			try {
				execSync(`tmux set-window-option -t ${executionWindowId} pane-border-status top`, { stdio: "ignore" });
				execSync(`tmux set-window-option -t ${executionWindowId} pane-border-format ' #{pane_title} '`, {
					stdio: "ignore",
				});
			} catch {
				// Non-fatal — pane titles just won't show
			}
		} else {
			// Split in the existing execution window
			paneId = execSync(
				`tmux split-window -d -t ${splitTarget} -P -F '#{pane_id}' -c ${shellEscape(opts.cwd)} ${shellEscape(runCmd)}`,
				{ encoding: "utf-8" },
			).trim();

			// Update the tracked pane to this new (live) one
			executionPaneId = paneId;

			// Re-tile so panes are evenly arranged
			try {
				execSync(`tmux select-layout -t ${executionWindowId} tiled`, { stdio: "ignore" });
			} catch {}
		}

		// Set pane title for identification
		try {
			execSync(`tmux select-pane -t ${paneId} -T ${shellEscape(`${opts.taskId}: ${opts.taskTitle}`)}`, {
				stdio: "ignore",
			});
		} catch {}
	} catch (e: any) {
		// Tmux command failed — clean up and fall through with error
		try {
			fs.rmSync(tmpDir, { recursive: true, force: true });
		} catch {}
		return {
			exitCode: 1,
			messages: [],
			stderr: `Failed to create tmux pane: ${e.stderr || e.message}`,
			usage: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0, cost: 0, turns: 0 },
		};
	}

	// 5. Wait for the task to complete
	await waitForCompletion(exitCodeFile, paneId, opts.signal);

	// 6. Read structured results from the session file
	const result = readSessionResults(sessionDir, exitCodeFile);

	// 7. Clean up temp directory
	try {
		fs.rmSync(tmpDir, { recursive: true, force: true });
	} catch {}

	return result;
}

// ---------------------------------------------------------------------------
// Completion detection
// ---------------------------------------------------------------------------

/**
 * Poll for the exit-code marker file. Falls back to pane existence check
 * in case the wrapper script's trap didn't fire (e.g., SIGKILL).
 */
async function waitForCompletion(exitCodeFile: string, paneId: string, signal?: AbortSignal): Promise<void> {
	return new Promise<void>((resolve) => {
		const check = () => {
			if (signal?.aborted) {
				// Kill the pane on abort
				try {
					execSync(`tmux kill-pane -t ${paneId}`, { stdio: "ignore" });
				} catch {}
				resolve();
				return;
			}

			// Primary: check for exit-code file
			if (fs.existsSync(exitCodeFile)) {
				resolve();
				return;
			}

			// Fallback: if pane is gone but no file yet, give trap time to write
			if (!paneExists(paneId)) {
				setTimeout(() => {
					// If still no file after 1.5s, write a fallback
					if (!fs.existsSync(exitCodeFile)) {
						try {
							fs.writeFileSync(exitCodeFile, "1\n");
						} catch {}
					}
					resolve();
				}, 1500);
				return;
			}

			setTimeout(check, 500);
		};
		check();
	});
}

// ---------------------------------------------------------------------------
// Session result extraction
// ---------------------------------------------------------------------------

/**
 * Find a .jsonl session file in a directory (checks one level deep).
 */
function findJsonlFile(dir: string): string | null {
	try {
		// Check immediate directory
		for (const f of fs.readdirSync(dir)) {
			if (f.endsWith(".jsonl")) return path.join(dir, f);
		}
		// Check one level deep (in case of subdirectory structure)
		for (const d of fs.readdirSync(dir)) {
			const subdir = path.join(dir, d);
			try {
				if (fs.statSync(subdir).isDirectory()) {
					for (const f of fs.readdirSync(subdir)) {
						if (f.endsWith(".jsonl")) return path.join(subdir, f);
					}
				}
			} catch {}
		}
	} catch {}
	return null;
}

/**
 * Read structured results from a completed sub-agent's session file.
 * Returns a SubagentOutput compatible with the headless runner's output.
 */
function readSessionResults(sessionDir: string, exitCodeFile: string): SubagentOutput {
	// Read exit code
	let exitCode = 1;
	try {
		const raw = fs.readFileSync(exitCodeFile, "utf-8").trim();
		const parsed = parseInt(raw, 10);
		if (!isNaN(parsed)) exitCode = parsed;
	} catch {}

	// Find and open session file
	const sessionFile = findJsonlFile(sessionDir);
	if (!sessionFile) {
		return {
			exitCode,
			messages: [],
			stderr: "",
			usage: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0, cost: 0, turns: 0 },
		};
	}

	try {
		const sm = SessionManager.open(sessionFile);
		const entries = sm.getBranch();

		const messages: Message[] = [];
		const usage = { input: 0, output: 0, cacheRead: 0, cacheWrite: 0, cost: 0, turns: 0 };
		let model: string | undefined;

		for (const entry of entries) {
			if (entry.type !== "message") continue;

			const msg = entry.message as unknown as Message;
			messages.push(msg);

			if (msg.role === "assistant") {
				usage.turns++;
				const u = (msg as any).usage;
				if (u) {
					usage.input += u.input || 0;
					usage.output += u.output || 0;
					usage.cacheRead += u.cacheRead || 0;
					usage.cacheWrite += u.cacheWrite || 0;
					usage.cost += u.cost?.total || 0;
				}
				if (!model && (msg as any).model) model = (msg as any).model;
			}
		}

		return { exitCode, messages, stderr: "", usage, model };
	} catch (e: any) {
		// Session file might be malformed if pi crashed mid-write
		return {
			exitCode,
			messages: [],
			stderr: `Failed to read session: ${e.message}`,
			usage: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0, cost: 0, turns: 0 },
		};
	}
}
