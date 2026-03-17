/**
 * Task brief assembly — deterministically builds a scoped prompt
 * for an implementation agent from structured plan data.
 *
 * The brief gives the agent:
 *   - Shared architectural context (brief)
 *   - File hints to start reading (not inlined — agent reads current state)
 *   - Constraints stated as facts (not reasoning to re-evaluate)
 *   - Summaries from completed dependency tasks
 *   - The goal and acceptance criteria
 *
 * The brief does NOT include:
 *   - Other tasks in the plan
 *   - The planner's reasoning process
 *   - Step-by-step implementation instructions
 *
 * KEY DESIGN DECISIONS (read before modifying):
 *
 *   Files are hints, not inlined content. The agent reads them itself via tool
 *   calls. This is intentional: (1) dependent tasks modify files, so content
 *   from plan time is stale by execution time, and (2) the agent can discover
 *   adjacent files the planner didn't anticipate. Do not "optimize" by inlining.
 *
 *   Goals, not steps. The planner works from a high-level reading. The
 *   implementer collides with reality — changed types, unexpected overloads,
 *   edge cases. Step-by-step instructions create a brittle agent that follows
 *   incorrect micro-instructions faithfully instead of using judgment. Goals
 *   with acceptance criteria let it adapt.
 *
 *   Constraints are stated as facts ("Use visitor pattern"), not as conclusions
 *   of reasoning ("We decided to use visitor pattern because..."). The latter
 *   framing invites the implementation agent to re-evaluate the decision,
 *   wasting tokens on re-reasoning the planner already did.
 *
 *   See README.md for full rationale.
 */

import type { Plan, Task, TaskResult } from "./types.js";

export function assembleTaskBrief(task: Task, plan: Plan, results: Record<string, TaskResult>): string {
	const s: string[] = [];

	s.push(`# Task: ${task.title}`, "");

	// Shared context — brief, not the full plan
	s.push("## Context", plan.context, "");

	// File hints — the agent reads these itself (gets current content, can discover more)
	if (task.files.length > 0) {
		s.push("## Relevant Files (start here)");
		for (const f of task.files) s.push(`- \`${f}\``);
		s.push("", "These are starting points. Read them to understand the current state. Explore further as needed.", "");
	}

	// Constraints — stated as facts, not conclusions of debates
	if (task.constraints.length > 0) {
		s.push("## Constraints");
		for (const c of task.constraints) s.push(`- ${c}`);
		s.push("");
	}

	// Dependency outputs — what prior agents accomplished (changes are on disk)
	const deps = task.dependsOn.map((id) => results[id]).filter(Boolean);
	if (deps.length > 0) {
		s.push("## Prior Work");
		s.push("These tasks were completed by other agents. Their changes are already on disk — read the files for current state.", "");
		for (const d of deps) {
			s.push(`### ${d.title}`);
			s.push(d.summary);
			if (d.filesChanged.length > 0) {
				s.push(`Files changed: ${d.filesChanged.map((f) => `\`${f}\``).join(", ")}`);
			}
			if (d.notes) {
				s.push(`Notes: ${d.notes}`);
			}
			s.push("");
		}
	}

	// Skills hint
	if (task.skills && task.skills.length > 0) {
		s.push("## Relevant Skills");
		s.push(`These skills may be useful: ${task.skills.join(", ")}. Load them with /skill:<name> if needed.`, "");
	}

	// Goal — the desired outcome, not steps
	s.push("## Goal", task.goal, "");

	// Acceptance criteria — concrete, testable
	if (task.acceptance.length > 0) {
		s.push("## Done When");
		for (const a of task.acceptance) s.push(`- ${a}`);
		s.push("");
	}

	return s.join("\n");
}
