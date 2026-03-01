# Commit Message Rules

Generate commit messages following Conventional Commits format.

## Format

```
<type>(<scope>): <subject>

<body>

<footer>
```

## Types

feat | fix | docs | style | refactor | perf | test | ci | chore

## Subject

- Max 50 characters, imperative mood, lowercase first letter, no period
- Reference concrete identifiers from the diff (function names, file names, module names)
- FORBIDDEN: vague subjects like "update code", "fix bug", "make changes", "minor updates"

## Body

- Default: NO body. Most commits need only a subject line.
- Add body ONLY when:
  - Multi-file changes need explanation of how they relate
  - Breaking change requires migration notes
  - The reason for the change is not obvious from the diff
- Body explains WHY, never repeats WHAT the diff shows
- Max 3 lines

## Scope

- Use module or directory name (e.g., `auth`, `api`, `ui`)
- Cross-module changes: omit scope

## Breaking Change

- Add `!` after type/scope: `feat(api)!: restructure response format`
- Add `BREAKING CHANGE:` in footer

## Examples

```
docs(guide): add Python async programming guide
```

```
refactor(auth): extract token validation into middleware

Move validation logic from route handlers to shared middleware.
Reduces duplication across 5 endpoint files.
```

```
feat(api)!: switch response envelope to JSON:API format

BREAKING CHANGE: response shape changed from {data, status} to {data, meta}.
```
