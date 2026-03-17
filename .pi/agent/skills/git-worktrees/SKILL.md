---
name: git-worktrees
description: How to use git worktrees to work on independent features in parallel. Use this skill whenever the user wants to start a new task without disrupting current work, work on multiple features simultaneously, create an isolated working copy for a branch, or mentions "worktree", "parallel work", or "work on something else at the same time". Also use it when the user wants to merge a worktree back, rebase a worktree branch, or clean up finished worktrees.
---

# Git Worktrees

Git worktrees let you check out multiple branches of the same repo in
separate directories, sharing one `.git` store. This means you can have
one pi session working on feature A while another works on feature B —
independent branches, independent working trees, no stash juggling.

This skill covers the full lifecycle: set up a worktree with enough
context for the next session to hit the ground running, then merge
everything back cleanly when the work is done.

## The workflow

There are two moments the user will invoke this skill:

1. **"I want to work on X in parallel"** → Set up the worktree and hand
   off (steps 1–4 below).
2. **"That worktree work is done, merge it back"** → Rebase, merge, and
   clean up (step 5 below).

## Setting up

### 1. Make sure the current tree is clean

```bash
git status --porcelain
```

If there are uncommitted changes, ask the user whether to commit or stash
them before proceeding. Worktrees share the same `.git` directory, so a
dirty index can cause confusion about which changes belong where.

### 2. Record the originating branch

The worktree branch will eventually rebase onto this:

```bash
git rev-parse --abbrev-ref HEAD
```

Remember this value — you'll need it for the merge-back step.

### 3. Create the worktree

Always place worktrees as **sibling directories** — never inside the repo:

```bash
REPO=$(basename "$PWD")
BRANCH="<descriptive-kebab-case-name>"

git worktree add -b "$BRANCH" "../${REPO}-${BRANCH}"
```

Naming convention: `../<repo>-<branch>`. For example, if the repo is
`my-app` and the branch is `add-export-cmd`, the worktree goes at
`../my-app-add-export-cmd`.

If resuming work on an existing branch:

```bash
git worktree add "../${REPO}-${BRANCH}" "$BRANCH"
```

### 4. Write TASK.md and hand off

The new pi session starts with zero context. Bridge the gap by writing a
`TASK.md` in the worktree root that gives it everything it needs to start
working immediately.

Write `TASK.md` with at minimum:

- **Task**: what to do, in enough detail that someone unfamiliar with the
  conversation could act on it.
- **Context**: relevant files, modules, patterns, constraints, or design
  decisions from the current session that inform the work.
- **Done criteria**: how to know the task is complete (tests pass, specific
  behavior works, etc.).
- **On completion**: commit all changes with a descriptive message, then
  run the project's check/test suite.

Then tell the user exactly what to run:

```
Worktree ready at ../<repo>-<branch>.

To start working on it, open a new terminal and run:

  cd ../<repo>-<branch> && pi @TASK.md
```

The `@TASK.md` syntax feeds the file contents as pi's initial message, so
the new session begins with full context. Stop here — the user takes it
from here in the other session.

## Merging back

When the user returns and says the worktree work is done:

### 5a. Verify the work is committed

```bash
cd ../<worktree-path> && git status --porcelain
```

If there are uncommitted changes, ask the user whether to commit them or
discard them before proceeding.

### 5b. Rebase onto the originating branch

The originating branch may have moved forward. Rebase so the merge is a
clean fast-forward:

```bash
cd ../<worktree-path> && git rebase <originating-branch>
```

If there are conflicts, see [Resolving rebase conflicts](#resolving-rebase-conflicts).

### 5c. Fast-forward merge

Back in the original working directory (no `cd` needed):

```bash
git merge <branch-name>
```

After a successful rebase this is a fast-forward — no merge commit. Verify:

```bash
git log --oneline -5
```

### 5d. Clean up

```bash
git worktree remove ../<worktree-path>
git branch -d <branch-name>
```

`git worktree remove` deletes the directory. `git branch -d` is safe — it
refuses to delete an unmerged branch.

### 5e. Verify

Run the project's test/check suite to make sure the merged code works in
the context of the originating branch.

## Resolving rebase conflicts

During `git rebase`, if conflicts occur:

1. **List conflicted files:**
   ```bash
   cd ../<worktree-path> && git diff --name-only --diff-filter=U
   ```

2. **Read each file** in the worktree, find the `<<<<<<<` / `=======` /
   `>>>>>>>` markers, and resolve with `edit`. Keep the intent of both
   sides where possible.

3. **Stage and continue:**
   ```bash
   cd ../<worktree-path> && git add -A && git rebase --continue
   ```

4. Repeat for each conflicting commit until the rebase finishes.

If the conflicts are too tangled to resolve confidently, abort and fall
back to a merge commit instead:

```bash
cd ../<worktree-path> && git rebase --abort
```

Then from the original working directory:

```bash
git merge <branch-name> --no-ff
```

Resolve conflicts there and commit. This produces a merge commit instead
of linear history, but it's better than a botched rebase.

## Managing worktrees

### Listing

```bash
git worktree list
```

Shows every worktree with its path, HEAD commit, and branch.

### Locking long-lived worktrees

If a worktree will sit idle for a while, lock it to prevent accidental
pruning:

```bash
git worktree lock ../<worktree-path> --reason "in-progress feature work"
```

Unlock when resuming:

```bash
git worktree unlock ../<worktree-path>
```

## Constraints

- **One branch per worktree.** Git won't let two worktrees check out the
  same branch.
- **Shared refs.** Commits, branches, tags, and stash are visible across
  all worktrees. Only the working tree and index are independent.
- **Sibling directories only.** Never nest a worktree inside the repo.
- **Build artifacts are per-worktree.** Each worktree needs its own
  dependency install (`go mod download`, `npm ci`, etc.). The new pi
  session will handle this naturally when it reads TASK.md and starts
  working.
- **Clean up TASK.md before the final commit** in the worktree session —
  it's scaffolding, not part of the feature.
