---
name: autocommit
description: (opencode - Skill) MUST USE for committing current changes. Analyzes git diff with subagents and creates atomic, well-described commits automatically. Triggers: 'commit', 'autocommit', '/autocommit'.
---
# Autocommit Skill

You are orchestrating an automated git commit workflow. Your job is to analyze current repository changes and produce atomic, meaningful commits — with zero manual input required.

**CRITICAL: You MUST complete ALL phases without stopping. Do NOT pause, ask for confirmation, or wait for user input at any point. Do NOT stop mid-task. Run every phase to completion, even if it takes multiple tool calls. The task is finished only when Phase 4 verification is done and you have reported the final commit list to the user.**

**MANDATORY FIRST STEP: Before doing anything else, create a todo list** with all planned phases (Phase 0 through Phase 4). Mark each phase `in_progress` as you start it and `completed` immediately when done. This ensures you never lose track of remaining work mid-task.

## Phase 0 — Parallel Reconnaissance

Fire ALL of the following **simultaneously** (parallel tool calls, no waiting):

1. `git status --short` — staged vs unstaged overview
2. `git diff --stat HEAD` — which files changed and by how much
3. `git diff HEAD` — full diff (what actually changed)
4. `git log --oneline -10` — last 10 commits (style reference)
5. `git diff --cached --stat` — staged-only changes (if any)

After collecting all results, proceed to Phase 1.

## Phase 1 — Commit Style Detection

Analyze `git log --oneline -10` output and detect:

- **Format**: Conventional Commits (`feat:`, `fix:`, `refactor:`, `chore:`) vs plain sentence vs short imperative
- **Language**: Polish vs English
- **Length**: short (≤50 chars subject) vs descriptive

You MUST match the detected style exactly in all commits you create.
If no history exists → default to **Conventional Commits in English**.

## Phase 2 — Atomic Commit Planning

Group changes into atomic commits using these rules:

- **One logical change = one commit** (never bundle unrelated changes)
- Different directories with different concerns → different commits
- Tests always go with the implementation they test
- Config changes can be standalone if substantive
- Refactors separate from feature additions
- Minimum: if ≥3 files changed in unrelated areas → plan ≥2 commits

**Output a numbered plan** before executing, e.g.:
```
Plan:
1. feat: add opencode autocommit skill [opencode.nix, autocommit.md]
2. chore: update flake inputs
```

## Phase 3 — Delegate to git-master

For each planned commit, invoke the **git-master skill** as a subagent:

```
task(
  category="quick",
  load_skills=["git-master"],
  run_in_background=false,
  description="Atomic commit: <commit subject>",
  prompt="""
  TASK: Create exactly ONE atomic git commit for the following files: <file list>
  COMMIT MESSAGE: <detected-style message>
  MUST DO:
    - Stage ONLY the specified files (git add <files>)
    - Use exactly the commit message provided
    - Verify with git status that only intended files are staged
    - Run git commit
  MUST NOT DO:
    - Stage unrelated files
    - Change the commit message
    - Create multiple commits
  CONTEXT: Working dir is the current repo root.
  """
)
```

Execute commits **sequentially** (not parallel) to avoid staging conflicts.

## Phase 4 — Verification

After all commits:

1. Run `git log --oneline -5` — confirm commits appear
2. Run `git status` — confirm working tree is clean (or note any intentionally unstaged files)
3. Report to user: list of commits created with their SHAs

## Rules

- **NEVER** commit secrets, `.env` files, or credentials
- **NEVER** use `--no-verify` or skip hooks
- **NEVER** amend commits that were already pushed
- If `git status` shows nothing to commit → report and stop
- If pre-commit hook fails → report the error, do NOT retry blindly
- Untracked files: stage them only if they are clearly part of the change (e.g., new module file that's imported)
