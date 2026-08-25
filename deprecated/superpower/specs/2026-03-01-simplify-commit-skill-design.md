# Simplify Commit Skill Design

## Problem

Current commit skill generates slow, low-quality commit messages:

- **Slow**: 5 serial steps including unnecessary `git status` and `git log`
- **Verbose body**: AI over-generates body content by default
- **Vague subject**: Produces generic subjects like "update code" or "fix bug"

## Design

### Workflow (3 steps, down from 5)

1. `git diff --cached` — empty output means no staged changes, exit
2. Generate message — analyze diff, apply rules below
3. Confirm and commit — show message, commit after user approval

Removed: `git status` (redundant), `git log` (introduces noise when history style is inconsistent)

### Message Rules

**Subject:**

- Max 50 chars, imperative mood, lowercase first letter, no period
- Must reference specific identifiers from the diff (function/file/module names)
- Forbidden: vague subjects like "update code", "fix bug", "make changes"

**Body (opt-out by default):**

- Default: no body. One-line subject only.
- Add body ONLY when: multi-file changes need correlation explanation, breaking change, or the "why" is not obvious from the diff
- Body must explain WHY, never repeat WHAT the diff shows
- Max 3 lines

**Scope:**

- Use module/directory name as scope
- Cross-module changes: omit scope

**Breaking change:**

- Add `!` suffix to type: `feat(api)!: ...`
- Add `BREAKING CHANGE:` footer

### Structure

```
frontmatter (name + description)
# Title
## Workflow (3 steps)
## Message Format (template)
## Type Reference (table)
## Rules (subject / body / scope / breaking change)
## Examples (3: subject-only / with body / breaking change)
```

Target: ~80-90 lines, English.
