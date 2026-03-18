import { Type, type Static } from "@sinclair/typebox";

export const TaskSchema = Type.Object({
	id: Type.String({ description: "Unique task ID, e.g. 'task-1'" }),
	title: Type.String({ description: "Short descriptive title" }),
	goal: Type.String({
		description: "Desired outcome for this task. State what should be true when done, not step-by-step instructions.",
	}),
	files: Type.Array(Type.String(), {
		description: "File paths the implementer should read first as starting context. Not restrictions — the agent may explore further.",
	}),
	constraints: Type.Array(Type.String(), {
		description: "Non-negotiable architectural decisions stated as facts. Only include genuinely deliberated decisions — do not micromanage implementation details.",
	}),
	acceptance: Type.Array(Type.String(), {
		description: "Concrete, testable criteria for completion (e.g. 'tsc compiles', 'existing tests pass', 'new endpoint returns 200').",
	}),
	dependsOn: Type.Array(Type.String(), {
		description: "Task IDs that must complete before this one. Empty array if independent.",
	}),
	skills: Type.Optional(
		Type.Array(Type.String(), {
			description: "Relevant skill names the implementer may want to load, e.g. ['git-worktrees']",
		}),
	),
	model: Type.Optional(
		Type.String({
			description: "Model override for this task, e.g. 'claude-sonnet-4-5'. Omit to use default.",
		}),
	),
});

export const PlanSchema = Type.Object({
	goal: Type.String({ description: "One-sentence summary of the overall feature or change" }),
	context: Type.String({
		description:
			"Brief architectural context shared across all tasks — just enough for any implementer to understand where their work fits in the codebase.",
	}),
	defaultModel: Type.Optional(
		Type.String({
			description:
				"Default model for all tasks. Individual tasks can override via their own model field. Omit to use the caller's default.",
		}),
	),
	tasks: Type.Array(TaskSchema, { minItems: 1 }),
});

export type Task = Static<typeof TaskSchema>;
export type Plan = Static<typeof PlanSchema>;

export type TaskStatus = "pending" | "running" | "done" | "failed" | "skipped";

export interface TaskResult {
	taskId: string;
	title: string;
	exitCode: number;
	summary: string;
	filesChanged: string[];
	notes: string;
	error?: string;
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

export interface PlanState {
	plan: Plan;
	planId: string;
	statuses: Record<string, TaskStatus>;
	results: Record<string, TaskResult>;
	planningUsage?: {
		input: number;
		output: number;
		cacheRead: number;
		cacheWrite: number;
		cost: number;
		turns: number;
	};
	planningModel?: string;
	planFile?: string;
}
