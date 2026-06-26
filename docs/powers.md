# Powers And MCP

This document defines how SDD powers work and how external tool capabilities are configured for Codex.

## Purpose

In this project, a power means an external tool capability that an agent is allowed to use when it is available.

Powers are not generic personality traits. They describe concrete tool access such as:

- read Jira projects, epics, issues, and comments
- create Jira epics, stories, tasks, and comments
- read GitHub repositories, issues, pull requests, diffs, and checks
- write GitHub pull request comments or review summaries
- run local test commands
- read or write project files

## Power Contract

A power has:

- a stable name
- a provider such as Jira, GitHub, filesystem, shell, or Codex
- concrete capabilities
- access level such as read, write, or admin-like
- required setup such as MCP servers, app connectors, CLI tools, or environment variables
- allowed agents
- safety rules
- activation rules
- credential requirements
- optional Codex MCP configuration
- enforcement status

Codex does not currently expose a single first-class object named `power`, so v1 represents powers declaratively and maps them onto available Codex mechanisms:

- agent developer instructions
- sandbox mode
- approval policy
- enabled or disabled skills
- MCP server configuration
- connector configuration
- CLI tools such as `gh`
- hooks or scripts for later enforcement
- installer-managed configuration

## Example Powers

- `jira-read`
- `jira-comment`
- `jira-write-planning`
- `jira-attach`
- `github-read`
- `github-review-comment`
- `github-issue-write`
- `filesystem-read`
- `filesystem-write-artifacts`
- `filesystem-write-code`
- `shell-run-tests`

## Power Folder Format

V1 should use one folder per external power. The initial external power folders
are Jira and GitHub:

```text
powers/
  jira/
    POWER.md
    mcp.toml
    secrets.template
  github/
    POWER.md
    mcp.toml
    secrets.template
```

`POWER.md` documents the power for agents and users:

- what the power is for
- when to use it
- when not to use it
- activation keywords
- available MCP tools or CLI tools
- required credentials
- safety rules
- examples

`mcp.toml` is a Codex config fragment containing one or more `[mcp_servers.<name>]` tables. Codex uses TOML for MCP configuration, not JSON.

`secrets.template` declares required environment variables without storing real secrets.

Example:

```text
# powers/jira/secrets.template
# JIRA_URL=https://your-company.atlassian.net
# JIRA_USERNAME=your.email@example.com
# JIRA_API_TOKEN=your-api-token
```

Powers may also be documentation-only if no MCP server or credentials are required.

## Activation Rules

Power activation rules are mandatory for powers that expose external tools.

For example, Jira tools should only be used when the user explicitly mentions Jira, ticket, issue, epic, story, sprint, or backlog. General SDD artifact writing must use local files instead of external issue trackers unless the user asks for the external system.

External persistence also requires explicit user intent and a target. For example, a reviewer may post a result to Jira only when the user asks for that and provides the issue key.

## Installation

Power folders should be installed or linked under:

```text
${CODEX_HOME:-$HOME/.codex}/sdd-ai-agents/powers/
```

The top-level `powers/README.md` should act as the catalog and index. Per-power `POWER.md` files are the detailed instruction source.

## Secrets

The installer should create a project-owned secrets file:

```text
${CODEX_HOME:-$HOME/.codex}/sdd-ai-agents/secrets
```

The installer should append missing placeholder blocks from `powers/*/secrets.template` while preserving existing user-provided values.

The secrets file must not be committed to Git and should use restrictive permissions:

```bash
chmod 600 "${CODEX_HOME:-$HOME/.codex}/sdd-ai-agents/secrets"
```

## MCP TOML Merge

Codex reads MCP servers from `config.toml`, typically:

```text
${CODEX_HOME:-$HOME/.codex}/config.toml
```

Power-level `mcp.toml` files are source fragments. Codex does not automatically scan them. When `--with-mcp` is used, the installer should merge these fragments into Codex config.

Merge rules:

- back up `config.toml` before editing
- record the edit and backup path in the install manifest
- manage only MCP server blocks owned by this project
- use a clear server naming prefix such as `sdd_`
- preserve unrelated user config
- support dry-run output showing the exact blocks that would be added, changed, or removed

Example fragment:

```toml
[mcp_servers.sdd_jira]
command = "uvx"
args = ["mcp-atlassian"]
env_vars = ["JIRA_URL", "JIRA_USERNAME", "JIRA_API_TOKEN"]
enabled = true
default_tools_approval_mode = "prompt"
```
