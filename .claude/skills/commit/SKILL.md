---
name: commit
description: Generate git commit messages from staged changes following Conventional Commits specification. Use when user wants to commit staged changes, asks for help writing commit messages, or invokes /commit command. Analyzes git diff, generates English commit message, and asks for user confirmation before committing.
---

# Commit Message Generator

Generate commit messages from staged changes following Conventional Commits specification.

## Workflow

1. **Check staged changes**
   - Run `git status` to verify staged files exist
   - If no staged changes, inform user and exit

2. **Analyze changes**
   - Run `git diff --cached` to get staged diff
   - Run `git log --oneline -5` to understand recent commit style

3. **Generate commit message**
   - Analyze the diff content
   - Determine appropriate type: `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `ci`, `chore`
   - Identify scope if applicable
   - Write concise subject line (max 50 chars, imperative mood, no period)
   - Add body if changes need explanation

4. **Present to user**
   - Display the generated commit message
   - Ask user to confirm, edit, or cancel

5. **Execute commit**
   - Only commit after user confirmation
   - Run `git commit -m "<message>"`
   - Show commit result

## Message Format

```
<type>(<scope>): <subject>

<body>

<footer>
```

## Type Reference

| Type       | Use Case                                 |
| ---------- | ---------------------------------------- |
| `feat`     | New feature                              |
| `fix`      | Bug fix                                  |
| `docs`     | Documentation only                       |
| `style`    | Code style (formatting, no logic change) |
| `refactor` | Code refactor (no feature/fix)           |
| `perf`     | Performance improvement                  |
| `test`     | Add/modify tests                         |
| `ci`       | CI/CD changes                            |
| `chore`    | Build, deps, tooling                     |

## Subject Rules

- Use imperative mood: "add feature" not "added feature"
- Lowercase first letter
- No period at end
- Max 50 characters
- Be specific and concise

## Examples

**Single file doc update:**

```
docs(guide): add Python async programming guide
```

**Bug fix with scope:**

```
fix(auth): resolve token refresh race condition
```

**Feature with body:**

```
feat(api): add user export endpoint

Support CSV and JSON export formats for user data.
Includes pagination for large datasets.
```
