// CodeGraph native extension for Pi — full tool surface, no MCP.
//
// Exposes the whole CodeGraph CLI as native Pi tools so the agent never has to
// shell out to `codegraph` via bash: it gets one structured tool per command,
// each returning the same markdown/JSON the CLI prints. One version-controlled
// .ts file also does the two always-on things `codegraph install --target claude`
// does for Claude Code:
//
//   - Hooks `before_agent_start` (Pi's UserPromptSubmit equivalent) to run
//     `codegraph prompt-hook` and inject the returned structural context for
//     structural prompts — the always-on nudge.
//   - Appends CodeGraph instructions to the system prompt for indexed projects,
//     so the agent reaches for codegraph before grep/Read. Baked into the
//     extension (version-controlled), not APPEND_SYSTEM.md (vstack-managed,
//     gitignored).
//
// Read-only tools are gated on a `.codegraph/` index being reachable from cwd.
// Unindexed code projects get only a lightweight offer to initialize; init is
// guarded by an explicit `confirmed=true` parameter. All failures are swallowed
// — a broken/uninstalled codegraph must never break the agent loop.
//
// `CODEGRAPH_BIN` (absolute path to the CLI) is set by Nix in
// modules/ai/pi/_pi.nix; falls back to PATH lookup.

import { spawn } from "node:child_process";
import { existsSync, readdirSync } from "node:fs";
import { dirname, join, resolve } from "node:path";
import { Type } from "typebox";
import { keyHint, type ExtensionAPI, type Theme } from "@earendil-works/pi-coding-agent";
import { Text } from "@earendil-works/pi-tui";

const HOOK_TIMEOUT_MS = 10_000;
const TOOL_TIMEOUT_MS = 30_000;

/** Walk up to the nearest valid index, never treating HOME or `/` as a project root. */
function findCodegraphRoot(start: string): string | undefined {
  const home = process.env.HOME ? resolve(process.env.HOME) : undefined;
  let dir = resolve(start);
  while (true) {
    // CodeGraph stores telemetry in ~/.codegraph even when HOME was never
    // indexed. Stop before HOME/root so projects cannot inherit that directory.
    if (dir === home || dir === dirname(dir)) return undefined;
    if (existsSync(join(dir, ".codegraph", "codegraph.db"))) return dir;
    dir = dirname(dir);
  }
}

function codegraphBin(): string {
  return process.env.CODEGRAPH_BIN || "codegraph";
}

/** Keep the graph fresh without a long-running MCP watcher. */
async function syncCodegraph(root: string): Promise<void> {
  await runCodegraph(["sync", "--quiet", root], {
    cwd: root,
    timeoutMs: TOOL_TIMEOUT_MS,
  });
}

/** Spawn `codegraph <args>` with optional stdin, resolve stdout string. Reject on non-zero exit / timeout. */
function runCodegraph(
  args: string[],
  opts: { cwd: string; stdin?: string; timeoutMs?: number },
): Promise<string> {
  return new Promise((resolve, reject) => {
    const child = spawn(codegraphBin(), args, {
      cwd: opts.cwd,
      stdio: ["pipe", "pipe", "pipe"],
      env: process.env,
    });
    const stdoutChunks: Buffer[] = [];
    const stderrChunks: Buffer[] = [];
    let settled = false;
    const done = (err: Error | null, out: string) => {
      if (settled) return;
      settled = true;
      err ? reject(err) : resolve(out);
    };
    child.stdout.on("data", (d) => stdoutChunks.push(d));
    child.stderr.on("data", (d) => stderrChunks.push(d));
    child.on("error", (e) => done(e, ""));
    child.on("close", (code) => {
      if (code !== 0) {
        done(new Error(`codegraph ${args.join(" ")} exited ${code}: ${Buffer.concat(stderrChunks).toString().trim()}`), "");
      } else {
        done(null, Buffer.concat(stdoutChunks).toString());
      }
    });
    const timer = setTimeout(() => {
      child.kill("SIGTERM");
      done(new Error(`codegraph ${args.join(" ")} timed out`), "");
    }, opts.timeoutMs ?? TOOL_TIMEOUT_MS);
    child.on("close", () => clearTimeout(timer));
    child.stdin.end(opts.stdin ?? "");
  });
}

