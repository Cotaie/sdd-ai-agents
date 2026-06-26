# SDD AI Agents Requirements

## 1. Purpose

This project defines and installs reusable Spec-Driven Development (SDD) agents, skills, powers, and guidance for Codex.

The project is the source of truth for:

- role-specific Codex agents
- reusable Codex skills
- artifact templates
- agent usage guidance
- local installer scripts
- optional plugin packaging

After installation, all Codex sessions running under the same WSL user should be able to use the installed SDD agents and skills from any project.

## 2. Core Idea

The user manually chooses the appropriate agents one by one during development.

Each agent is responsible for a specific kind of guidance or work:

- product and requirements thinking
- architecture and design thinking
- planning and task breakdown
- implementation
- review and validation
- documentation and release preparation

The user drives the process by choosing the next appropriate agent, reading its output, and deciding whether to continue, revise, ask another agent, or persist an artifact.

Tasks do not need to pass through every agent. Earlier agents are reused only when the user decides later work revealed a missing requirement, missing design decision, unclear task, validation gap, or other upstream issue.

Artifacts are created when they are useful or required. They are not mandatory for every interaction.

Reviewer agents provide findings and recommendations in terminal/chat by default. Review files, Jira comments, GitHub comments, or other persisted review records are created only when the user explicitly requests them.

## 3. Target Platform

The first supported platform is local Codex running in WSL.

The project should install assets into user-level Codex locations so they are available across local projects.

Expected install targets:

```text
~/.codex/agents/        # custom Codex agents
~/.agents/skills/       # user-level Codex skills
~/.codex/config.toml    # optional Codex configuration changes
~/.codex/plugins/       # optional local plugin package
~/.agents/plugins/      # optional local plugin marketplace
```

The installer should prefer symlinks during local development so changes in this repository are immediately reflected in Codex after restart or reload when required.

## 4. Concept Model

### 4.1 Agents

Agents are role-specific Codex custom agents. Each agent has:

- a stable name
- a concise description
- developer instructions
- allowed responsibilities
- forbidden responsibilities
- recommended model/reasoning settings where appropriate
- optional sandbox settings
- references to skills it should use

Agents represent execution identity and behavioral boundaries.

### 4.2 Skills

Skills are reusable workflow capabilities that agents can invoke or follow.

Detailed skill structure and developer-skill layering live in [skills.md](skills.md).

### 4.3 Powers

Powers are external tool capabilities that agents are allowed to use when available.

Detailed power structure, activation rules, secrets handling, and MCP TOML merge behavior live in [powers.md](powers.md).

### 4.4 Sandbox Modes

Sandbox mode is the Codex execution boundary for local file and command access.

The main modes used by this project are:

- `read-only`: the agent can inspect files but cannot edit files or run commands outside that boundary without approval.
- `workspace-write`: the agent can read files, write inside the active workspace, and run routine local commands inside the workspace boundary.

This is separate from powers. For example, `jira-write-planning` is an external tool power, while `workspace-write` is a local Codex sandbox boundary.

V1 uses practical reviewer mode by default:

- creator agents use `workspace-write` so they can create artifacts
- reviewer agents use `workspace-write` so they can create review files only when explicitly requested
- reviewer instructions forbid editing the artifact under review

Strict reviewer mode is a future or optional profile:

- reviewer agents use `read-only`
- reviewer agents return review text in chat
- another authorized actor writes the review artifact

Per-file write enforcement, such as "reviewers may only write `*-review.md`", requires hooks or wrapper tooling beyond basic sandbox mode.

### 4.5 Review Results

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

### 4.6 Artifacts

Artifacts are markdown files or structured documents produced by agents when useful or requested.

Initial artifacts:

- `requirements.md`
- `design.md`
- `tasks.md`
- implementation source changes
- implementation tests
- `validation-report.md`
- release documentation

Optional persisted review artifacts:

- `docs/reviews/<initiative>/requirements-review.md`
- `docs/reviews/<initiative>/design-review.md`
- `docs/reviews/<initiative>/task-review.md`
- `docs/reviews/<initiative>/code-review.md`
- `docs/reviews/<initiative>/test-review.md`

## 5. SDD Workflow

The detailed manual agent selection guide, role contracts, review behavior, and artifact ownership guidance live in [workflow.md](workflow.md).

