# SDD AI Agents

Codex agent configuration project for a manual Spec-Driven Development workflow.

This repository defines:

- role-specific Codex custom agents
- reusable Codex skills
- external tool powers and MCP configuration fragments
- installer, uninstaller, and diagnostic scripts
- documentation for manual agent selection and review behavior

Current docs:

- [Requirements](docs/requirements.md)
- [Workflow](docs/workflow.md)
- [Skills](docs/skills.md)
- [Powers and MCP](docs/powers.md)

## Project-local Jira configuration

This repository includes a project-local Codex MCP configuration for managing
the SDD-AI-Agents Jira project:

- `.codex/config.toml` defines the `sdd_project_jira` MCP server.
- `.codex/.env.example` documents the required Jira environment variables.
- `.codex/load-project-env.sh` loads local Jira credentials from
  `.codex/.env.local`.

The project-local Jira configuration is separate from the reusable SDD power
definitions under `powers/`. Real credentials and local Codex state must remain
untracked.
