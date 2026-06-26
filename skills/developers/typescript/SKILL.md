---
name: typescript
description: Use when the implementation task is clearly TypeScript-based within Specification Driven Development work, including frontend or backend TypeScript code.
license: MIT
compatibility: Designed for Codex
metadata:
  author: cotaie
  version: "1.0"
---

# TypeScript Developer Skill

## Project defaults

- If the repository does not say otherwise, follow the project's existing package manager and test tooling.
- Preserve type safety and the project's established TypeScript patterns.

## Steps

1. Read the approved requirements, design, and task scope first.
2. Identify the smallest implementation path and the files that need to change.
3. Add a focused test update before changing behavior.
4. Keep the changes focused on the approved task.
5. Add or update TypeScript tests when behavior changes.

## Code style

- Preserve type safety.
- Avoid weakening types to hide defects.
- Keep changes aligned with the project's existing TypeScript patterns.

## Review checklist

- The task is satisfied.
- Tests cover the new behavior.
- Existing public APIs remain compatible unless the spec says otherwise.
- The relevant format, lint, type-check, and tests pass.

## References

- [Developer skills](../SKILL.md)