The implementation must provide Codex agents and skills that support that usage model.

## 6. Installer Requirements

The project must provide an installer script that can set up the local Codex environment for the current WSL user.

Initial command:

```bash
./scripts/install.sh
```

Installer responsibilities:

- validate it is running from the repository root
- create required user-level Codex directories
- install or symlink custom agents into `~/.codex/agents`
- install or symlink skills into `~/.agents/skills`
- install or symlink power folders into this project's Codex state directory
- create or update a project-owned secrets file from `powers/*/secrets.template`
- optionally merge `powers/*/mcp.toml` fragments into `~/.codex/config.toml`
- optionally install plugin metadata
- write an install manifest containing every local Codex or agent-system path created or modified by this project
- mark copied managed files with a project-owned header where the file format allows it
- avoid overwriting unrelated user files without a backup or confirmation
- print a clear summary of installed assets
- provide restart/reload guidance for Codex

The installer should support a dry run:

```bash
./scripts/install.sh --dry-run
```

The installer should support local development symlinks:

```bash
./scripts/install.sh --link
```

The installer should support copied installation:

```bash
./scripts/install.sh --copy
```

The installer should support MCP registration:

```bash
./scripts/install.sh --with-mcp
```

The installer should support skipping MCP registration:

```bash
./scripts/install.sh --without-mcp
```

For v1, `--without-mcp` should be the safer default unless the user explicitly approves config changes to `~/.codex/config.toml`.

Secrets and MCP merge requirements are defined in [powers.md](powers.md).

## 7. Uninstaller Requirements

The project should provide an uninstaller:

```bash
./scripts/uninstall.sh
```

Uninstaller responsibilities:

- remove all local Codex and agent-system updates produced by this project
- remove only files installed or modified by this project
- refuse to delete unrelated user files
- read the install manifest before making changes
- support dry-run mode
- remove managed symlinks safely
- restore backed-up files when this project modified an existing file
- remove project-managed MCP blocks from `~/.codex/config.toml` when they were installed
- remove empty project-owned state directories when safe
- print a clear summary

Initial command:

```bash
./scripts/uninstall.sh
```

Dry run:

```bash
./scripts/uninstall.sh --dry-run
```

### 7.1 Install Manifest

The installer must write a manifest under the Codex user state directory:

```text
${CODEX_HOME:-$HOME/.codex}/sdd-ai-agents/install-manifest.tsv
```

The manifest is the authoritative list of local updates produced by this project.

Each manifest row should include:

- entry kind, such as `file`, `directory`, `symlink`, `config-edit`, or `backup`
- installed path
- source path when applicable
- install mode, such as `link` or `copy`
- backup path when applicable
- checksum when applicable

The uninstaller must use the manifest first. If no manifest exists, it may only remove conservative fallback paths that are clearly owned by this project, such as:

- symlinks whose targets are inside this repository
- copied files containing a `Managed by sdd-ai-agents` marker
- empty project-owned directories such as `${CODEX_HOME:-$HOME/.codex}/sdd-ai-agents`

### 7.2 Local Paths That May Be Managed

The uninstaller may manage only paths explicitly installed by this project:

```text
~/.codex/agents/sdd-*.toml
~/.agents/skills/sdd-*/
~/.codex/plugins/sdd-ai-agents/
~/.agents/plugins/marketplace.json
~/.codex/config.toml
${CODEX_HOME:-$HOME/.codex}/sdd-ai-agents/
```

For shared files such as `~/.codex/config.toml` or `~/.agents/plugins/marketplace.json`, the installer must either:

- avoid modifying them, or
- create a backup and record the exact change in the manifest.

The uninstaller must not delete shared files outright unless the manifest proves the entire file was created by this project.

When uninstalling MCP configuration, the uninstaller must remove only project-managed `[mcp_servers.sdd_*]` blocks recorded in the manifest. It must preserve unrelated MCP servers and all unrelated Codex settings.

## 8. Doctor Requirements

The project should provide a diagnostic script:

```bash
./scripts/doctor.sh
```

Doctor responsibilities:

- verify expected directories exist
- verify agent files are installed
- verify skill files are installed
- verify power folders are installed when applicable
- verify secrets placeholders exist
- verify MCP config blocks exist when MCP install was requested
- verify the install manifest exists when the project is installed
- detect broken symlinks
- detect conflicting names
- detect partial uninstall state
- print actionable repair steps

