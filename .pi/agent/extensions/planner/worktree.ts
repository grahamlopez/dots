/**
 * Git worktree management for parallel task isolation.
 *
 * When parallel tasks run in the same directory, the last writer wins —
 * silently overwriting changes from a concurrent task. Git worktrees solve
 * this: each task gets its own working tree on its own branch. After
 * completion, branches merge back sequentially, and git's merge/rebase
 * machinery detects real conflicts.
 *
 * Flow per task:
 *   1. Create worktree + branch from current HEAD
 *   2. Symlink dependency directories (node_modules, etc.) to avoid reinstall
 *   3. Subagent runs with cwd = worktree path
 *   4. Auto-commit any uncommitted changes
 *   5. Rebase onto main (which may have moved if earlier tasks merged)
 *   6. Fast-forward merge back to main
 *   7. Clean up worktree + branch
 *
 * If rebase fails (real conflict), the task is marked failed with conflict
 * details and the worktree is LEFT IN PLACE for manual inspection/resolution.
 */

import { spawnSync } from "node:child_process";
import * as fs from "node:fs";
import * as path from "node:path";

// Dependency directories to symlink into worktrees (avoids reinstall overhead)
const DEP_DIRS = ["node_modules", ".venv", "vendor", "target", ".build", ".next", ".nuxt"];

// -----------------------------------------------------------------------
// Git helper
// -----------------------------------------------------------------------

interface GitResult {
	ok: boolean;
	stdout: string;
	stderr: string;
}

function git(args: string[], cwd: string): GitResult {
	const result = spawnSync("git", args, {
		cwd,
		encoding: "utf-8",
		timeout: 60_000,
		stdio: ["ignore", "pipe", "pipe"],
	});
	return {
		ok: result.status === 0,
		stdout: (result.stdout ?? "").trim(),
		stderr: (result.stderr ?? "").trim(),
	};
}

// -----------------------------------------------------------------------
// Checks
// -----------------------------------------------------------------------

export function isGitRepo(cwd: string): boolean {
	return git(["rev-parse", "--is-inside-work-tree"], cwd).ok;
}

export function isClean(cwd: string): boolean {
	const result = git(["status", "--porcelain"], cwd);
	return result.ok && result.stdout === "";
}

export function getCurrentBranch(cwd: string): string {
	const result = git(["rev-parse", "--abbrev-ref", "HEAD"], cwd);
	if (!result.ok) throw new Error(`Cannot determine current branch: ${result.stderr}`);
	return result.stdout;
}

// -----------------------------------------------------------------------
// Worktree lifecycle
// -----------------------------------------------------------------------

export interface WorktreeInfo {
	path: string;
	branch: string;
	mainBranch: string;
}

/**
 * Create a worktree for a task, branching from current HEAD.
 * Follows the git-worktrees skill convention: sibling directory, kebab-case.
 */
export function createTaskWorktree(cwd: string, planId: string, taskId: string): WorktreeInfo {
	const repoName = path.basename(path.resolve(cwd));
	const branch = `plan-${planId}-${taskId}`;
	const wtPath = path.resolve(cwd, `../${repoName}-${branch}`);
	const mainBranch = getCurrentBranch(cwd);

	// Clean up stale worktree/branch if they exist from a previous failed run
	if (fs.existsSync(wtPath)) {
		git(["worktree", "remove", "--force", wtPath], cwd);
	}
	const branchCheck = git(["branch", "--list", branch], cwd);
	if (branchCheck.ok && branchCheck.stdout) {
		git(["branch", "-D", branch], cwd);
	}

	const result = git(["worktree", "add", "-b", branch, wtPath], cwd);
	if (!result.ok) {
		throw new Error(`Failed to create worktree for ${taskId}: ${result.stderr}`);
	}

	return { path: wtPath, branch, mainBranch };
}

/**
 * Symlink dependency directories from the main repo into the worktree.
 * This avoids expensive reinstalls (npm install, pip install, etc.).
 * Symlinks are created only for directories that exist in the main repo
 * and don't already exist in the worktree.
 */
export function symlinkDeps(mainCwd: string, worktreePath: string): void {
	for (const dep of DEP_DIRS) {
		const src = path.join(mainCwd, dep);
		const dst = path.join(worktreePath, dep);
		try {
			if (fs.existsSync(src) && !fs.existsSync(dst)) {
				fs.symlinkSync(src, dst, "dir");
			}
		} catch {
			// Non-fatal — the subagent can install deps if needed
		}
	}
}

/**
 * Commit any uncommitted changes in a worktree.
 * Returns true if a commit was made, false if the tree was clean.
 */
export function commitIfDirty(worktreePath: string, taskId: string, title: string): boolean {
	if (isClean(worktreePath)) return false;

	git(["add", "-A"], worktreePath);
	const result = git(["commit", "-m", `[planner] ${taskId}: ${title}`], worktreePath);
	return result.ok;
}

// -----------------------------------------------------------------------
// Merge back
// -----------------------------------------------------------------------

export interface MergeResult {
	success: boolean;
	/** Set on conflict — describes what went wrong */
	conflicts?: string;
	/** Files that conflicted (parsed from git output) */
	conflictFiles?: string[];
}

/**
 * Rebase the task branch onto main, then fast-forward merge.
 *
 * This is called sequentially — only one merge at a time — so the main
 * branch moves forward with each successful merge. Later tasks rebase
 * onto the updated main, which is where git detects real conflicts.
 *
 * On conflict: aborts the rebase and returns conflict details.
 * The worktree is LEFT IN PLACE so the user can inspect/resolve manually.
 */
export function mergeBack(mainCwd: string, wt: WorktreeInfo): MergeResult {
	// Rebase task branch onto current main HEAD
	const rebase = git(["rebase", wt.mainBranch], wt.path);
	if (!rebase.ok) {
		// Extract conflicting files before aborting
		const conflictCheck = git(["diff", "--name-only", "--diff-filter=U"], wt.path);
		const conflictFiles = conflictCheck.stdout
			.split("\n")
			.map((f) => f.trim())
			.filter(Boolean);

		git(["rebase", "--abort"], wt.path);

		return {
			success: false,
			conflicts: rebase.stderr || rebase.stdout,
			conflictFiles,
		};
	}

	// Fast-forward merge into main
	const merge = git(["merge", wt.branch], mainCwd);
	if (!merge.ok) {
		return {
			success: false,
			conflicts: `Fast-forward merge failed: ${merge.stderr}`,
		};
	}

	return { success: true };
}

// -----------------------------------------------------------------------
// Cleanup
// -----------------------------------------------------------------------

/**
 * Remove a worktree and its branch. Safe to call even if the worktree
 * doesn't exist (idempotent).
 */
export function cleanupWorktree(mainCwd: string, wt: WorktreeInfo): void {
	try {
		if (fs.existsSync(wt.path)) {
			// Remove dep symlinks first (git worktree remove doesn't like them)
			for (const dep of DEP_DIRS) {
				const dst = path.join(wt.path, dep);
				try {
					const stat = fs.lstatSync(dst);
					if (stat.isSymbolicLink()) fs.unlinkSync(dst);
				} catch {
					// ignore
				}
			}
			git(["worktree", "remove", "--force", wt.path], mainCwd);
		}
	} catch {
		// Best-effort cleanup
	}

	try {
		git(["branch", "-D", wt.branch], mainCwd);
	} catch {
		// Branch may already be deleted or not exist
	}
}
