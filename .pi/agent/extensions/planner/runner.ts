/**
 * Subagent spawning — runs implementation agents as isolated pi processes.
 *
 * Each subagent gets:
 *   - A clean context window (--no-session)
 *   - The implementer system prompt (--append-system-prompt)
 *   - The assembled task brief as its prompt
 *   - Default coding tools (read, bash, edit, write)
 *   - research and web_fetch tools (explicitly loaded via -e)
 *   - No parent extensions (--no-extensions) for a clean tool set
 *
 * Output is captured via --mode json and parsed for usage tracking.
 */

import { spawn } from "node:child_process";
import * as fs from "node:fs";
import * as os from "node:os";
import * as path from "node:path";
import type { Message } from "@mariozechner/pi-ai";

export const IMPLEMENTER_PROMPT = `You are an implementation agent executing a focused task.

- Read the suggested files first to understand the current state of the code
- Explore further as needed — you are not limited to the listed files
- Follow constraints exactly — they represent deliberated architectural decisions
- If you discover something that contradicts a constraint, note the conflict clearly but still work toward satisfying the goal
- Work until all acceptance criteria are met
- If you've attempted the same fix 2-3 times without progress, stop and reconsider your approach before trying again. If the issue involves a library, framework, or runtime behavior you're uncertain about, use the research or web_fetch tool to look up the specific error or API. Don't use research for bugs in the project's own logic — those are only solvable by reading the code.
- If you get stuck, explain what's blocking you rather than producing broken code

When you are finished, end your final message with this exact format:

## Summary
What was accomplished (1-2 sentences).

## Files Changed
- \`path/to/file\` - what changed

## Notes
Anything notable: difficulties encountered and how you solved them, surprises
about the codebase, or things the caller should know. Omit if nothing.`;

export interface SubagentOutput {
	exitCode: number;
	messages: Message[];
	stderr: string;
	usage: {
		input: number;
		output: number;
		cacheRead: number;
		cacheWrite: number;
		cost: number;
		turns: number;
	};
	model?: string;
}

export async function spawnImplementer(opts: {
	cwd: string;
	prompt: string;
	model?: string;
	signal?: AbortSignal;
	onMessage?: (text: string) => void;
}): Promise<SubagentOutput> {
	const args = ["--mode", "json", "-p", "--no-session", "--no-extensions"];

	// Explicitly load research and web_fetch extensions (allowed even with --no-extensions)
	const extDir = path.join(os.homedir(), ".pi/agent/extensions");
	args.push("-e", path.join(extDir, "research.ts"));
	args.push("-e", path.join(extDir, "web-fetch/index.ts"));

	// Write implementer system prompt to temp file
	const tmpDir = fs.mkdtempSync(path.join(os.tmpdir(), "pi-plan-"));
	const promptFile = path.join(tmpDir, "implementer.md");
	fs.writeFileSync(promptFile, IMPLEMENTER_PROMPT, "utf-8");
	args.push("--append-system-prompt", promptFile);

	if (opts.model) args.push("--model", opts.model);

	// Task brief is the prompt (last positional argument)
	args.push(opts.prompt);

	const out: SubagentOutput = {
		exitCode: 0,
		messages: [],
		stderr: "",
		usage: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0, cost: 0, turns: 0 },
	};

	try {
		let wasAborted = false;

		out.exitCode = await new Promise<number>((resolve) => {
			const proc = spawn("pi", args, {
				cwd: opts.cwd,
				shell: false,
				stdio: ["ignore", "pipe", "pipe"],
			});

			let buf = "";

			const parseLine = (line: string) => {
				if (!line.trim()) return;
				let ev: any;
				try {
					ev = JSON.parse(line);
				} catch {
					return;
				}

				if (ev.type === "message_end" && ev.message) {
					const msg = ev.message as Message;
					out.messages.push(msg);

					if (msg.role === "assistant") {
						out.usage.turns++;
						const u = (msg as any).usage;
						if (u) {
							out.usage.input += u.input || 0;
							out.usage.output += u.output || 0;
							out.usage.cacheRead += u.cacheRead || 0;
							out.usage.cacheWrite += u.cacheWrite || 0;
							out.usage.cost += u.cost?.total || 0;
						}
						if (!out.model && (msg as any).model) out.model = (msg as any).model;

						const text =
							msg.content
								?.filter((c: any) => c.type === "text")
								.map((c: any) => c.text)
								.join("") || "";
						if (text) opts.onMessage?.(text);
					}
				}

				if (ev.type === "tool_result_end" && ev.message) {
					out.messages.push(ev.message as Message);
				}
			};

			proc.stdout.on("data", (d: Buffer) => {
				buf += d.toString();
				const lines = buf.split("\n");
				buf = lines.pop() || "";
				for (const l of lines) parseLine(l);
			});

			proc.stderr.on("data", (d: Buffer) => {
				out.stderr += d.toString();
			});

			proc.on("close", (code) => {
				if (buf.trim()) parseLine(buf);
				resolve(code ?? 0);
			});

			proc.on("error", () => resolve(1));

			if (opts.signal) {
				const kill = () => {
					wasAborted = true;
					proc.kill("SIGTERM");
					setTimeout(() => {
						if (!proc.killed) proc.kill("SIGKILL");
					}, 5000);
				};
				if (opts.signal.aborted) kill();
				else opts.signal.addEventListener("abort", kill, { once: true });
			}
		});

		if (wasAborted) out.exitCode = 130;
	} finally {
		try {
			fs.unlinkSync(promptFile);
		} catch {}
		try {
			fs.rmdirSync(tmpDir);
		} catch {}
	}

	return out;
}

/**
 * Parse the implementer's output to extract summary and files changed.
 * Falls back to last 500 chars if the expected format isn't followed.
 */
export function parseOutput(messages: Message[]): { summary: string; filesChanged: string[]; notes: string } {
	for (let i = messages.length - 1; i >= 0; i--) {
		if (messages[i].role !== "assistant") continue;

		const text =
			messages[i].content
				?.filter((c: any) => c.type === "text")
				.map((c: any) => c.text)
				.join("\n") || "";

		// Try to extract structured sections
		const sumMatch = text.match(/## Summary\n([\s\S]*?)(?=\n## |$)/);
		const summary = sumMatch?.[1]?.trim() || text.slice(-500).trim();

		const filesSection = text.match(/## Files Changed\n([\s\S]*?)(?=\n## |$)/);
		const filesChanged: string[] = [];
		if (filesSection) {
			for (const line of filesSection[1].split("\n")) {
				const m = line.match(/`([^`]+)`/);
				if (m) filesChanged.push(m[1]);
			}
		}

		const notesMatch = text.match(/## Notes\n([\s\S]*?)(?=\n## |$)/);
		const notes = notesMatch?.[1]?.trim() || "";

		return { summary, filesChanged, notes };
	}

	return { summary: "(no output)", filesChanged: [], notes: "" };
}
