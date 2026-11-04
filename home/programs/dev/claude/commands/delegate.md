---
description: Do the non-critical work listed under "# Delegate" in .ai/brief.md
---

I've written the core code for the plan in `.ai/brief.md`. Do the open items
under its `# Delegate` heading: tests, docs, wiring and other non-critical work.

Only these items, if I named any: $ARGUMENTS

## Before starting

- Read `.ai/brief.md` and the core code the items depend on.
- If any `Change:` item outside `# Delegate` is still open, stop and list them.
  Ask whether to continue anyway, since the core code may not be finished.

## While working

- **The core code is mine.** Don't change the logic of any function with a
  `Change:` list in the brief. If an item needs a change there, such as
  registering a hook, keep it minimal and point it out in the report.
- **Test the design, not just the code.** Base tests on the brief's
  `Change:` items, `Watch out:` lines and file notes. Tests copied from the
  implementation would pass even when it's wrong.
- **Match the project:** follow the existing style, test layout and build setup.
- **Ask instead of guessing** when an item depends on a decision the brief
  doesn't cover.
- When an item is done, tick it in the brief and add the main files:
  `- [x] Add CLI command for eviction stats (src/cli/stats.cc)`.

## When finished

Build and run the tests if the project has an obvious way to do so. Then
report:
- **Done:** items ticked, with files.
- **Core code touched:** any changes to functions with `Change:` lists, with
  file:line, or "none".
- **Not done:** items left open, and why.
- **Tests:** what you ran and the result, including failures.

End by asking me to review the diff before I commit.