type ToolParams = Record<string, unknown>;

function toolResultText(content: readonly unknown[]): string {
  return content
    .flatMap((block) => {
      if (!block || typeof block !== "object") return [];
      const value = block as { type?: unknown; text?: unknown };
      return value.type === "text" && typeof value.text === "string" ? [value.text] : [];
    })
    .join("\n")
    .trim();
}

/** Compact by default; preserve the complete model-facing result when expanded. */
function renderCodegraphResult(
  content: readonly unknown[],
  expanded: boolean,
  isPartial: boolean,
  theme: Theme,
  isError = false,
): Text {
  if (isPartial) return new Text(theme.fg("warning", "Updating CodeGraph…"), 0, 0);

  const output = toolResultText(content);
  if (expanded) {
    return new Text(output || theme.fg("dim", "CodeGraph returned no output."), 0, 0);
  }

  const lines = output.split("\n").filter((line) => line.trim());
  const first = (lines[0] || "CodeGraph returned no output")
    .replace(/^\s*[#>*+\-]+\s*/, "")
    .replace(/\s+/g, " ")
    .trim();
  const summary = first.length > 120 ? `${first.slice(0, 117)}…` : first;
  const failed = isError || /\b(failed|refused|error)\b/i.test(first);
  let text = theme.fg(failed ? "error" : "success", failed ? "✗ " : "✓ ");
  text += theme.fg("muted", summary);
  if (lines.length > 1) text += theme.fg("dim", ` · ${lines.length} lines`);
  text += ` ${keyHint("app.tools.expand", "to expand")}`;
  return new Text(text, 0, 0);
}

/** Build args for a command from a param map: only non-undefined values. */
function buildArgs(
  cmd: string,
  p: ToolParams,
  root: string,
  positional: string[],
  opts: Record<string, "string" | "number" | "flag">,
  pathMode: "option" | "positional" = "option",
): string[] {
  const args = pathMode === "option" ? [cmd, "--path", root] : [cmd];
  for (const [key, kind] of Object.entries(opts)) {
    const val = p[key];
    if (val === undefined || val === null) continue;
    // CLI flags use hyphens; param keys may use underscores (e.g. max_files).
    const flag = key.replace(/_/g, "-");
    if (kind === "flag") {
      if (val) args.push(`--${flag}`);
    } else {
      args.push(`--${flag}`, String(val));
    }
  }
  for (const pos of positional) args.push(pos);
  if (pathMode === "positional") args.push(root);
  return args;
}

/** Register one codegraph tool that wraps a `codegraph <cmd>` subcommand. */
function registerCodegraphTool(
  pi: ExtensionAPI,
  spec: {
    name: string;
    label: string;
    description: string;
    parameters: import("typebox").TObject;
    /** Positional CLI args built from params (in order). */
    positional?: (p: ToolParams) => string[];
    /** Option flags from params. */
    options?: Record<string, "string" | "number" | "flag">;
    /** Most commands use --path; `status` takes the project path positionally. */
    pathMode?: "option" | "positional";
  },
) {
  pi.registerTool({
    name: spec.name,
    label: spec.label,
    description: spec.description,
    parameters: spec.parameters,
    async execute(_toolCallId, params, _signal, _onUpdate, _ctx) {
      const cwd = process.cwd();
      const root = findCodegraphRoot(cwd);
      if (!root) {
        return {
          content: [
            {
              type: "text" as const,
              text: "CodeGraph: this project isn't indexed (no `.codegraph/` found from cwd upward). Skip codegraph for this project; use grep/read instead. The user can run `codegraph init .` to index it — don't do that yourself.",
            },
          ],
          details: {},
        };
      }
      try {
        // No MCP server means no long-running watcher. Incremental sync is
        // cheap (~hundreds of ms) and guarantees every native tool sees the
        // current graph after edits.
        await syncCodegraph(root);
        const effectiveParams: ToolParams = { ...(params as ToolParams) };
        // CodeGraph defaults to only six files. That is useful for focused
        // questions but too shallow for a repository-wide duplication audit.
        if (
          spec.name === "codegraph_explore" &&
          effectiveParams.max_files === undefined &&
          isRepositoryAuditPrompt(String(effectiveParams.query ?? ""))
        ) {
          effectiveParams.max_files = 40;
        }
        // A focused node should not silently dump a multi-thousand-line file.
        // The model can page deliberately when it genuinely needs more.
        if (
          spec.name === "codegraph_node" &&
          effectiveParams.file !== undefined &&
          effectiveParams.limit === undefined &&
          !effectiveParams.symbols_only
        ) {
          effectiveParams.limit = 300;
        }
        const positional = spec.positional ? spec.positional(effectiveParams) : [];
        const args = buildArgs(
          spec.name.replace(/^codegraph_/, ""),
          effectiveParams,
          root,
          positional,
          spec.options ?? {},
          spec.pathMode,
        );
        const out = await runCodegraph(args, { cwd: root, timeoutMs: TOOL_TIMEOUT_MS });
        return {
          content: [{ type: "text" as const, text: out.trim() || `CodeGraph: no results from \`${spec.name}\`.` }],
          details: { root },
        };
      } catch (e) {
        return {
          content: [{ type: "text" as const, text: `CodeGraph \`${spec.name}\` failed: ${(e as Error).message}` }],
          details: {},
        };
      }
    },
    renderResult(result, { expanded, isPartial }, theme, context) {
      return renderCodegraphResult(result.content, expanded, isPartial, theme, context.isError);
    },
  });
}

/** Instructions appended to the system prompt for indexed projects. */
const CODEGRAPH_INSTRUCTIONS = `
## CodeGraph

This project is indexed by CodeGraph (a \`.codegraph/\` directory exists at the repo root). Reach for these tools BEFORE grep/find or reading files when you need to understand or locate code. Each tool automatically incrementally syncs the index first, so results stay fresh without an MCP watcher. Each operation is one structured call — do not shell out to \`codegraph\` via bash; use the tool instead.

- \`codegraph_explore\` — PRIMARY tool. Answers most code questions in one call: the relevant symbols' verbatim, line-numbered source grouped by file, plus the call paths between them (including dynamic-dispatch hops grep can't follow) and a blast-radius summary. Best for "how does X work", a flow ("how does X reach Y"), surveying an area, and repository-wide audits for duplicated/repeated or dead code. For an audit, pass the user's full question and use further targeted explores for candidates it surfaces. Name a file or symbol in the query to read its current source. Treat returned source as already Read.
- \`codegraph_node\` — One symbol's source + caller/callee trail. Or read one focused file with line numbers + dependents (set \`file\`; large files default to 300 lines and can be paged). Do not call it repeatedly to enumerate the repo.
- \`codegraph_nodes\` — Bounded exact-file batch: 2–4 already-selected files, up to 200 lines each, one sync and one round-trip. Batching reduces latency, not context size; use it only after explore/query identifies exact candidates.
- \`codegraph_query\` — FTS search for symbols by name (and optional \`kind\` filter). Use when you know a name but not where it lives.
- \`codegraph_callers\` — Everyone who calls a symbol (impact inbound). Run before editing to see who depends on it.
- \`codegraph_callees\` — Everything a symbol calls (impact outbound). Use to trace a function's downstream behavior.
- \`codegraph_impact\` — Full transitive blast radius of changing a symbol, up to \`depth\` hops. Use before a non-trivial edit.
- \`codegraph_files\` — Project file structure from the index (tree/flat/grouped), optionally filtered by dir or glob. Use instead of \`find\`/\`ls\` for an indexed repo.
- \`codegraph_status\` — Index stats (files, nodes, edges, freshness). Use to check the index before relying on it.

Treat source returned by CodeGraph as already Read. Prefer \`codegraph_explore\` for discovery and relationships, \`codegraph_nodes\` for a small exact set of files, and raw Read only for exact last-mile details, unsupported material, or when graph retrieval is insufficient. \`codegraph_files\` is orientation, not analysis. These are strong preferences—not hard restrictions; use the tool that best preserves correctness.
`.trim();

const CODEGRAPH_AUDIT_GUIDANCE = `
## CodeGraph guidance for this repository audit

Start with one broad \`codegraph_explore\` using the user's complete audit question (audit queries automatically get a larger file budget). Do not turn \`codegraph_node\` into a file-by-file repository crawler. If the first exploration identifies 2–4 exact candidate files that need full comparison, fetch them together with one bounded \`codegraph_nodes\` call. Use individual node calls only for a genuinely focused symbol/file, and synthesize once there is enough evidence. Raw Read/search remains available for concrete gaps or unsupported files.
`.trim();

/** Does this prompt request a repository-wide audit needing broader explore context? */
function isRepositoryAuditPrompt(prompt: string): boolean {
  return /(dubl|duplik|powtarz|powtórzon|repeated\s+code|code\s+repetition|duplicat|copy.?paste|dead\s+code|unused\s+code|martw\w*\s+kod|nieużywan\w*\s+kod|repo(?:sitory)?[- ]wide\s+audit|audyt\w*\s+repo)/i.test(prompt);
}

/** Nudge appended to the system prompt when a real code project has no index yet. */
const CODEGRAPH_OFFER = `
## CodeGraph (not indexed)

This project is not indexed by CodeGraph. CodeGraph builds a local SQLite knowledge graph of every symbol, call edge, and file in the repo — querying it through the \`codegraph_*\` tools is cheaper than re-deriving structure with grep/Read, and its watcher keeps the index fresh.

If this project has meaningful source code in a supported language (Python, TypeScript/JavaScript, Go, Rust, Java, C/C++, C#, Ruby, PHP, Swift, Kotlin, Scala, Nix, and more), propose initialization to the user: "Want me to index this project with CodeGraph so I can answer code questions faster?" The \`codegraph_init\` tool creates a \`.codegraph/\` directory and builds the initial index; after explicit confirmation call it with \`confirmed=true\`. Skip the offer for tiny/throwaway folders, config-only directories, and docs-only repositories.
`.trim();

/** Cheap heuristic: is this cwd a real code project worth offering to index? */
function looksLikeCodeProject(cwd: string): boolean {
  if (cwd === process.env.HOME || cwd === "/" || cwd === dirname(cwd)) return false;
  try {
    const entries = readdirSync(cwd, { withFileTypes: true });
    const markers = [
      ".git",
      "go.mod",
      "package.json",
      "pyproject.toml",
      "Cargo.toml",
      "setup.py",
      "pom.xml",
      "flake.nix",
    ];
    if (markers.some((marker) => existsSync(join(cwd, marker)))) return true;

    // Without a project marker, require several source files to avoid nagging
    // in one-off scratch directories.
    const codeExt = /^\.(py|ts|tsx|js|jsx|mjs|mts|go|rs|java|c|cc|cpp|cxx|h|hpp|cs|rb|php|swift|kt|kts|scala|dart|lua|ex|exs|jl|v|sv|sh|bash|zig|nix|f|f90|pas|pp|groovy|gradle|vue|svelte|astro)$/;
    const sourceCount = entries.filter((entry) => {
      if (!entry.isFile()) return false;
      const ext = entry.name.match(/\.[a-z0-9]+$/i)?.[0];
      return ext ? codeExt.test(ext) : false;
    }).length;
    return sourceCount >= 3;
  } catch {
    return false;
  }
}

type InitResult = {
  ok: boolean;
  text: string;
  details: Record<string, string>;
};

/** Shared implementation for the native tool and `/codegraph-init` command. */
async function initializeCodegraph(path: string | undefined, force = false): Promise<InitResult> {
  const target = resolve(process.cwd(), path || ".");
  if (!existsSync(target)) {
    return {
      ok: false,
      text: `CodeGraph init failed: project path does not exist: ${target}`,
      details: { target },
    };
  }

  // Check protected roots before looking for an existing index. A stale or
  // telemetry-only ~/.codegraph must never turn an unsafe init into success.
  const home = process.env.HOME ? resolve(process.env.HOME) : undefined;
  const looksDangerous = target === home || target === "/" || target === dirname(target);
  if (looksDangerous && !force) {
    return {
      ok: false,
      text: `CodeGraph init refused: ${target} looks like a home or filesystem root.`,
      details: { target },
    };
  }

  const existingRoot = findCodegraphRoot(target);
  if (existingRoot) {
    return {
      ok: true,
      text: `CodeGraph is already initialized at ${existingRoot}. Use codegraph_status or codegraph_explore instead.`,
      details: { root: existingRoot },
    };
  }

  try {
    const args = ["init", target];
    if (force) args.push("--force");
    const out = await runCodegraph(args, { cwd: target, timeoutMs: 120_000 });
    return {
      ok: true,
      text: out.trim() || `CodeGraph initialized at ${target}.`,
      details: { target },
    };
  } catch (e) {
    return {
      ok: false,
      text: `CodeGraph init failed: ${(e as Error).message}`,
      details: { target },
    };
  }
}

export default function codegraphExtension(pi: ExtensionAPI) {
  // 1. Native tools — full CodeGraph CLI surface, no bash needed.
  registerCodegraphTool(pi, {
    name: "codegraph_explore",
    label: "CodeGraph Explore",
    description:
      "Primary CodeGraph tool. MUST be the first deep-analysis tool for repository-wide audits such as duplicated/repeated code or dead code. Answers most code questions in one call: relevant symbols' verbatim, line-numbered source grouped by file, plus call paths and blast-radius summary. Pass the user's full audit question, then use targeted follow-up explores for candidates. Best also for 'how does X work', flows, and surveying an area. Treat returned source as already Read.",
    parameters: Type.Object({
      query: Type.String({ description: "Natural-language question, or a bag of symbol/file names (e.g. 'how does AuthService reach the database', or 'UserService saveUser')." }),
      max_files: Type.Optional(Type.Number({ description: "Maximum number of files to include source from. Repository-audit queries default to 40 when omitted; focused queries keep the CodeGraph default." })),
    }),
    positional: (p) => [String(p.query)],
    options: { max_files: "number" },
  });

  registerCodegraphTool(pi, {
    name: "codegraph_node",
    label: "CodeGraph Node",
    description:
      "One symbol's source + caller/callee trail, or one focused file with line numbers + dependents. File mode defaults to at most 300 lines; use offset/limit to page. Avoid enumerating a repo with repeated node calls; for 2–4 already-selected exact files prefer codegraph_nodes.",
    parameters: Type.Object({
      name: Type.Optional(Type.String({ description: "Symbol name to look up. Omit in file mode (use `file`)." })),
      file: Type.Optional(Type.String({ description: "File mode: path to read with line numbers + dependents. Also disambiguates a symbol to this file." })),
      offset: Type.Optional(Type.Number({ description: "File mode: 1-based start line." })),
      limit: Type.Optional(Type.Number({ description: "File mode: maximum lines." })),
      symbols_only: Type.Optional(Type.Boolean({ description: "File mode: just the symbol map + dependents, no source." })),
    }),
    positional: (p) => (p.name !== undefined ? [String(p.name)] : []),
    options: { file: "string", offset: "number", limit: "number", symbols_only: "flag" },
  });

  pi.registerTool({
    name: "codegraph_nodes",
    label: "CodeGraph Nodes",
    description:
      "Bounded batch for 2–4 exact files already selected by explore/query. Syncs once and fetches at most 200 lines per file in parallel. Use it to reduce round-trips—not to enumerate the repository. For one file or a symbol, use codegraph_node.",
    parameters: Type.Object({
      files: Type.Array(
        Type.Object({
          file: Type.String({ description: "Exact indexed file path." }),
          offset: Type.Optional(Type.Number({ description: "1-based start line (default 1)." })),
          limit: Type.Optional(Type.Number({ description: "Maximum lines (default/max 200)." })),
          symbols_only: Type.Optional(Type.Boolean({ description: "Return only symbol map + dependents, without source." })),
        }),
        { minItems: 2, maxItems: 4, description: "Two to four already-selected exact files." },
      ),
    }),
    async execute(_toolCallId, params, _signal, _onUpdate, _ctx) {
      const root = findCodegraphRoot(process.cwd());
      if (!root) {
        return {
          content: [{ type: "text" as const, text: "CodeGraph: this project isn't indexed; use raw tools or initialize it first." }],
          details: {},
        };
      }

      const requested = (params.files as Array<{
        file: string;
        offset?: number;
        limit?: number;
        symbols_only?: boolean;
      }>).map((item) => ({
        file: item.file,
        offset: Math.max(1, item.offset ?? 1),
        limit: Math.min(200, Math.max(1, item.limit ?? 200)),
        symbols_only: Boolean(item.symbols_only),
      }));
      const unique = [...new Map(
        requested.map((item) => [`${item.file}:${item.offset}:${item.limit}:${item.symbols_only}`, item]),
      ).values()];

      try {
        await syncCodegraph(root);
        const outputs = await Promise.all(unique.map(async (item) => {
          const args = buildArgs(
            "node",
            item,
            root,
            [],
            { file: "string", offset: "number", limit: "number", symbols_only: "flag" },
          );
          const out = await runCodegraph(args, { cwd: root, timeoutMs: TOOL_TIMEOUT_MS });
          return `## ${item.file} (lines ${item.offset}–${item.offset + item.limit - 1})\n\n${out.trim() || "No indexed source returned."}`;
        }));
        return {
          content: [{ type: "text" as const, text: outputs.join("\n\n---\n\n") }],
          details: { root, files: unique.map((item) => item.file) },
        };
      } catch (e) {
        return {
          content: [{ type: "text" as const, text: `CodeGraph \`codegraph_nodes\` failed: ${(e as Error).message}` }],
          details: {},
        };
      }
    },
    renderResult(result, { expanded, isPartial }, theme, context) {
      return renderCodegraphResult(result.content, expanded, isPartial, theme, context.isError);
    },
  });

  registerCodegraphTool(pi, {
    name: "codegraph_query",
    label: "CodeGraph Search",
    description:
      "Full-text search for symbols by name across the codebase, powered by FTS5. Use when you know a name but not where it lives. Optionally filter by kind and cap results.",
    parameters: Type.Object({
      search: Type.String({ description: "Symbol name (or fragment) to search for." }),
      limit: Type.Optional(Type.Number({ description: "Maximum results (default 10)." })),
      kind: Type.Optional(Type.String({ description: "Filter by node kind: function, class, method, etc." })),
    }),
    positional: (p) => [String(p.search)],
    options: { limit: "number", kind: "string" },
  });

  registerCodegraphTool(pi, {
    name: "codegraph_callers",
    label: "CodeGraph Callers",
    description:
      "Find all functions/methods that call a specific symbol (inbound impact). Run before editing to see who depends on it.",
    parameters: Type.Object({
      symbol: Type.String({ description: "Symbol name whose callers you want." }),
      limit: Type.Optional(Type.Number({ description: "Maximum results (default 20)." })),
    }),
    positional: (p) => [String(p.symbol)],
    options: { limit: "number" },
  });

  registerCodegraphTool(pi, {
    name: "codegraph_callees",
    label: "CodeGraph Callees",
    description:
      "Find all functions/methods that a specific symbol calls (outbound impact). Use to trace a function's downstream behavior.",
    parameters: Type.Object({
      symbol: Type.String({ description: "Symbol name whose callees you want." }),
      limit: Type.Optional(Type.Number({ description: "Maximum results (default 20)." })),
    }),
    positional: (p) => [String(p.symbol)],
    options: { limit: "number" },
  });

  registerCodegraphTool(pi, {
    name: "codegraph_impact",
    label: "CodeGraph Impact",
    description:
      "Analyze the full transitive blast radius of changing a symbol, up to `depth` hops. Use before a non-trivial edit to know what could break.",
    parameters: Type.Object({
      symbol: Type.String({ description: "Symbol name to analyze impact for." }),
      depth: Type.Optional(Type.Number({ description: "Traversal depth (default 2)." })),
    }),
    positional: (p) => [String(p.symbol)],
    options: { depth: "number" },
  });

  registerCodegraphTool(pi, {
    name: "codegraph_files",
    label: "CodeGraph Files",
    description:
      "Project file structure from the index (tree/flat/grouped), optionally filtered by directory or glob. Use instead of `find`/`ls` for an indexed repo.",
    parameters: Type.Object({
      filter: Type.Optional(Type.String({ description: "Filter to files under this directory." })),
      pattern: Type.Optional(Type.String({ description: "Filter files matching this glob pattern." })),
      format: Type.Optional(Type.String({ description: "Output format: tree, flat, or grouped (default tree)." })),
      max_depth: Type.Optional(Type.Number({ description: "Maximum directory depth for tree format." })),
      no_metadata: Type.Optional(Type.Boolean({ description: "Hide file metadata (language, symbol count)." })),
    }),
    options: { filter: "string", pattern: "string", format: "string", max_depth: "number", no_metadata: "flag" },
  });

  registerCodegraphTool(pi, {
    name: "codegraph_status",
    label: "CodeGraph Status",
    description:
      "Index stats for the project: file count, nodes, edges, and freshness. Use to check the index before relying on it.",
    parameters: Type.Object({}),
    options: {},
    pathMode: "positional",
  });

  // Init is write-side (creates `.codegraph/` + builds the index). It must be
  // CONFIRMED — the model should propose it, then call it only after the user
  // agrees. The tool still runs `codegraph init` directly when invoked, but its
  // description steers the model to ask first. `force` is needed for paths that
  // look like home/root; never pass it without an explicit user reason.
  pi.registerTool({
    name: "codegraph_init",
    label: "CodeGraph Init",
    description:
      "Initialize CodeGraph for a project: creates a `.codegraph/` directory and builds the initial index. This is a write operation on the user's project (adds a dir, runs indexing). PROPOSE it to the user when the project has meaningful code (a real repo with source files in a supported language) AND has no `.codegraph/` yet — then call it ONLY after the user confirms. Do NOT call unprompted for tiny/throwaway folders, config-only dirs, or a user's home/root (that needs `force=true`, which you should never set without an explicit user reason). After init, the other codegraph tools become available for that project.",
    parameters: Type.Object({
      confirmed: Type.Boolean({
        description:
          "Must be true only after the user explicitly agreed to create `.codegraph/` and build the index. If the user has not confirmed, do not call this tool.",
      }),
      path: Type.Optional(Type.String({ description: "Project path to index. Defaults to the current working directory." })),
      force: Type.Optional(Type.Boolean({ description: "Initialize even if the path looks like a home directory or filesystem root. Do NOT set this without an explicit user reason." })),
    }),
    async execute(_toolCallId, params, _signal, _onUpdate, _ctx) {
      const target = resolve(process.cwd(), (params.path as string | undefined) ?? ".");
      if (!params.confirmed) {
        return {
          content: [
            {
              type: "text" as const,
              text: "CodeGraph init refused: explicit user confirmation is required. Ask whether the user wants `.codegraph/` created, then call again with confirmed=true only after they agree.",
            },
          ],
          details: { target },
        };
      }
      const result = await initializeCodegraph(params.path as string | undefined, Boolean(params.force));
      return {
        content: [{ type: "text" as const, text: result.text }],
        details: result.details,
      };
    },
    renderResult(result, { expanded, isPartial }, theme, context) {
      return renderCodegraphResult(result.content, expanded, isPartial, theme, context.isError);
    },
  });

  // Explicit slash command: invoking it is itself the user's confirmation.
  // It always initializes Pi's current working directory; choosing another
  // project remains available to the model through the codegraph_init tool.
  pi.registerCommand("codegraph-init", {
    description:
      "Initialize CodeGraph in the current project. Creates `.codegraph/` and builds the initial index.",
    handler: async (args, ctx) => {
      if (args.trim()) {
        ctx.ui.notify("Usage: /codegraph-init (the current Pi project is indexed automatically)", "error");
        return;
      }

      const target = process.cwd();
      ctx.ui.notify(`Initializing CodeGraph at ${target}…`, "info");

      const result = await initializeCodegraph(undefined, false);
      if (!result.ok) {
        ctx.ui.notify(result.text, "error");
        return;
      }

      const root = result.details.root ?? result.details.target ?? target;
      ctx.ui.notify(`CodeGraph ready at ${root}`, "info");

      // Don't trigger a model turn just for the command, but make the explicit
      // initialization visible to the model on the user's next prompt.
      pi.sendMessage(
        {
          customType: "codegraph-init",
          content: `The user explicitly invoked /codegraph-init. CodeGraph is initialized at ${root}; use the native codegraph_* tools for subsequent code exploration.`,
          display: false,
        },
        { deliverAs: "nextTurn" },
      );
    },
  });

  // 2 + 3. Always-on context injection + soft graph-first guidance.
  pi.on("before_agent_start", async (event) => {
    try {
      const cwd = event.systemPromptOptions?.cwd ?? process.cwd();
      const root = findCodegraphRoot(cwd);

      if (root) {
        const prompt = event.prompt ?? "";
        const isAudit = isRepositoryAuditPrompt(prompt);
        let context = "";
        if (prompt.trim()) {
          try {
            await syncCodegraph(root);
            const raw = await runCodegraph(
              ["prompt-hook"],
              { cwd, stdin: JSON.stringify({ prompt, cwd }), timeoutMs: HOOK_TIMEOUT_MS },
            );
            context = raw.trim();
          } catch {
            // prompt-hook is best-effort; don't block the turn on it.
          }
        }

        return {
          systemPrompt: `${event.systemPrompt}\n\n${CODEGRAPH_INSTRUCTIONS}${isAudit ? `\n\n${CODEGRAPH_AUDIT_GUIDANCE}` : ""}`,
          ...(context
            ? {
                message: {
                  customType: "codegraph",
                  content: context,
                  display: false,
                },
              }
            : {}),
        };
      }

      // New, unindexed code project: add a lightweight suggestion. The model
      // should ask first; only an explicit user confirmation unlocks init.
      if (looksLikeCodeProject(cwd)) {
        return {
          systemPrompt: `${event.systemPrompt}\n\n${CODEGRAPH_OFFER}`,
        };
      }

      return;
    } catch {
      // Swallow: a broken codegraph must never break the agent loop.
    }
  });
}
