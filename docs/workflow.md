# SDD Agent Workflow

This document defines how users manually choose and use the SDD Codex agents during development.

## Core Rule

The user manually chooses which specialized agent to use at each point in development.

Each agent gives role-specific output that helps the user decide the next step:

- continue with the next agent
- revise the current work
- ask for a review
- implement a task
- validate behavior
- persist an artifact, comment, or report

The user remains in control. Agents produce recommendations, implementation changes, reviews, or artifacts as requested.

Artifacts are created when useful or required. Review results are displayed in terminal/chat by default. Review files, Jira comments, GitHub comments, or other persisted review records are created only when explicitly requested by the user.

## Manual Agent Selection

There is no automatic state machine. There is no requirement that every task pass through every agent.

Use the agent that matches the current need. Once design and tasks are clear, implementation tasks go to the single developer agent. The Architect Agent is used again only when the user decides a missing design decision, architectural conflict, or unclear technical direction needs architectural input.

| Phase | Typical Input | Agent | Typical Output | Optional Follow-up |
| --- | --- | --- | --- | --- |
| Requirements | Idea, prompt, business context | Product Agent | Requirements guidance or `requirements.md` | Requirements Reviewer |
| Design | Requirements or product direction | Architect Agent | Design guidance, `design.md`, ADR/API/data-model artifacts | Design Reviewer |
| Planning | Requirements and design direction | Planner Agent | Task breakdown or `tasks.md` | Task Reviewer |
| Implementation | Task or task slice | Developer Agent | Source changes, tests, implementation notes | Code Reviewer |
| Validation | Implementation and expected behavior | Tester Agent | Test execution summary, bug reports, `validation-report.md` | Test Reviewer |
| Release | Completed implementation and validation evidence | Documentation / Release Agent | Documentation, changelog, migration notes, release notes | Optional future docs reviewer |

The table is a usage guide, not an execution engine.

Users may choose to go back to an earlier agent when they find a gap. Examples:

- Developer finds the task is underspecified -> return to Planner Agent.
- Developer finds the design is missing an interface or data decision -> return to Architect Agent.
- Code Reviewer finds behavior does not match requirements -> return to Product Agent or Planner Agent, depending on whether the issue is scope or implementation detail.
- Tester finds missing acceptance criteria -> return to Product Agent.

For implementation, the user or Planner Agent may split work into multiple task slices. Each slice can be implemented and reviewed independently before broader validation.

## Review Results

Reviewers produce review results, not mandatory review files.

Default behavior:

- display the review result in terminal/chat
- include findings, evidence, and final status
- do not create `*-review.md`
- do not post to Jira, GitHub, Confluence, or another external system

Persistent review output is optional and must be explicitly requested by the user.

Supported persistence targets:

- markdown file under `docs/reviews/<initiative>/`
- Jira comment on a specified issue, story, task, epic, or bug
- GitHub pull request review or comment
- Confluence page/comment when a future power supports it

Examples:

```text
docs/reviews/initial-project/requirements-review.md
docs/reviews/jira-power/design-review-r2.md
docs/reviews/developer/code-review.md
```

If multiple review rounds are persisted, use a clear suffix such as `-r2`, `-r3`, or a short date stamp.

Jira persistence requires an explicit target issue key and the relevant Jira power. Example user requests:

- "Post this review as a comment on DEV-123."
- "Attach the review to the Jira task."
- "Save this requirements review under docs/reviews/initial-project/."

Reviewer agents must not persist review results externally unless the user explicitly asks for that destination.

## Status Values

Review results must end with exactly one status:

- `APPROVED`
- `CHANGES_REQUESTED`
- `BLOCKED`

`APPROVED` means the artifact can be used as input by the next creator agent.

`CHANGES_REQUESTED` means the creator must revise the artifact.

`BLOCKED` means the reviewer cannot make a decision because required information is missing or contradictory.

## Agent Set

Codex custom agent names use the `sdd-` prefix to reduce collisions in user-level installations.

Example:

- role label: Code Reviewer
- custom agent name: `sdd-code-reviewer`
- config file: `agents/code-reviewer.toml`

### Product Agent

Creates `requirements.md`.

Responsibilities:

- clarify product intent
- define functional requirements
- define non-functional requirements
- define user stories
- define acceptance criteria
- define business rules
- identify scope boundaries

Forbidden:

- approve its own requirements
- design implementation architecture
- write production code

### Requirements Reviewer

Produces a requirements review result.

Responsibilities:

- check completeness
- detect ambiguity
- check consistency
- check testability
- find missing edge cases
- validate scope boundaries
- display review findings in terminal/chat by default
- persist the review only when the user explicitly requests a file, Jira comment, GitHub comment, or another configured destination

Forbidden:

