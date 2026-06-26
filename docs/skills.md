# Skills

This document defines how SDD Codex skills are structured and used.

## Purpose

Skills are reusable workflow capabilities. They give agents repeatable procedures without making every agent instruction file large.

Each skill has:

- YAML frontmatter with a stable `name` and `description`
- a `SKILL.md`
- `When to use`
- `Steps`
- `References` where needed

Skills represent repeatable procedures that agents can invoke or follow.

## Installation

Skills should be installed under:

```text
~/.agents/skills/
```

The installer should support symlink and copy modes.

## Developer Skill Layering

Developer skills should be layered:

- `developers`: generic SDD implementation discipline and artifact rules
- `typescript`: TypeScript-specific implementation rules
- `python`: Python-specific implementation rules

The repository uses a single developer agent that combines `developers` with
the relevant stack skill.

Examples:

```text
sdd-developer-agent
  skills:
    - developers
    - typescript

sdd-developer-agent
  skills:
    - developers
    - python
```

The generic `sdd-developer-agent` may include both stack skills when the task
touches multiple layers.

## Target Skill Layout

```text
skills/
  product-agent/
    SKILL.md
  requirements-reviewer/
    SKILL.md
  architect-agent/
    SKILL.md
  design-reviewer/
    SKILL.md
  planner-agent/
    SKILL.md
  task-reviewer/
    SKILL.md
  developers/
    SKILL.md
    typescript/
      SKILL.md
    python/
      SKILL.md
  code-reviewer/
    SKILL.md
  tester-agent/
    SKILL.md
  test-reviewer/
    SKILL.md
  documentation-release-agent/
    SKILL.md
```
