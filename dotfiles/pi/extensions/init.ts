/**
 * /init — Analyze project and generate/update AGENTS.md
 *
 * Sends a detailed analysis prompt to the agent, which uses its tools
 * to explore the codebase and fill in every section of AGENTS.md.
 *
 * Usage:
 *   /init            — create or update AGENTS.md
 *   /init --force    — regenerate from scratch, discarding existing content
 */

import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";

const AGENTS_TEMPLATE = `# Project Agent

**Workspace Path:** \`{cwd}\`
*(Note to Pi: Your file write/edit tools run in a different directory by default. You MUST use absolute paths starting with the Workspace Path above for ALL file operations!)*

<!-- Pi: before writing anything, explore this project:
  1. Read package.json / pyproject.toml / Cargo.toml / go.mod — identify stack and versions
  2. Scan directory structure: rg --files | head -60
  3. Read 3-5 key source files to understand patterns and conventions
  4. Check for .cursorrules, CLAUDE.md, .eslintrc, prettier.config — existing AI/style config
  Then fill in each section below based on what you actually find.
  Adapt or add sections if the project has unique needs.
-->

**Generated:** {date}

## Stack
<!-- Pi: languages, frameworks, key libraries and their versions -->

## Structure
<!-- Pi: key directories and what each contains — a mental map, not a full file list -->

## Commands
| Action  | Command |
|---------|---------|
| Install |         |
| Build   |         |
| Test    |         |
| Run     |         |

## Conventions
<!-- Pi: coding style, patterns in use, formatter/linter config, naming conventions -->

## Key Files
<!-- Pi: the 5-10 most important files and what each one does -->

## What to Avoid
<!-- Pi: patterns or changes that would break things or go against project style -->

## Notes
<!-- Pi: existing AI config files (.cursorrules, CLAUDE.md), gotchas, constraints, anything a new agent must know -->
`;

function buildPrompt(cwd: string, force: boolean): string {
  const today = new Date().toISOString().slice(0, 10);

  if (force) {
    return `Generate a fresh AGENTS.md for this project at ${cwd}/AGENTS.md.

Overwrite any existing AGENTS.md completely. Follow these steps:

1. **Identify the stack** — read package.json, pyproject.toml, Cargo.toml, go.mod, or similar manifest files. Note all languages, frameworks, and key libraries with their versions.

2. **Map the structure** — list the key directories and explain what each contains. This is a mental map, not a full file listing. Focus on the top-level and important subdirectories.

3. **Discover commands** — from package.json scripts, Makefile, Justfile, or similar, extract install, build, test, and run commands. Format them as a Markdown table.

4. **Infer conventions** — read 3-5 key source files. Note coding style, naming patterns, formatter/linter config (.eslintrc, .prettierrc, .editorconfig, etc.).

5. **Identify key files** — list the 5-10 most important files and describe what each does.

6. **Note what to avoid** — based on the project structure and patterns, identify changes that would break things or go against project style.

7. **Document notes** — check for existing AI config files (.cursorrules, CLAUDE.md, .windsurfrules), gotchas, constraints, package manager quirks, monorepo considerations, etc.

Fill in the template below and write it to ${cwd}/AGENTS.md. Replace {cwd} with the actual workspace path and {date} with ${today}.

Do NOT skip any section. If you cannot determine something, write "N/A — could not determine" rather than leaving it blank.

\`\`\`markdown
${AGENTS_TEMPLATE}
\`\`\``;
  }

  return `Update the AGENTS.md file at ${cwd}/AGENTS.md based on a fresh analysis of this project.

**First**, read the existing AGENTS.md to understand what's already documented.

**Then**, analyze the current state of the project and update each section:

1. **Stack** — verify languages, frameworks, and versions. Update if dependencies changed. Read manifest files (package.json, pyproject.toml, Cargo.toml, go.mod, flake.nix, etc.).

2. **Structure** — verify key directories still match reality. Add any new important directories, remove obsolete ones.

3. **Commands** — verify install/build/test/run commands still work. Update if scripts changed.

4. **Conventions** — read a few recent source files. Check for new linter/formatter config files. Update if patterns evolved.

5. **Key Files** — verify the listed files are still the most important. Rotate in new critical files, remove less relevant ones.

6. **What to Avoid** — update if new anti-patterns emerged or old ones are no longer relevant.

7. **Notes** — check for new AI config files, gotchas, or constraints. Update the date to ${today}.

Do NOT skip any section. If existing content is still accurate, keep it. If something is outdated or missing, update it. Write the result to ${cwd}/AGENTS.md.`;
}

export default function initExtension(pi: ExtensionAPI) {
  pi.registerCommand("init", {
    description: "Analyze project and generate/update AGENTS.md",
    getArgumentCompletions: (prefix: string) => {
      const options = ["--force"];
      const filtered = options.filter((o) => o.startsWith(prefix));
      return filtered.length > 0 ? filtered.map((v) => ({ value: v, label: v })) : null;
    },
    handler: async (args: string, ctx) => {
      if (!ctx.isIdle()) {
        ctx.ui.notify("Agent is busy. Wait for the current task to finish, then run /init.", "warning");
        return;
      }

      const trimmed = args.trim();
      const force = trimmed === "--force";

      if (trimmed && !force) {
        ctx.ui.notify(
          `Unknown argument: "${trimmed}". Use /init (analyze & update) or /init --force (regenerate from scratch).`,
          "warning",
        );
        return;
      }

      const prompt = buildPrompt(ctx.cwd, force);

      ctx.ui.notify(
        force ? "Regenerating AGENTS.md from scratch..." : "Analyzing project and updating AGENTS.md...",
        "info",
      );

      pi.sendUserMessage(prompt);
    },
  });
}
