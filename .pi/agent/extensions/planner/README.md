# Planner Extension

Structured planning + deterministic task dispatch for large features and refactors.

The problem this solves: when you divide a plan into tasks for separate implementation agents, each agent typically reads the entire plan, gets confused by irrelevant context, and wastes tokens re-reasoning about decisions the planner already made. This extension fixes that by deterministically assembling scoped task briefs — each implementation agent sees only its task, with decisions framed as constraints rather than conclusions to re-evaluate.

## Workflow

```
1. Brainstorm with the agent normally
2. /plan (or /plan compact)
3. Agent explores codebase, calls submit_plan with structured JSON
4. Review the plan in the TUI (also saved to docs/plans/<plan>.md)
5. /plan-execute — tasks dispatched to isolated subagents
6. /plan-status — full token usage breakdown across all phases
```

## Commands

| Command | Description |
|---------|-------------|
| `/plan` | Toggle planning mode (read-only tools, submit_plan enabled) |
| `/plan compact` | Compact brainstorm context first, then enter planning mode |
| `/plan-execute` | Execute all pending tasks (interactive tmux panes by default) |
| `/plan-execute --no-tmux` | Execute all pending tasks headlessly (no tmux panes) |
| `/plan-execute --hierarchical` | Execute all pending tasks serially (no worktrees) |
| `/plan-execute task-1` | Execute (or re-run) a specific task |
| `/plan-status` | Show current plan progress and full token usage |
| `/plan-clear` | Clear the plan and all results |
| `Ctrl+Alt+P` | Toggle planning mode (shortcut) |

## Planning Mode

When you enter plan mode with `/plan`:

- **Write tools are blocked** — `edit`, `write`, and destructive bash commands are prevented
- **Planning instructions are injected** — the agent is guided to explore first, then submit a structured plan
- **`submit_plan` tool is available** — forces the agent to output machine-parseable JSON instead of free-text markdown

The agent can still use `read`, `grep`, `find`, `ls`, and safe bash commands (git status, git log, cat, etc.) to explore the codebase.

### When to use `/plan` vs `/plan compact`

- **`/plan`** — Just toggles the mode. Your full brainstorming conversation stays intact. Use this when the brainstorm was short/medium or the context is in good shape. The planning agent benefits from having the real conversation with all its nuance.

- **`/plan compact`** — Compacts the brainstorming conversation first (preserving decisions, discarding tangents), then enters plan mode. Use this when the brainstorm was very long and you need to reclaim context space. Compaction is lossy — a summary is never as rich as the original conversation.

- **`/handoff`** (separate extension) — If the brainstorm was so long you're worried about context limits, handoff to a new session with a focused planning prompt gives you the most control since you review the handoff text before sending.

**When in doubt, use `/plan` without compact.** You can always compact later if needed.

## Plan Structure

The `submit_plan` tool enforces a specific JSON schema. Each task has:

| Field | Purpose |
|-------|---------|
| `id` | Unique identifier (e.g. `task-1`) |
| `title` | Short descriptive name |
| `goal` | Desired **outcome**, not step-by-step instructions |
| `files` | File paths to read first — starting points, not restrictions |
| `constraints` | Architectural decisions stated as **facts**, not reasoning |
| `acceptance` | Concrete, testable completion criteria |
| `dependsOn` | Task IDs that must complete first (empty = independent) |
| `skills` | Optional skill names relevant to the task |
| `model` | Optional model override |

### What makes a good plan

The extension guides the agent toward plans that work well with isolated implementation agents:

- **Goals, not steps.** "FooBar integrates with the existing visitor infrastructure" — not "Add a method called processNode that takes a NodeContext parameter." The implementer reads the actual code and figures out the right approach.
- **Constraints are for architecture only.** "Use the visitor pattern" and "Errors use Result<T,E>" are good constraints. Method signatures and variable names are not — that's micromanaging.
- **Files are hints.** The implementer reads them to understand current state and can explore further. They aren't inlined (which would be stale by the time dependent tasks run).
- **Tight coupling = same task.** If two changes touch the same files, they belong in one task. Split at module/concern boundaries.

## Plan Files

When `submit_plan` is called, a human-readable markdown version of the plan is written to `docs/plans/<slugified-goal>.md` in the current project. If `docs/plans/` doesn't exist, you're prompted to create it.

The plan file contains the goal, context, and all tasks with their goals, files, constraints, acceptance criteria, and dependencies — formatted for easy reading and sharing.

The file path is shown in `/plan-status` and in the submit_plan result.

## Token Usage Tracking

The extension tracks token usage across the entire planning and execution lifecycle:

- **Planning phase** — all LLM turns while in `/plan` mode (exploration, reasoning, submit_plan call)
- **Execution phase** — per-task usage from each sub-agent (input, output, cache read, cache write, cost, turns, model)

Usage is visible in three places:

1. **`/plan-status`** — shows a compact summary: total tokens in/out, cache stats, cost, and turn count
2. **Execution summary** — after `/plan-execute` completes, a full usage table breaks down every phase with per-row and total stats
3. **Widget** — per-task cost shown inline during and after execution