## 9. Repository Layout

Target v1 repository layout:

```text
sdd-ai-agents/
  README.md
  docs/
    requirements.md
    workflow.md
    artifact-ownership.md
    install.md
    reviews/
      <initiative>/
        requirements-review.md
        design-review.md
        task-review.md
        code-review.md
        test-review.md
  agents/
    product-agent.toml
    requirements-reviewer.toml
    architect-agent.toml
    design-reviewer.toml
    planner-agent.toml
    task-reviewer.toml
    developer-agent.toml
    code-reviewer.toml
    tester-agent.toml
    test-reviewer.toml
    documentation-release-agent.toml
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
  templates/
    requirements.md
    design.md
    tasks.md
    validation-report.md
    release-notes.md
    review-result.md
  powers/
    README.md
    jira/
      POWER.md
      mcp.toml
      secrets.template
    github/
      POWER.md
      mcp.toml
      secrets.template
  scripts/
    install.sh
    uninstall.sh
    doctor.sh
  .codex-plugin/
    plugin.json
```

## 10. Configuration Strategy

V1 should prefer file installation and symlinks over invasive edits to `~/.codex/config.toml`.

If config changes are needed, the installer should:

- show the exact change
- make a backup before editing
- avoid duplicating existing entries
- support dry-run output

Custom agents should be installed as standalone TOML files under `~/.codex/agents`.

Agent files should include:

- `name`
- `description`
- `developer_instructions`
- `sandbox_mode`
- `approval_policy`
- optional `model_reasoning_effort`

Agent instructions should list:

- referenced SDD skills
- allowed powers
- forbidden powers
- allowed artifact writes
- forbidden artifact writes
- review persistence rules when the agent is a reviewer

Skills should be installed under `~/.agents/skills`; details are defined in [skills.md](skills.md).

Power folders should be installed under the project Codex state directory; details are defined in [powers.md](powers.md).

## 11. Workflow Status Values

Review results must end with one status:

- `APPROVED`
- `CHANGES_REQUESTED`
- `BLOCKED`

`APPROVED` means the artifact can be used as input by the next creator agent.

`CHANGES_REQUESTED` means the creator must revise the artifact.

`BLOCKED` means the reviewer cannot make a decision because required information is missing or contradictory.

The status may be displayed only in terminal/chat. A persisted markdown review file is optional and requires explicit user request.

## 12. Traceability Requirements

Every downstream artifact should reference upstream artifacts.

Minimum traceability:

- requirements reference original prompt or project goal
- design references requirement IDs
- tasks reference requirement IDs and design sections
- implementation notes reference task IDs
- code review references requirement IDs, design sections, and task IDs
- validation report references acceptance criteria
- release notes reference approved implementation scope
- persisted review records reference the reviewed artifact/change and the destination requested by the user

## 13. V1 Acceptance Criteria

The first complete version is acceptable when:

- all v1 agent TOML files exist
- all v1 skill directories contain valid `SKILL.md` files
- artifact templates exist
- installer supports dry-run and symlink install
- installer writes a manifest of all local Codex changes
- installer creates a project-owned secrets file from power templates
- installer can optionally merge project-owned MCP TOML fragments into Codex config
- uninstaller removes all manifest-tracked project updates
- uninstaller refuses to remove unrelated local Codex files
- doctor detects missing agents, skills, powers, secrets placeholders, MCP blocks, or broken installs
- README explains install and usage
- the agents can be used manually in a Codex session

## 14. Non-Goals for V1

V1 does not need to:

- run a hosted service
- implement a UI
- enforce every agent usage rule mechanically
- integrate with CI
- publish to a public plugin marketplace
- support non-WSL platforms
- automatically orchestrate all agents without user prompts

## 15. Future Enhancements

Potential later work:

- repo bootstrap command for adding `.sdd/` artifact folders to any project
- CI checks for optional persisted artifacts
- hooks that prevent reviewer agents from editing reviewed artifacts unless explicitly requested
- MCP server for artifact state and agent-support metadata
- plugin marketplace distribution
- organization/team installation mode
- docs reviewer role
- automated traceability graph generation
- command shortcuts for each SDD stage
