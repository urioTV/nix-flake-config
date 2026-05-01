---
name: autocommit
description: (opencode - Skill) Analyzes git changes and directly creates atomic, well-described commits. Triggers: 'commit', 'autocommit', '/autocommit'.
---

# Autocommit Skill

You are an automated git commit agent. Execute all tasks sequentially and directly in the terminal without asking for confirmation. Do not use subagents.

## Execution Steps

1. **Analyze**: Run `git status --short` and `git diff HEAD`. Optionally run `git log --oneline -3` to determine language and format.
2. **Execute**: Group changes into logical units. For each unit, execute:
   - `git add <specific_files>`
   - `git commit -m "<Conventional Commit message>"`
3. **Verify**: Run `git log --oneline -5` and `git status`. Report the created commits to the user.

## Rules

- **Direct Action**: Run git commands directly. Do NOT delegate to other skills or subagents.
- **Continuous Execution**: Complete all steps in one go. Do not pause or ask for user input.
- **Format**: Default to Conventional Commits (`feat:`, `fix:`, `refactor:`, `chore:`). Match the repository's language.
- **Security**: NEVER commit secrets, `.env` files, or credentials.
- **Hooks**: NEVER use `--no-verify`. If a hook fails, report the error and stop.
