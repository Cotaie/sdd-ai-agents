# Jira Power

## Purpose

The Jira power lets SDD agents use Jira as an external planning and review
system when the user explicitly asks for Jira, a ticket, an issue, an epic, a
story, a sprint, or a backlog.

This power is reusable SDD infrastructure. It is separate from this repository's
project-local `.codex/config.toml`.

## Capabilities

### jira-read

- read projects
- read epics
- read stories
- read tasks
- read comments
- search issues
- download issue attachments when needed for the requested work

Allowed agents:

- sdd-product-agent
- sdd-requirements-reviewer
- sdd-architect-agent
- sdd-design-reviewer
- sdd-planner-agent
- sdd-task-reviewer
- sdd-documentation-release-agent

### jira-write-planning

- create epics
- create stories
- create tasks
- update labels
- write planning comments

Allowed agents:

- sdd-product-agent
- sdd-planner-agent
- sdd-documentation-release-agent

### jira-comment

- post review or planning comments to an explicitly named issue

Allowed agents:

- sdd-requirements-reviewer
- sdd-design-reviewer
- sdd-task-reviewer
- sdd-code-reviewer
- sdd-test-reviewer
- sdd-documentation-release-agent

### jira-attach

- attach generated review or validation artifacts to an explicitly named issue

Allowed agents:

- sdd-code-reviewer
- sdd-tester-agent
- sdd-test-reviewer
- sdd-documentation-release-agent

## Activation Keywords

- Jira
- ticket
- issue
- epic
- story
- task
- sprint
- backlog

## Use When

- the user asks to read Jira project context
- the user provides a Jira issue key
- the user asks to create Jira planning work
- the user asks to post or attach a result to Jira

## Do Not Use When

- the user only asks for local SDD artifacts
- the user has not mentioned Jira or a Jira-like work item
- a reviewer produced findings but the user did not explicitly request Jira
  persistence
- the target issue key or project key is missing for a write operation

## Safety Rules

- Never post comments, create issues, transition issues, or attach files unless
  the user explicitly asks for that external persistence.
- Ask for or discover the project key before creating Jira issues.
- Preserve local artifacts as the source of truth unless the user asks to sync
  them to Jira.
- Do not include local secrets, API tokens, or private environment values in Jira
  content.
- Treat Jira write operations as persistent external side effects.

## Available MCP Tools

Expected MCP server name: `sdd_jira`

Common tool categories:

- project listing and project issue reads
- issue reads and searches
- issue creation and updates
- comments
- attachments
- versions and components

## Required Credentials

Credentials are provided through environment variables declared in
`secrets.template`.

## Examples

- "Read SDD-12 and summarize the acceptance criteria."
- "Create Jira tasks in SDD for this task breakdown."
- "Post this review as a comment on SDD-14."
- "Attach the validation report to SDD-20."

