# AGENTS.md - Coding Agent Guidelines

## Build/Lint/Test Commands

- `just test` - Run `nix flake check` to verify all configurations
- `just fmt` - Format code with nixfmt-rfc-style
- `just build <host>` - Build a specific host configuration
- `just switch <host>` - Switch to a host configuration
- `just dev` - Enter development shell with all tools

## Code Style

- **Formatter**: nixfmt-rfc-style (2-space indent, braces on same line)
- **Module pattern**: `{ inputs, den, pkgs, FTS, __findFile, ... }:` for imports
- **Aspect syntax**: Use `<FTS/category/subcategory>` angle brackets for aspect
  references
- **Parametric aspects**: `(FTS.module { option = "value"; })` or
  `(<FTS/path> { opt = val; })`

## Naming Conventions

- Hosts: `hosts/<hostname>/<hostname>.nix`
- Users: `users/<username>/<username>.nix`
- Modules: `modules/<category>/<subcategory>/<module>.nix`
- Facets (routers): `modules/<category>/<category>.nix`

## Secrets (SOPS)

- Host secrets: `hosts/<hostname>/secrets.yaml`, User secrets:
  `users/<username>/secrets.yaml`
- Edit with `just edit-secrets <name>`, never commit `sops.key` or `keys.txt`

## btca

When the user says "use btca", use btca before you answer the question. It will
give you up to date information about the technology. Run:

- btca ask -t <tech> -q "<question>"

Available <tech>:

- `deploy-rs` - NixOS deployment tool
- `flake-aspects` - How aspects are structured
- `import-tree` - How files are imported
- `flake-file` - How the flake file is generated
- `den` - How hosts are defined
- `selfhostblocks` - All selfhosting related services
- `skarabox` - Example system deployment for secrets management and deployments

<!-- BEGIN BEADS INTEGRATION v:1 profile:full hash:d4f96305 -->
## Issue Tracking with bd (beads)

**IMPORTANT**: This project uses **bd (beads)** for ALL issue tracking. Do NOT use markdown TODOs, task lists, or other tracking methods.

### Why bd?

- Dependency-aware: Track blockers and relationships between issues
- Git-friendly: Dolt-powered version control with native sync
- Agent-optimized: JSON output, ready work detection, discovered-from links
- Prevents duplicate tracking systems and confusion

### Quick Start

**Check for ready work:**

```bash
bd ready --json
```

**Create new issues:**

```bash
bd create "Issue title" --description="Detailed context" -t bug|feature|task -p 0-4 --json
bd create "Issue title" --description="What this issue is about" -p 1 --deps discovered-from:bd-123 --json
```

**Claim and update:**

```bash
bd update <id> --claim --json
bd update bd-42 --priority 1 --json
```

**Complete work:**

```bash
bd close bd-42 --reason "Completed" --json
```

### Issue Types

- `bug` - Something broken
- `feature` - New functionality
- `task` - Work item (tests, docs, refactoring)
- `epic` - Large feature with subtasks
- `chore` - Maintenance (dependencies, tooling)

### Priorities

- `0` - Critical (security, data loss, broken builds)
- `1` - High (major features, important bugs)
- `2` - Medium (default, nice-to-have)
- `3` - Low (polish, optimization)
- `4` - Backlog (future ideas)

### Workflow for AI Agents

1. **Check ready work**: `bd ready` shows unblocked issues
2. **Claim your task atomically**: `bd update <id> --claim`
3. **Work on it**: Implement, test, document
4. **Discover new work?** Create linked issue:
   - `bd create "Found bug" --description="Details about what was found" -p 1 --deps discovered-from:<parent-id>`
5. **Complete**: `bd close <id> --reason "Done"`

### Auto-Sync

bd automatically syncs via Dolt:

- Each write auto-commits to Dolt history
- Use `bd dolt push`/`bd dolt pull` for remote sync
- No manual export/import needed!

### Important Rules

- ✅ Use bd for ALL task tracking
- ✅ Always use `--json` flag for programmatic use
- ✅ Link discovered work with `discovered-from` dependencies
- ✅ Check `bd ready` before asking "what should I work on?"
- ❌ Do NOT create markdown TODO lists
- ❌ Do NOT use external issue trackers
- ❌ Do NOT duplicate tracking systems

For more details, see README.md and docs/QUICKSTART.md.

## Landing the Plane (Session Completion)

**When ending a work session**, you MUST complete ALL steps below. Work is NOT complete until `git push` succeeds.

**MANDATORY WORKFLOW:**

1. **File issues for remaining work** - Create issues for anything that needs follow-up
2. **Run quality gates** (if code changed) - Tests, linters, builds
3. **Update issue status** - Close finished work, update in-progress items
4. **PUSH TO REMOTE** - This is MANDATORY:
   ```bash
   git pull --rebase
   bd dolt push
   git push
   git status  # MUST show "up to date with origin"
   ```
5. **Clean up** - Clear stashes, prune remote branches
6. **Verify** - All changes committed AND pushed
7. **Hand off** - Provide context for next session

**CRITICAL RULES:**
- Work is NOT complete until `git push` succeeds
- NEVER stop before pushing - that leaves work stranded locally
- NEVER say "ready to push when you are" - YOU must push
- If push fails, resolve and retry until it succeeds

<!-- END BEADS INTEGRATION -->
