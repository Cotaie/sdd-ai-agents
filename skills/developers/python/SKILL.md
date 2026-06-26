---
name: python
description: Use when the implementation task is clearly Python-based within Specification Driven Development work, including Python code, tests, scripts, packaging, or automation.
license: MIT
compatibility: Designed for Codex
metadata:
  author: cotaie
  version: "1.0"
---

# Python Developer Skill

## Project defaults

- If the repository does not say otherwise, assume Python 3.12.
- If the repository does not say otherwise, use `uv` for dependency and command execution.
- If the repository does not say otherwise, use `ruff` for formatting and linting.
- If the repository does not say otherwise, use `pytest` for tests.
- If the repository does not say otherwise, use `mypy` for static typing.

## Steps

1. Read the approved requirements, design, and task scope first.
2. Identify the smallest implementation path and the files that need to change.
3. Add a failing test or a focused test update before changing behavior.
4. Implement the change with the project's typing, packaging, dependency, and error-handling conventions.
5. Run the relevant checks:

```bash
uv run ruff format .
uv run ruff check .
uv run mypy .
uv run pytest
```

6. Summarize changed files and test results.

## Code style

- Do not add unnecessary abstractions.
- Do not catch broad exceptions unless re-raising with context.
- Keep IO at the edges.
- Keep domain logic independent of frameworks.
- Use explicit return types for public functions.

## Testing

- Put unit tests in `tests/unit` when the project uses that layout.
- Put integration tests in `tests/integration` when the project uses that layout.
- Prefer fixtures over repeated setup.
- Mock external services.
- Do not require network access in unit tests.

## Review checklist

- The spec or task is satisfied.
- Tests cover the new behavior.
- Existing public APIs remain compatible unless the spec says otherwise.
- Format, lint, type-check, and tests pass.

## References

- [Developer skills](../SKILL.md)
