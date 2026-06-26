# Skills

This document defines how SDD Codex skills are structured and used.

## Purpose

Skills are reusable workflow capabilities. They give agents repeatable procedures without making every agent instruction file large.

Each skill has:

- a `SKILL.md`
- trigger guidance
- required inputs
- expected outputs
- step-by-step behavior
- artifact templates or references where needed

Skills represent repeatable procedures that agents can invoke or follow.

## Installation

Skills should be installed under:

```text
~/.agents/skills/
```

The installer should support symlink and copy modes.

## Developer Skill Layering

Developer skills should be layered:

- `sdd-developer`: generic SDD implementation discipline and artifact rules
- `sdd-developer-typescript`: TypeScript-specific implementation rules
- `sdd-developer-python`: Python-specific implementation rules

The repository uses a single developer agent that combines `sdd-developer` with
the relevant stack skill.

Examples:

```text
sdd-developer-agent
  skills:
    - sdd-developer
    - sdd-developer-typescript

sdd-developer-agent
  skills:
    - sdd-developer
    - sdd-developer-python
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
