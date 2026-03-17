---
description: Quality check a recent implementation
---
Spawn yourself as a sub-agent via bash to do a code review: $@

Use `pi --print` with appropriate arguments. If the user specifies a model,
use `--provider` and `--model` accordingly.

Pass a prompt to the sub-agent emphasizing to the subagent that:
This project values above all else implementation simplicity and reuse of available framework/library components and common well-understood patterns in an effort to have the highest possible long-term maintainability for agentic developers. Please carefully analyze this implementation and tell me if you like it. Check for and comment about:
- Custom or overly complex implementation
- Code brevity and understandability. Are there any opportunities to simplify or remove code?
- Unnecessary hoisting or redirection
- Code duplication of any kind
- Test coverage and potency: are there missing tests or tests that don't exercise the app's functionality or otherwise trivially pass
- Error handling gaps

Do not read the code yourself. Let the sub-agent do that.

Report the sub-agent's findings.

