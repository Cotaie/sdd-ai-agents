# GitHub Power

## Purpose

The GitHub power lets SDD agents read repository development context and write
issue or pull request comments when the user explicitly asks for GitHub, a
repository, an issue, a pull request, a branch, a commit, or checks.

## Capabilities

### github-read

- read repositories
- read issues
- read pull requests
- read diffs
- read checks
- read branches and commits

Allowed agents:

- all SDD agents

### github-review-comment

- write pull request comments
- write pull request review summaries

Allowed agents:

- sdd-code-reviewer

### github-issue-write

- create issues
- update issue labels
- write issue comments

Allowed agents:

- sdd-planner-agent
- sdd-tester-agent
- sdd-documentation-release-agent

### github-merge

- merge pull requests
- push protected branch changes

Allowed agents:

- none in v1

## Activation Keywords

- GitHub
- repository
- repo
- pull request
- PR
- issue
- branch
- commit
- checks

## Use When

- the user asks to inspect GitHub repository, issue, pull request, branch,
  commit, diff, or check context
- the user asks to post a review or summary to a pull request
- the user asks to create or update GitHub issues

## Do Not Use When

- local git state is enough for the requested answer
- the user did not ask for GitHub context or persistence
- a reviewer produced findings but the user did not explicitly request a GitHub
  comment or review
- the target repository, pull request, or issue is missing for a write operation

## Safety Rules

- Never post comments, create issues, update labels, or create reviews unless the
  user explicitly asks for that external persistence.
- Do not merge pull requests or push protected branch changes in v1.
- Do not include local secrets, tokens, or private environment values in GitHub
  content.
- Prefer read-only GitHub access for review context unless a write destination is
  explicit.

## Available Tools

Expected MCP server name: `sdd_github`

Fallback CLI:

- `gh` when installed and authenticated

Common tool categories:

- repository reads
- issue and pull request reads
- commit, diff, and check reads
- issue comments
- pull request comments or reviews

## Required Credentials

Credentials are provided through environment variables declared in
`secrets.template`, or through an authenticated `gh` CLI session when used as a
fallback.

## Examples

- "Review PR 12 in GitHub."
- "Read the checks for this pull request."
- "Post this code review summary to PR 12."
- "Create a GitHub issue for this validation failure."

