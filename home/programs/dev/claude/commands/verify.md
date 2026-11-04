---
description: Check my changes against .ai/brief.md and tick off finished items
allowed-tools: Read, Grep, Glob, Bash(git diff:*), Bash(git status:*)
---

I wrote the core code for the plan in `.ai/brief.md`. Check my work against it.
You may edit `.ai/brief.md` as described below. Do not edit any other file.

Focus, if I gave one: $ARGUMENTS

Changed files:

!`git status --short`

My changes:

!`git diff HEAD`

Untracked files don't appear in the diff, so read any that are listed above.
Then read `.ai/brief.md` and as much of the surrounding code as you need.

## 1. Check each open item

For every unticked item under `Change:`, outside `# Delegate`:

| You find | Edit |
|---|---|
| Clearly done | Tick it and add where: `- [x] Pinned pages are never evicted (src/buffer_pool.cc:42)` |
| Partly done, or you're unsure | Leave it open and append a question: `- [ ] Pinned pages are never evicted. Q: only checked on the fast path; intended?` |
| Not done | Leave it unchanged |

Only tick an item when you can point to the line that does it. A wrong tick
hides work I skipped, so when in doubt, ask.

## 2. Keep the notes accurate

- `Does:` says what a function is for, not how it currently works. Only
  correct it if my change gave the function a different purpose. Never
  rewrite a note to match code that conflicts with an open item: the code
  may be the mistake.
- If a `Watch out:` line no longer applies, correct it.
- If my diff changes a function that has no `##` section, add a short one with
  `Does:` and, if needed, `Watch out:`. Don't add `Change:` items.

## 3. Raise up to three concerns

Look for problems the brief doesn't cover: broken invariants, unhandled
failure paths, wrong assumptions about code I call. Report at most three, each
tied to a file:line and phrased as a question. Skip style comments.

## Rules for editing the brief

- Change only checkboxes, appended notes, and the lines described in step 2.
- Never reword my items or remove anything.
- Don't touch `# Delegate`.

## Report

Reply with:
- **Ticked:** items you ticked.
- **Open:** items still open, with any questions.
- **Concerns:** up to three, or "none".

If every `Change:` item is ticked and there are no concerns, say the core work
looks complete and `/delegate` can do the rest.
