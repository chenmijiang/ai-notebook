# Simplify Commit Skill Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Rewrite the commit skill SKILL.md to produce faster, higher-quality commit messages.

**Architecture:** Single file replacement. Reduce workflow from 5 serial steps to 3. Add explicit rules to prevent verbose body and vague subject.

**Tech Stack:** Markdown (Claude Code skill)

---

### Task 1: Rewrite commit skill

**Files:**
- Modify: `~/.claude/skills/commit/SKILL.md` (full replacement)

**Step 1: Read current file**

Read `~/.claude/skills/commit/SKILL.md` to confirm current content.

**Step 2: Write new SKILL.md**

Replace with the following content:

```markdown
---
name: commit
description: Generate git commit messages from staged changes following Conventional Commits. Use when user wants to commit, asks for help writing commit messages, or invokes /commit command.
---

# Commit Message Generator

Generate commit messages from staged changes following Conventional Commits.

## Workflow

1. **Get staged diff**
   - Run `git diff --cached`
   - If output is empty, inform user there are no staged changes and exit

2. **Generate commit message**
   - Analyze the diff content
   - Apply the rules below to produce a commit message

3. **Confirm and commit**
   - Display the generated commit message
   - Ask user to confirm, edit, or cancel
   - Only commit after user confirmation
   - Run `git commit -m "<message>"`

## Message Format

<type>(<scope>): <subject>

<body>

<footer>

## Type Reference

| Type | Use Case |
|------|----------|
| feat | New feature |
| fix | Bug fix |
| docs | Documentation only |
| style | Code style (formatting, no logic change) |
| refactor | Code refactor (no feature/fix) |
| perf | Performance improvement |
| test | Add/modify tests |
| ci | CI/CD changes |
| chore | Build, deps, tooling |

## Rules

### Subject

- Max 50 characters, imperative mood, lowercase first letter, no period
- Be specific: reference concrete identifiers from the diff (function names, file names, module names)
- FORBIDDEN: vague subjects like "update code", "fix bug", "make changes", "minor updates"

### Body

- **Default: NO body.** Most commits need only a subject line.
- Add body ONLY when:
  - Multi-file changes need explanation of how they relate
  - Breaking change requires migration notes
  - The reason for the change is not obvious from the diff
- Body explains WHY, never repeats WHAT the diff shows
- Max 3 lines

### Scope

- Use the module or directory name as scope (e.g., `auth`, `api`, `ui`)
- If changes span multiple modules, omit scope

### Breaking Change

- Add `!` after type/scope: `feat(api)!: restructure response format`
- Add `BREAKING CHANGE:` in footer with migration details

## Examples

**Subject only (most commits):**

docs(guide): add Python async programming guide

**With body (multi-file, needs context):**

refactor(auth): extract token validation into middleware

Move validation logic from individual route handlers to shared
middleware. Reduces duplication across 5 endpoint files.

**Breaking change:**

feat(api)!: switch response envelope to JSON:API format

BREAKING CHANGE: response shape changed from {data, status} to {data, meta}.
Update all API clients to use new structure.
```

**Step 3: Verify the file**

Read the file back to confirm it was written correctly.

**Step 4: Commit**

```bash
git add ~/.claude/skills/commit/SKILL.md
```

No git commit needed here — this file is outside the current repo. If the skill directory is in a git repo, commit with:

```
chore(skill): simplify commit message generation rules
```