The execution summary table looks like:

```
| Phase           | Input  | Output | Cache Read | Cache Write | Cost    | Turns | Model              |
|-----------------|-------:|-------:|-----------:|------------:|--------:|------:|---------------------|
| Planning        | 45,230 |  8,120 |     12,400 |       5,600 | $0.0820 |     4 | claude-sonnet-4-5   |
| task-1: Auth    | 23,100 |  5,400 |      8,200 |       3,100 | $0.0450 |     3 | claude-sonnet-4-5   |
| task-2: Routes  | 31,200 |  7,800 |     10,500 |       4,200 | $0.0670 |     5 | claude-sonnet-4-5   |
| **Total**       | 99,530 | 21,320 |     31,100 |      12,900 | $0.1940 |    12 |                     |
```

## Execution

`/plan-execute` dispatches tasks to pi subprocesses. Each subagent gets:

- The **implementer system prompt** (focused on executing, not re-planning)
- The **assembled task brief** — built deterministically from plan data
- Default coding tools (read, bash, edit, write)
- No parent extensions (`--no-extensions`) for a clean tool set

### Tmux Mode (Default)

When running inside tmux, `/plan-execute` opens each sub-agent as an **interactive pi instance in its own tmux pane**:

```
┌──────────────────────┬──────────────────────┐
│ task-1: auth module  │ task-2: API routes    │
│ pi working...        │ pi working...         │
│ > edit src/auth.ts   │ > read routes/        │
│ > bash npm test      │ > [you can type here] │
├──────────────────────┼──────────────────────┤
│ task-3: tests        │ task-4: docs          │
│ pi working...        │ ○ pending (waiting    │
│ > read tests/        │   on task-1)          │
└──────────────────────┴──────────────────────┘
```

**Why this matters:**

- **You can watch each agent work** — see every tool call, every edit, in real time
- **You can steer agents mid-flight** — if task-2 starts going wrong, type a correction in its pane
- **You can zoom in** — `tmux resize-pane -Z` (or prefix+z) to focus on one agent
- **Results are still structured** — after each agent exits, its session file is read back for usage stats, summary, and file changes

The execution window is created automatically when the first task spawns. All task panes are arranged in a tiled layout with pane border titles showing task IDs. When all tasks complete, you're switched back to your original working window.

**To opt out** and run headlessly (like pre-tmux behavior): `/plan-execute --no-tmux`

When not inside tmux, headless mode is used automatically.

### Headless Mode

With `--no-tmux` (or when not in tmux), sub-agents run as background `pi --mode json -p` processes. Output is captured via JSON events. This is the original behavior — faster for routine tasks but no visibility or steering.

### Task Brief Assembly

This is the deterministic core. For each task, **code** (not an LLM) builds the prompt:

1. **Shared context** — brief architectural summary from the plan
2. **File hints** — listed for the agent to read (current content, not stale snapshots)
3. **Constraints** — stated as non-negotiable facts
4. **Prior work** — summaries from completed dependency tasks + files they changed
5. **Skill hints** — names of relevant skills
6. **Goal + acceptance criteria** — what to achieve and how to verify

What the brief does **not** include:
- Other tasks in the plan
- The planner's reasoning process
- Step-by-step implementation instructions
- The brainstorming conversation

### Parallel Isolation via Git Worktrees

When parallel tasks run in the same directory, the last writer wins — silently overwriting a concurrent task's changes. The planner *should* avoid this ("group tightly-coupled changes into one task"), but planners make mistakes, especially with non-obvious coupling like shared utility files or barrel exports.

**When executing in a git repo**, each parallel task automatically gets its own **git worktree** — a separate working directory on its own branch. This means:

- Parallel tasks have **full file isolation** — no overwrites possible
- Dependency directories (`node_modules`, `.venv`, etc.) are **symlinked** from the main repo to avoid reinstall overhead
- After a task completes, its branch is **rebased onto main** and **fast-forward merged** back
- Merges happen **sequentially** (serialized queue), so each rebase sees the latest HEAD
- If rebase fails (real conflict), the task is marked failed and the **worktree is left in place** for manual inspection/resolution
- Successful merges clean up the worktree and branch automatically

**When NOT in a git repo**, tasks still run in parallel but share the working directory. A warning is shown. Use `--hierarchical` for safe serial execution.

#### Execution Modes

| Command | Mode | Isolation | Visibility |
|---------|------|-----------|------------|
| `/plan-execute` (tmux + git) | Parallel with worktrees | Full — each task on own branch | Interactive tmux panes |
| `/plan-execute --no-tmux` (git) | Parallel with worktrees | Full — each task on own branch | Headless |
| `/plan-execute --hierarchical` | Serial, one at a time | Full — sequential, no overlap | Interactive tmux panes (if tmux) |
| `/plan-execute` (no git repo) | Parallel, shared directory | ⚠ None — last writer wins | Interactive tmux panes (if tmux) |
| `/plan-execute task-1` | Single task | N/A — only one task runs | Interactive tmux pane (if tmux) |

