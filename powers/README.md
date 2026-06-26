# Power Catalog

This catalog defines external tool capabilities that SDD agents may be allowed
to use.

V1 powers are declarative. They are enforced through agent instructions, Codex
sandbox modes, approval policy, MCP or connector availability, CLI credentials,
and future hooks.

## External Power Folders

- [Jira](jira/POWER.md) - read and write planning artifacts in Jira when the
  user explicitly asks to use Jira.
- [GitHub](github/POWER.md) - read repository development context and write
  issue or pull request comments when explicitly requested.

Each external power folder may include:

- `POWER.md` - agent and user instructions for the power.
- `mcp.toml` - optional Codex MCP configuration fragment.
- `secrets.template` - required environment variable placeholders.

## Filesystem Powers

### filesystem-read

Provider: local filesystem

Capabilities:

- read project files
- inspect SDD artifacts
- inspect source code and tests

Allowed agents:

- all SDD agents

### filesystem-write-artifacts

Provider: local filesystem

Capabilities:

- create or update SDD artifacts
- create or update review reports
- create or update documentation artifacts

Allowed agents:

- sdd-product-agent
- sdd-requirements-reviewer
- sdd-architect-agent
- sdd-design-reviewer
- sdd-planner-agent
- sdd-task-reviewer
- sdd-code-reviewer
- sdd-tester-agent
- sdd-test-reviewer
- sdd-documentation-release-agent

### filesystem-write-code

Provider: local filesystem

Capabilities:

- edit source code
- edit tests
- create implementation files

Allowed agents:

- sdd-developer-agent
- sdd-typescript-developer
- sdd-react-developer
- sdd-node-developer
- sdd-python-developer

## Shell Powers

### shell-run-tests

Provider: local shell

Capabilities:

- run test commands
- run lint commands
- run build or validation commands

Allowed agents:

- sdd-developer-agent
- sdd-typescript-developer
- sdd-react-developer
- sdd-node-developer
- sdd-python-developer
- sdd-code-reviewer
- sdd-tester-agent
- sdd-test-reviewer

## Deployment Powers

### production-deploy

Provider: deployment platform

Capabilities:

- deploy to production
- approve production release

Allowed agents:

- none in v1