- rewrite `requirements.md` directly
- create `requirements-review.md` unless explicitly requested
- post to Jira/GitHub/Confluence unless explicitly requested with a target
- approve without evidence

### Architect Agent

Creates `design.md` and optional ADRs/API/data-model artifacts.

Responsibilities:

- define system architecture
- define components
- define interfaces
- choose technologies
- document design decisions
- map design choices to approved requirements

Forbidden:

- modify approved requirements
- implement production code
- approve its own design

### Design Reviewer

Produces a design review result.

Responsibilities:

- check requirement traceability
- check architectural consistency
- evaluate complexity
- evaluate scalability
- evaluate security implications
- identify missing components
- display review findings in terminal/chat by default
- persist the review only when the user explicitly requests a file, Jira comment, GitHub comment, or another configured destination

Forbidden:

- rewrite `design.md` directly
- create `design-review.md` unless explicitly requested
- post to Jira/GitHub/Confluence unless explicitly requested with a target
- approve without evidence

### Planner Agent

Creates `tasks.md`.

Responsibilities:

- break work into small tasks
- define dependencies
- prioritize work
- estimate complexity
- identify verification steps
- map tasks to requirements and design sections

Forbidden:

- change requirements or design
- implement tasks
- approve its own task plan

### Task Reviewer

Produces a task review result.

Responsibilities:

- find missing tasks
- find duplicate tasks
- check task ordering
- check task scope
- check testability
- check dependency correctness
- display review findings in terminal/chat by default
- persist the review only when the user explicitly requests a file, Jira comment, GitHub comment, or another configured destination

Forbidden:

- rewrite `tasks.md` directly
- create `task-review.md` unless explicitly requested
- post to Jira/GitHub/Confluence unless explicitly requested with a target
- approve without evidence

### Developer Stage

Creates implementation changes and unit tests.

The developer stage uses one implementation agent:

- `sdd-developer-agent` is the standard implementation agent.
- `sdd-developer` is the generic implementation skill.
- `sdd-developer-typescript` and `sdd-developer-python` add stack-specific rules.

Use `sdd-developer-agent` for implementation tasks when the stack is known or
when the task spans both TypeScript and Python.

Responsibilities:

- implement exactly the assigned task
- follow approved architecture
- write or update tests
- keep changes scoped
- report implementation notes
- follow generic SDD developer rules
- follow stack-specific language rules when relevant

Forbidden:

- approve its own code
- modify requirements or design
- expand scope without approval

### Code Reviewer

Produces a code review result.

Responsibilities:

- verify acceptance criteria implementation
- verify business rules
- verify design compliance
- verify task scope
- check readability and maintainability
- check performance risks
- check security risks
- check error handling
- check test coverage and regression risk
- display review findings in terminal/chat by default
- persist the review only when the user explicitly requests a file, Jira comment, GitHub PR comment/review, or another configured destination

Forbidden:

- edit implementation code
- modify specifications
- create `code-review.md` unless explicitly requested
- post to Jira/GitHub/Confluence unless explicitly requested with a target
- approve without evidence

### Tester Agent

Creates `validation-report.md` and bug reports where needed.

Responsibilities:

- execute tests
- validate behavior against requirements
- detect regressions
- report failures with reproduction details
- summarize test evidence

Forbidden:

- approve final validation alone
- change requirements or design

### Test Reviewer

Produces a test review result.

Responsibilities:

- check requirement coverage
- check missing scenarios
- check missing edge cases
- check test reliability
- check test quality
- display review findings in terminal/chat by default
- persist the review only when the user explicitly requests a file, Jira comment, GitHub comment, or another configured destination

Forbidden:

- rewrite tests directly in review mode
- create `test-review.md` unless explicitly requested
- post to Jira/GitHub/Confluence unless explicitly requested with a target
- approve without evidence

### Documentation / Release Agent

Creates release documentation.

Responsibilities:

- update user-facing documentation
- update developer documentation
- prepare changelog entries
- prepare migration notes
- prepare release notes
- confirm docs match approved implementation

Forbidden:

- change implementation behavior
- invent release scope not present in approved artifacts

## Artifact Ownership

| Artifact | Creator | Reviewer |
| --- | --- | --- |
| `requirements.md` | Product Agent | Requirements Reviewer |
| `design.md` | Architect Agent | Design Reviewer |
| `tasks.md` | Planner Agent | Task Reviewer |
| Source code and unit tests | Specialized Developer Agent | Code Reviewer |
| `validation-report.md` | Tester Agent | Test Reviewer |
| Release documentation | Documentation / Release Agent | Optional future docs reviewer |

Review results are useful decision support but are not mandatory files. Persistent review records live under `docs/reviews/<initiative>/` only when explicitly requested.