#### Conflict Example

Tasks A and B run in parallel, both on branches from the same HEAD:
1. A finishes first. Rebase onto main (trivial — main hasn't moved). Fast-forward merge. Main now includes A's changes.
2. B finishes. Rebase onto main (which now includes A). If B modified the same lines A did, git reports a conflict. Task B is marked failed with conflict details, and B's worktree is preserved at `../<repo>-plan-task-2/` for manual resolution.

### DAG Scheduling

Tasks execute based on their dependency graph:

- Independent tasks run **in parallel** (up to 4 concurrent) with worktree isolation
- A task starts as soon as its dependencies complete (pool-based, not wave-based — task D that depends only on A starts when A finishes, even if slow sibling B is still running)
- If a task fails, its transitive dependents are **skipped** (other independent tasks continue)
- Re-running a failed task with `/plan-execute task-X` automatically resets skipped dependents

### Progress Tracking

During execution:
- **Footer status** shows overall progress (e.g. `⚡ 3/5`)
- **Widget** shows per-task status with icons and cost
- **Tmux panes** show each agent working in real time (tmux mode)
- **Messages** appear as each task completes with its summary
- **Final summary** shows all results, errors, and full token usage table across planning + execution

## Re-running and Recovery

| Situation | Action |
|-----------|--------|
| Task failed | `/plan-execute task-3` — resets to pending and re-runs |
| Want to re-run a completed task | `/plan-execute task-2` — prompts for confirmation |
| Task failed, dependents were skipped | `/plan-execute task-3` — if it succeeds, skipped dependents auto-reset to pending |
| Resume after interrupted execution | `/plan-execute` — picks up where it left off (interrupted tasks reset to pending on session restore) |
| Start over | `/plan-clear` then `/plan` |

## File Structure

```
~/.pi/agent/extensions/planner/
├── index.ts         Extension entry: tool, commands, events, rendering, DAG scheduler
├── types.ts         TypeBox schemas for Plan and Task (forces structured LLM output)
├── brief.ts         Task brief assembly (deterministic: plan data → scoped prompt)
├── runner.ts        Headless subagent spawning (pi --mode json, output parsing)
├── tmux-runner.ts   Tmux pane spawning (interactive pi, session file result extraction)
└── worktree.ts      Git worktree lifecycle (create, symlink deps, merge back, cleanup)
```

## Design Decisions

**Why tmux panes by default?**
Headless execution is a black box. When a task goes off-track, you only find out after it finishes. With tmux panes, you see every tool call in real time and can type corrections mid-flight. Most tasks complete fine autonomously — you only intervene when you spot a problem. This is the sweet spot between full automation and manual work.

**Why read session files instead of JSON streaming for tmux mode?**
In tmux mode, pi runs interactively (full TUI). It can't simultaneously output JSON to stdout. Instead, pi writes its session to a file, and after it exits we read the session back. The session file contains *more* structured data than JSON events — full conversation tree, all tool results, usage stats. It also survives crashes (whatever was flushed is recoverable).

**Why not inline file contents in the brief?**
Files are listed as hints, not inlined. The implementation agent reads them itself. This means it gets current content (not stale snapshots from plan time — important when earlier tasks modify files), and it can discover adjacent files the planner didn't anticipate.

**Why goals instead of steps?**
The planner works from a high-level reading. The implementer collides with reality — types that changed, overloads the planner didn't notice, tests that reveal edge cases. Goals with acceptance criteria let the agent adapt. Step-by-step instructions make it a brittle transcription machine.

**Why `--no-extensions` for subagents?**
Gives the implementer a clean tool set (read, bash, edit, write) without the planner extension, research tools, or other extensions adding noise to the system prompt and tool list.

**Why block writes in plan mode instead of using `setActiveTools`?**
`setActiveTools` replaces the entire tool list, which would disable other extensions' tools (research, web_fetch, etc.). Blocking via the `tool_call` event is surgical — only edit/write/destructive bash are prevented, everything else works normally.

**Why a pool scheduler instead of waves?**
Wave-based execution waits for an entire batch to finish before starting the next. If tasks A and B are in the same wave, and A takes 1 minute but B takes 10, task C (which only depends on A) waits 10 minutes unnecessarily. The pool scheduler starts C as soon as A completes.

**Why git worktrees for parallel isolation?**
When two agents edit the same file concurrently, the last writer silently wins. Application-level file locking is fragile and doesn't compose with arbitrary tool calls. Git worktrees give each task a real isolated working directory on its own branch, and git's rebase/merge machinery detects conflicts properly. Dependency directories (node_modules, etc.) are symlinked to avoid reinstall overhead. On conflict, the worktree is preserved for manual resolution rather than silently corrupting the codebase.

**Why serialize merge-back instead of merging in parallel?**
Each completed task rebases onto main before merging. If two tasks merge simultaneously, they'd both rebase onto the same HEAD and the second fast-forward would fail. Sequential merging ensures each rebase sees the latest HEAD (including all previously merged tasks), producing linear history and correct conflict detection.
