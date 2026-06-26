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
- `sdd-developer-react`: React-specific implementation rules
- `sdd-developer-node`: Node.js-specific implementation rules

Specialized developer agents should reference `sdd-developer` and the relevant stack-specific skills.

Examples:

```text
sdd-typescript-developer
  skills:
    - sdd-developer
    - sdd-developer-typescript

sdd-react-developer
  skills:
    - sdd-developer
    - sdd-developer-typescript
    - sdd-developer-react

sdd-python-developer
  skills:
    - sdd-developer
    - sdd-developer-python
```

The generic `sdd-developer-agent` may reference only `sdd-developer` when acting as a fallback or coordinator.

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
    react/
      SKILL.md
    node/
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
