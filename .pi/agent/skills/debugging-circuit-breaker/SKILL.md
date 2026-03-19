---
name: debugging-circuit-breaker
description: A structured approach to debugging that prevents going in circles. Use this skill whenever you've made 3 or more failed attempts to fix the same problem, when you find yourself trying variations of the same approach without progress, when a test keeps failing and you're not sure why, or when you catch yourself thinking "let me just try one more thing." Also use it at the start of any non-trivial debugging session to set up good habits from the beginning.
---

# Debugging Circuit Breaker

When debugging, it's easy to lock onto a hypothesis and spend dozens of
turns trying variations of the same wrong idea. This skill provides a
structured approach that prevents that.

## The core rule

**After 3 failed attempts at the same problem, you must get new
information from a different source before trying again.**

"Different source" means something you haven't looked at yet:

- Existing code in the project that solves a similar problem
- The framework/library documentation
- The `research` tool
- A fundamentally different diagnostic (not another `console.log` in
  the same area)

Three attempts means three materially different things you've tried —
not three runs of the same test. Changing `pushState` to `replaceState`
to `goto` counts as one attempt (same hypothesis: "the navigation API
is wrong"), not three.

Trying variations of the same idea without new information is the
definition of going in circles. New information is what breaks the
cycle.

## Before you start debugging

Before writing new code, especially tests, do this first:

1. **Read existing patterns.** Find code in the project that already
   does what you're trying to do. Read the test helpers. This is not
   optional prep — it's the single highest-value step.

2. **Understand why helpers exist, not just what they do.** A helper
   with a 20-second retry loop exists because something is slow or
   async. A setup function that seems overly complex is handling edge
   cases you haven't hit yet. Don't skip them.

3. **Start from something that works.** Copy a passing test and modify
   it rather than writing from scratch. This inherits all the
   non-obvious things that make it work.

If you do this, you'll avoid most debugging entirely.

## When you hit the wall

Work through these in order. Each step is cheap and often reveals the
answer before you reach the expensive steps.

### Step 1: Read existing code that already works

Find existing code in the project that does the same thing successfully.

- If your test fails but similar existing tests pass, diff them. What's
  different? The difference is your bug.
- If there are test helpers you're not using, read them and understand
  what problems they solve.
- If a function you're calling works elsewhere, compare how it's called
  there vs how you're calling it.

The answer is almost always here. Existing code encodes solutions to
problems that were already debugged — often problems you don't even
know exist yet (timing, initialization order, framework quirks).

### Step 2: Question your assumptions

Write down what you believe is true but haven't directly verified:

- "The click handler is firing" — have you confirmed this with evidence?
- "The page is fully loaded" — how do you know? What does "loaded" mean
  in this framework?
- "This API works this way" — did you read the docs or are you guessing?

Pick the assumption you're least sure about and verify it with a direct
test — not by trying another fix and seeing if it works.

### Step 3: Simplify to find the real problem

Strip down to the minimal case:

- Does the simplest possible version work? (Hardcoded values, no
  framework abstractions, minimal reproduction)
- Does it work in isolation but fail in context? That points to an
  environment/timing issue, not a logic issue.
- What's the smallest diff between "works" and "doesn't work"?

### Step 4: Research

If steps 1-3 didn't solve it, you have a knowledge gap. Use the
`research` tool with a specific question that includes:

- The exact framework and version
- What you expected to happen
- What actually happened
- What you've already ruled out

Bad: "Why doesn't Svelte onclick work?"

Good: "In Svelte 5 with SvelteKit, a button rendered via SSR is visible
in Playwright but clicking it has no effect. Event handlers attached via
onclick prop don't fire. Existing similar buttons in the same app work
in tests. What causes SSR-rendered elements to be visible but not
interactive?"

## Recognizing the smell

You're going in circles if:

- You're trying different APIs that do the same thing
- You keep changing the same few lines hoping a variant will work
- You're adding diagnostic logging but not learning anything new from it
- Your inner monologue is "that's weird, let me try..." for the third
  time
- You've been on the same problem for more than 10 turns

When you notice any of these, invoke the core rule: get new information
from a different source before your next attempt.
