---
description: Write the design decisions from this conversation into .ai/brief.md
---

Write the design we agreed on in this conversation into `.ai/brief.md`. A
Neovim panel shows each section while I edit the matching code, so I can write
the core logic myself. Do not write or change any source code.

Focus, if I gave one: $ARGUMENTS

## Before writing

- Read the code you will mention, so every name matches the code exactly.
- If `.ai/brief.md` exists, read it and update it in place. Keep my edits,
  ticked items and notes for code outside this change. Remove only what this
  design replaced.

## Format

```markdown
# src/buffer_pool.cc
What this file is for, and the rules that hold for all of it. Three lines at most.

## BufferPool
Rules for the whole class, such as latch order or ownership.

## BufferPool::evict
Does: what the function is for, in one or two lines.
Change:
- [ ] What must be true when I'm done
Watch out: traps, such as locks held on entry or callers relying on side effects.

# Delegate
- [ ] Non-critical work for /delegate: tests, docs, wiring, CLI, config
```

- `#` headings are file paths relative to the project root. `##` headings are
  scopes inside that file.
- Use qualified names as they appear in the code (`Class::method`,
  `Outer::Inner`), with no parentheses or parameters. The panel finds notes by
  these names.
- Give each touched header its own `#` section with a file note. Notes for its
  functions can stay under the source file, as long as the names are qualified.
- Only add `##` sections for code this change touches, or code I need to
  understand to write it.
- Omit `Change:` for functions that only need explaining.
- Put `# Delegate` last, with one item per piece of non-critical work.

## What goes in the items

- Write `Change:` items as outcomes ("pinned pages are never evicted"), not
  instructions ("add `if (pinned) continue;`"). I decide how.
- Include only decisions we actually made. For anything we left open, add an
  item starting `Decide:`.
- One item per independent check, so each can be ticked separately.

When you're done, list the sections you added or changed, and any `Decide:`
items.
