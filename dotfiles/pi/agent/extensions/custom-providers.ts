// Custom provider manager for pi >= 0.87.
//
// Lineage: originally adapted from moonpi's custom-provider subsystem
// (https://github.com/galatolofederico/moonpi) under the MIT License,
// Copyright (c) 2026 Federico Andrea Galatolo. This file is a full rewrite
// built around live endpoint discovery, but `stripJsonComments` and
// `resolveEnvironmentVariables` still derive from that work.
//
// Design:
//   - models.json holds provider definitions (baseUrl, api, models).
//   - Credentials live in auth.json, exactly like /login, so a freshly added
//     provider is immediately usable without a separate login step.
//   - Registration/refresh is delegated to pi's own model registry. The
//     extension writes files and asks the registry to reconcile; it never
//     builds pi-ai providers itself.
//   - `models.json` is written atomically; existing provider fields that the
//     extension does not manage (headers, compat, modelOverrides, authHeader,
//     apiKey) are preserved.
//
// Commands:
//   /custom-provider:add      full wizard: URL -> auth -> probe -> models -> save
//   /custom-provider:scan     rescan an endpoint, show diff, add/remove/update
//   /custom-provider:list     provider overview with endpoint, api and key status
//   /custom-provider:key      set, clear or test a provider credential
//   /custom-provider:model    add, edit or remove a single model
//   /custom-provider:remove   remove a provider (and its credential)

import {
  getAgentDir,
  type ExtensionAPI,
  type ExtensionCommandContext,
} from "@earendil-works/pi-coding-agent";
import { Key, matchesKey, truncateToWidth } from "@earendil-works/pi-tui";
import {
  chmodSync,
  existsSync,
  mkdirSync,
  readFileSync,
  renameSync,
  unlinkSync,
  writeFileSync,
} from "node:fs";
import { dirname, join } from "node:path";

// ---------------------------------------------------------------------------
// Constants and types
// ---------------------------------------------------------------------------

const KNOWN_APIS = [
  "openai-completions",
  "openai-responses",
  "azure-openai-responses",
  "openai-codex-responses",
  "anthropic-messages",
  "mistral-conversations",
  "google-generative-ai",
  "google-vertex",
  "bedrock-converse-stream",
] as const;

type KnownApi = (typeof KNOWN_APIS)[number];

const DEFAULT_API: Record<string, KnownApi> = {
  openai: "openai-completions",
  anthropic: "anthropic-messages",
  google: "google-generative-ai",
  ollama: "openai-completions",
  lmstudio: "openai-completions",
};

type DiscoveryKind = "openai" | "anthropic" | "google" | "lmstudio" | "ollama";

interface ModelDefinition {
  id: string;
  name?: string;
  api?: KnownApi;
  baseUrl?: string;
  reasoning?: boolean;
  thinkingLevelMap?: Partial<Record<"off" | "minimal" | "low" | "medium" | "high" | "xhigh" | "max", string | null>>;
  input?: Array<"text" | "image">;
  cost?: { input: number; output: number; cacheRead: number; cacheWrite: number };
  contextWindow?: number;
  maxTokens?: number;
  headers?: Record<string, string>;
  compat?: Record<string, unknown>;
}

interface ProviderConfig {
  name?: string;
  baseUrl?: string;
  api?: KnownApi;
  /** Legacy location for a key. New credentials go to auth.json. */
  apiKey?: string;
  headers?: Record<string, string>;
  compat?: Record<string, unknown>;
  authHeader?: boolean;
  models?: ModelDefinition[];
  modelOverrides?: Record<string, unknown>;
  [key: string]: unknown;
}

interface ModelsConfig {
  providers: Record<string, ProviderConfig>;
}

/** Normalized model record extracted from any supported discovery endpoint. */
interface DiscoveredModel {
  id: string;
  name?: string;
  contextWindow?: number;
  maxTokens?: number;
  reasoning?: boolean;
  input?: Array<"text" | "image">;
  ownedBy?: string;
  /** Endpoint-specific classification, e.g. "embedding". */
  kind?: string;
  note?: string;
  /** True when the model is a chat model (embeddings are excluded by default). */
  chat: boolean;
}

interface ProbeResult {
  url: string;
  kind: DiscoveryKind;
  models: DiscoveredModel[];
  sample: string;
}

interface ScanDiff {
  added: DiscoveredModel[];
  removed: ModelDefinition[];
  changed: Array<{ existing: ModelDefinition; discovered: DiscoveredModel; fields: string[] }>;
  unchanged: ModelDefinition[];
}

type AuthMethod =
  | { type: "key"; key: string }
  | { type: "env"; variable: string }
  | { type: "keyless" };

/** Shape of the private runtime used to persist credentials, same path as /login. */
interface CredentialRuntime {
  login(
    providerId: string,
    type: "api_key" | "oauth",
    interaction: {
      prompt(prompt: { type: "secret" | "text"; message: string }): Promise<string>;
      notify(event: unknown): void;
      signal?: AbortSignal;
    },
  ): Promise<unknown>;
  logout(providerId: string, options?: { signal?: AbortSignal }): Promise<void>;
  getProviderAuthStatus(providerId: string): { configured: boolean; source?: string };
}

const isKnownApi = (value: string): value is KnownApi => (KNOWN_APIS as readonly string[]).includes(value);

const modelsJsonPath = () => join(getAgentDir(), "models.json");

// ---------------------------------------------------------------------------
// models.json reading and writing
// ---------------------------------------------------------------------------

/** Matches pi's JSONC support: strips // comments and trailing commas. */
function stripJsonComments(input: string): string {
  return input
    .replace(/"(?:\\.|[^"\\])*"|\/\/[^\n]*/g, (match) => (match[0] === '"' ? match : ""))
    .replace(/"(?:\\.|[^"\\])*"|,(\s*[}\]])/g, (match, tail) => tail ?? (match[0] === '"' ? match : ""));
}

function readModelsJson(): ModelsConfig {
  const path = modelsJsonPath();
  if (!existsSync(path)) return { providers: {} };
  const parsed = JSON.parse(stripJsonComments(readFileSync(path, "utf8"))) as Partial<ModelsConfig>;
  if (!parsed.providers || typeof parsed.providers !== "object" || Array.isArray(parsed.providers)) {
    throw new Error(`${path} must contain a top-level "providers" object.`);
  }
  return { providers: parsed.providers };
}

/** Writes atomically so an interrupted command cannot truncate models.json. */
function writeModelsJson(config: ModelsConfig): void {
  const path = modelsJsonPath();
  const temporaryPath = `${path}.tmp-${process.pid}`;
  mkdirSync(dirname(path), { recursive: true });
  try {
    writeFileSync(temporaryPath, `${JSON.stringify(config, null, 2)}\n`, { encoding: "utf8", mode: 0o600 });
    renameSync(temporaryPath, path);
    chmodSync(path, 0o600);
  } catch (error) {
    if (existsSync(temporaryPath)) unlinkSync(temporaryPath);
    throw error;
  }
}

function loadConfig(ctx: ExtensionCommandContext): ModelsConfig | undefined {
  try {
    return readModelsJson();
  } catch (error) {
    ctx.ui.notify(`Cannot read ${modelsJsonPath()}: ${error instanceof Error ? error.message : String(error)}`, "error");
    return undefined;
  }
}

function saveConfig(ctx: ExtensionCommandContext, config: ModelsConfig): boolean {
  try {
    writeModelsJson(config);
    return true;
  } catch (error) {
    ctx.ui.notify(`Cannot write ${modelsJsonPath()}: ${error instanceof Error ? error.message : String(error)}`, "error");
    return false;
  }
}

/** Applies a partial patch to one provider, preserving every unmanaged field. */
function patchProvider(
  config: ModelsConfig,
  providerId: string,
  patch: Partial<ProviderConfig>,
): void {
  const previous = config.providers[providerId] ?? {};
  config.providers[providerId] = { ...previous, ...patch };
}

// ---------------------------------------------------------------------------
// Environment interpolation (same syntax as models.json)
// ---------------------------------------------------------------------------

function resolveEnvironmentVariables(value: string): string | undefined {
  let unresolved = false;
  const escapedDollar = "\u0000PI_LITERAL_DOLLAR\u0000";
  const escapedBang = "\u0000PI_LITERAL_BANG\u0000";
  const result = value
    .replace(/\$\$/g, escapedDollar)
    .replace(/\$!/g, escapedBang)
    .replace(/\$\{([A-Za-z_][A-Za-z0-9_]*)\}|\$([A-Za-z_][A-Za-z0-9_]*)/g, (_m, braced, plain) => {
      const resolved = process.env[braced ?? plain];
      if (resolved === undefined) {
        unresolved = true;
        return "";
      }
      return resolved;
    })
    .replaceAll(escapedDollar, "$")
    .replaceAll(escapedBang, "!");
  return unresolved ? undefined : result;
}

// ---------------------------------------------------------------------------
// Credential persistence through pi's native auth.json path
// ---------------------------------------------------------------------------

/**
 * Returns pi's credential runtime. `ModelRegistry.runtime` is not part of the
 * published extension types, so it is probed defensively; when it is missing
 * the caller falls back to instructing the user to run /login.
 */
function credentialRuntime(ctx: ExtensionCommandContext): CredentialRuntime | undefined {
  const registry = ctx.modelRegistry as unknown as { runtime?: unknown };
  const runtime = registry.runtime as CredentialRuntime | undefined;
  return runtime && typeof runtime.login === "function" ? runtime : undefined;
}

/** Stores a credential via Models.login, which persists it to auth.json atomically. */
async function storeCredential(
  ctx: ExtensionCommandContext,
  providerId: string,
  value: string,
): Promise<boolean> {
  const runtime = credentialRuntime(ctx);
  if (!runtime) {
    ctx.ui.notify(`Cannot store the credential automatically. Run /login ${providerId} to save it.`, "warning");
    return false;
  }
  try {
    await runtime.login(providerId, "api_key", {
      prompt: async () => value,
      notify: () => {},
      signal: ctx.signal,
    });
    return true;
  } catch (error) {
    ctx.ui.notify(
      `Could not store the credential for "${providerId}": ${error instanceof Error ? error.message : String(error)}`,
      "error",
    );
    return false;
  }
}

async function clearCredential(ctx: ExtensionCommandContext, providerId: string): Promise<boolean> {
  const runtime = credentialRuntime(ctx);
  if (!runtime) return false;
  try {
    await runtime.logout(providerId, { signal: ctx.signal });
    return true;
  } catch (error) {
    ctx.ui.notify(
      `Could not clear the credential for "${providerId}": ${error instanceof Error ? error.message : String(error)}`,
      "error",
    );
    return false;
  }
}

// ---------------------------------------------------------------------------
// Endpoint probing and model discovery
// ---------------------------------------------------------------------------

function isObject(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

function asNumber(value: unknown): number | undefined {
  return typeof value === "number" && Number.isFinite(value) && value > 0 ? value : undefined;
}

function asString(value: unknown): string | undefined {
  return typeof value === "string" && value.length > 0 ? value : undefined;
}

/** Candidate discovery endpoints derived from a user-supplied base URL. */
function candidateEndpoints(baseUrl: string): string[] {
  const base = baseUrl.trim().replace(/\/+$/, "");
  const urls = new Set<string>();
  if (/\/(v1|v1beta)\/models$/.test(base)) {
    urls.add(base);
    return [...urls];
  }
  if (/\/(v1|v1beta)$/.test(base)) {
    urls.add(`${base}/models`);
    return [...urls];
  }
  if (/\/models$/.test(base)) {
    urls.add(base);
  }
  urls.add(`${base}/v1/models`); // OpenAI-compatible
  urls.add(`${base}/api/v0/models`); // LM Studio rich metadata
  urls.add(`${base}/v1beta/models`); // Google Generative AI
  urls.add(`${base}/api/tags`); // Ollama native
  urls.add(`${base}/models`); // bare OpenAI-compatible
  return [...urls];
}

function buildProbeHeaders(apiKey: string | undefined, providerHeaders?: Record<string, string>): Record<string, string> {
  const headers: Record<string, string> = { Accept: "application/json" };
  for (const [name, value] of Object.entries(providerHeaders ?? {})) {
    const resolved = resolveEnvironmentVariables(value);
    if (resolved !== undefined) headers[name] = resolved;
  }
  if (apiKey) {
    // Send every common credential header so a probe works before the API
    // family is known. Servers ignore the ones they do not use.
    headers.Authorization = `Bearer ${apiKey}`;
    headers["x-api-key"] = apiKey;
    headers["anthropic-version"] = "2023-06-01";
  }
  return headers;
}

/** Classifies a discovery payload by its shape. */
function classifyPayload(body: unknown): DiscoveryKind | undefined {
  const source = Array.isArray(body) ? body : isObject(body) ? (body.data ?? body.models) : undefined;
  if (!Array.isArray(source) || source.length === 0) return undefined;
  const first = source[0];
  if (!isObject(first)) return undefined;

  // Ollama tags expose `model`/`name` plus digest/size but no `id`.
  if (isObject(first.details) || "digest" in first || ("model" in first && !("id" in first))) return "ollama";
  if (asString(first.name)?.startsWith("models/")) return "google";
  if (asNumber(first.inputTokenLimit) !== undefined && "displayName" in first) return "google";
  if (
    "max_context_length" in first ||
    "loaded_instances" in first ||
    "publisher" in first ||
    "compatibility_type" in first
  ) {
    return "lmstudio";
  }
  if (asString(first.display_name) && !("owned_by" in first)) return "anthropic";
  if (asString(first.id)) return "openai";
  return undefined;
}

function inferReasoning(id: string, name: string): boolean | undefined {
  const text = `${id} ${name}`;
  const patterns = [
    /(^|[/_:.\s-])(r1|qwq|magistral|deepseek-r)([/_:.\s-]|$)/i,
    /(^|[/_:.\s-])(qwen-?3|qwen3)([/_:.\s-]|\d)/i,
    /(^|[/_:.\s-])(o1|o3|o4)([/_:.\s-]|$)/i,
    /gpt-oss/i,
    /glm-4\.(5|6|7)|glm-5/i,
    /reason/i,
    /think/i,
    /gemini-(2\.5|3)/i,
    /claude-(opus|sonnet)/i,
  ];
  return patterns.some((pattern) => pattern.test(text)) ? true : undefined;
}

function inferVision(id: string, name: string): boolean | undefined {
  const text = `${id} ${name}`;
  const patterns = [
    /vl([/_:.\s-]|$)/i,
    /vision/i,
    /llava/i,
    /pixtral/i,
    /internvl/i,
    /minicpm-v/i,
    /gemma-?[34]/i,
    /qwen.*vl/i,
    /llama-?4/i,
    /mistral-small-3/i,
    /gpt-4o|gpt-4\.1|gpt-5/i,
    /claude-(opus|sonnet|haiku)/i,
    /gemini/i,
  ];
  return patterns.some((pattern) => pattern.test(text)) ? true : undefined;
}

/** Normalizes a discovery payload into chat/embedding records. */
function normalizeModels(kind: DiscoveryKind, body: unknown): DiscoveredModel[] {
  const source = Array.isArray(body) ? body : isObject(body) ? (body.data ?? body.models) : [];
  if (!Array.isArray(source)) return [];
  const models: DiscoveredModel[] = [];

  for (const raw of source) {
    if (!isObject(raw)) continue;
    const model = normalizeModel(kind, raw);
    if (model) models.push(model);
  }

  // De-duplicate by id, preserving the first occurrence.
  const seen = new Set<string>();
  return models.filter((model) => (seen.has(model.id) ? false : (seen.add(model.id), true)));
}

function normalizeModel(kind: DiscoveryKind, raw: Record<string, unknown>): DiscoveredModel | undefined {
  switch (kind) {
    case "openai": {
      const id = asString(raw.id);
      if (!id) return undefined;
      const name = asString(raw.name) ?? asString(raw.display_name);
      const meta = isObject(raw.meta) ? raw.meta : undefined;
      const contextWindow =
        asNumber(raw.context_window) ??
        asNumber(raw.max_model_len) ??
        asNumber(raw.max_context_length) ??
        asNumber(meta?.n_ctx_train) ??
        asNumber(meta?.n_ctx);
      const capabilities = isObject(raw.capabilities) ? raw.capabilities : undefined;
      const reasoning =
        typeof capabilities?.reasoning === "boolean"
          ? capabilities.reasoning
          : isObject(capabilities?.reasoning) || Array.isArray(capabilities?.reasoning)
            ? true
            : inferReasoning(id, name ?? "");
      const vision = typeof capabilities?.vision === "boolean" ? capabilities.vision : undefined;
      return {
        id,
        name,
        contextWindow,
        maxTokens: asNumber(raw.max_tokens) ?? asNumber(raw.max_output_tokens) ?? asNumber(raw.max_completion_tokens),
        reasoning,
        input: (vision ?? inferVision(id, name ?? "")) ? ["text", "image"] : undefined,
        ownedBy: asString(raw.owned_by),
        chat: !/embed|rerank/i.test(id),
      };
    }
    case "anthropic": {
      const id = asString(raw.id);
      if (!id) return undefined;
      const name = asString(raw.display_name);
      return {
        id,
        name,
        reasoning: inferReasoning(id, name ?? ""),
        input: inferVision(id, name ?? "") ? ["text", "image"] : undefined,
        note: asString(raw.created_at),
        chat: true,
      };
    }
    case "google": {
      const fullName = asString(raw.name);
      if (!fullName) return undefined;
      const id = fullName.replace(/^models\//, "");
      const methods = Array.isArray(raw.supportedGenerationMethods)
        ? raw.supportedGenerationMethods.filter((entry): entry is string => typeof entry === "string")
        : [];
      const chat = methods.length === 0 || methods.includes("generateContent");
      const name = asString(raw.displayName);
      return {
        id,
        name,
        contextWindow: asNumber(raw.inputTokenLimit),
        maxTokens: asNumber(raw.outputTokenLimit),
        reasoning: inferReasoning(id, name ?? ""),
        input: inferVision(id, name ?? "") ? ["text", "image"] : undefined,
        note: methods.length > 0 ? methods.join(", ") : undefined,
        chat,
      };
    }
    case "lmstudio": {
      const id = asString(raw.key) ?? asString(raw.id);
      if (!id) return undefined;
      const loaded = Array.isArray(raw.loaded_instances) ? raw.loaded_instances[0] : undefined;
      const config = isObject(loaded) && isObject(loaded.config) ? loaded.config : undefined;
      const capabilities = isObject(raw.capabilities) ? raw.capabilities : undefined;
      const reasoningCapability = capabilities?.reasoning;
      const visionCapability = capabilities?.vision;
      const quantization = isObject(raw.quantization) ? asString(raw.quantization.name) : undefined;
      return {
        id,
        name: asString(raw.display_name),
        contextWindow: asNumber(config?.context_length) ?? asNumber(raw.max_context_length),
        reasoning:
          typeof reasoningCapability === "boolean"
            ? reasoningCapability
            : isObject(reasoningCapability) || Array.isArray(reasoningCapability)
              ? true
              : inferReasoning(id, asString(raw.display_name) ?? ""),
        input: visionCapability === true ? ["text", "image"] : undefined,
        ownedBy: asString(raw.publisher),
        kind: asString(raw.type),
        note: [asString(raw.architecture), quantization].filter(Boolean).join(" ") || undefined,
        chat: asString(raw.type) !== "embedding" && !/embed/i.test(id),
      };
    }
    case "ollama": {
      const id = asString(raw.model) ?? asString(raw.name);
      if (!id) return undefined;
      const details = isObject(raw.details) ? raw.details : undefined;
      const parameters = isObject(details?.parameter_size)
        ? undefined
        : asString((details as Record<string, unknown> | undefined)?.parameter_size);
      const family = asString(details?.family);
      const sizeBytes = asNumber(raw.size);
      const note = [family, parameters, sizeBytes ? `${(sizeBytes / 1e9).toFixed(1)}GB` : undefined]
        .filter(Boolean)
        .join(" ");
      return {
        id,
        name: asString(raw.name),
        reasoning: inferReasoning(id, asString(raw.name) ?? ""),
        input: inferVision(id, asString(raw.name) ?? "") ? ["text", "image"] : undefined,
        note: note || "ollama",
        chat: !/embed/i.test(id),
      };
    }
    default:
      return undefined;
  }
}

async function probeEndpoint(url: string, headers: Record<string, string>, signal: AbortSignal): Promise<ProbeResult | { url: string; error: string }> {
  try {
    const response = await fetch(url, { headers, signal });
    if (!response.ok) return { url, error: `HTTP ${response.status} ${response.statusText}` };
    const body = await response.json();
    const kind = classifyPayload(body);
    if (!kind) return { url, error: "unrecognized model list format" };
    const models = normalizeModels(kind, body);
    if (models.length === 0) return { url, error: "no models in response" };
    return { url, kind, models, sample: models.slice(0, 3).map((model) => model.id).join(", ") };
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    return { url, error: message.includes("abort") ? "timeout" : message };
  }
}

async function probeAll(
  baseUrl: string,
  headers: Record<string, string>,
  signal: AbortSignal,
): Promise<{ ok: ProbeResult[]; failures: Array<{ url: string; error: string }> }> {
  const urls = candidateEndpoints(baseUrl);
  const results = await Promise.all(
    urls.map((url) => probeEndpoint(url, headers, AbortSignal.any([signal, AbortSignal.timeout(8_000)]))),
  );
  const ok: ProbeResult[] = [];
  const failures: Array<{ url: string; error: string }> = [];
  for (const result of results) {
    if ("error" in result) failures.push(result);
    else ok.push(result);
  }
  return { ok, failures };
}

/** Derives the inference base URL from the chosen discovery endpoint. */
function deriveBaseUrl(discoveryUrl: string, kind: DiscoveryKind): string {
  const withoutModels = discoveryUrl.replace(/\/models$/, "").replace(/\/api\/tags$/, "");
  if (kind === "lmstudio" || kind === "ollama") {
    // Both serve an OpenAI-compatible API under /v1.
    return `${withoutModels.replace(/\/api\/v0$/, "").replace(/\/api$/, "")}/v1`;
  }
  if (kind === "google") return withoutModels;
  if (withoutModels.endsWith("/v1") || withoutModels.endsWith("/v1beta")) return withoutModels;
  return `${withoutModels}/v1`;
}

function defaultProviderId(baseUrl: string): string {
  try {
    const url = new URL(baseUrl);
    const host = url.hostname.replace(/[^a-z0-9]+/gi, "-");
    const port = url.port ? `-${url.port}` : "";
    const path = url.pathname.replace(/[^a-z0-9]+/gi, "-").replace(/^-+|-+$/g, "");
    const id = [host + port, path].filter(Boolean).join("-").replace(/-+/g, "-").toLowerCase();
    return id || "custom-provider";
  } catch {
    return "custom-provider";
  }
}

// ---------------------------------------------------------------------------
// Diff between discovery and stored configuration
// ---------------------------------------------------------------------------

function contextWindowOf(model: DiscoveredModel): number | undefined {
  return model.contextWindow;
}

function buildScanDiff(discovered: DiscoveredModel[], existing: ModelDefinition[]): ScanDiff {
  const existingById = new Map(existing.map((model) => [model.id, model]));
  const discoveredById = new Map(discovered.map((model) => [model.id, model]));
  const added: DiscoveredModel[] = [];
  const removed: ModelDefinition[] = [];
  const changed: ScanDiff["changed"] = [];
  const unchanged: ModelDefinition[] = [];

  for (const model of discovered) {
    if (!existingById.has(model.id)) added.push(model);
  }
  for (const model of existing) {
    if (!discoveredById.has(model.id)) removed.push(model);
  }
  for (const model of existing) {
    const remote = discoveredById.get(model.id);
    if (!remote) continue;
    const fields: string[] = [];
    // Name differences are cosmetic and noisy; only flag metadata that affects behavior.
    if (contextWindowOf(remote) && contextWindowOf(remote) !== model.contextWindow) fields.push("context");
    if (remote.maxTokens && remote.maxTokens !== model.maxTokens) fields.push("maxTokens");
    if (remote.reasoning && model.reasoning === undefined) fields.push("reasoning");
    if (remote.input && model.input === undefined) fields.push("input");
    if (fields.length > 0) changed.push({ existing: model, discovered: remote, fields });
    else unchanged.push(model);
  }
  return { added, removed, changed, unchanged };
}

/** Builds a stored definition from a discovered model, preserving explicit user values. */
function toModelDefinition(discovered: DiscoveredModel, previous?: ModelDefinition): ModelDefinition {
  const model: ModelDefinition = { ...(previous ?? {}) };
  model.id = discovered.id;
  if (!previous?.name && discovered.name && discovered.name !== discovered.id) model.name = discovered.name;
  if (!previous?.reasoning && discovered.reasoning) model.reasoning = true;
  if (!previous?.input && discovered.input) model.input = discovered.input;
  if (!previous?.contextWindow && contextWindowOf(discovered)) model.contextWindow = contextWindowOf(discovered);
  if (!previous?.maxTokens && discovered.maxTokens) model.maxTokens = discovered.maxTokens;
  return model;
}

// ---------------------------------------------------------------------------
// Terminal UI helpers
// ---------------------------------------------------------------------------

interface MultiSelectOption {
  id: string;
  label: string;
  detail?: string;
  section?: string;
  preselected?: boolean;
  disabled?: boolean;
}

/**
 * Checkbox list with section grouping. Returns the selected ids, or undefined
 * when the user cancels. Falls back to a confirmation prompt outside TUI mode.
 */
async function multiSelect(
  ctx: ExtensionCommandContext,
  title: string,
  subtitle: string,
  options: MultiSelectOption[],
  fallbackPrompt?: string,
): Promise<string[] | undefined> {
  if (options.length === 0) return [];
  const selectable = options.filter((option) => !option.disabled);

  if (ctx.mode !== "tui") {
    // Without a custom component the only interactive primitive is confirm().
    // A missing fallback prompt means "select nothing", which keeps unsafe
    // defaults (model removal) from applying in non-interactive modes.
    if (!fallbackPrompt) return [];
    const confirmed = await ctx.ui.confirm(fallbackPrompt, `${selectable.length} item(s)`);
    return confirmed ? selectable.map((option) => option.id) : [];
  }

  return ctx.ui.custom<string[] | undefined>((tui, theme, _keybindings, done) => {
    let cursor = 0;
    let cachedLines: string[] | undefined;
    const selected = new Set<string>(options.filter((option) => option.preselected && !option.disabled).map((o) => o.id));

    const move = (delta: number) => {
      cursor = Math.max(0, Math.min(options.length - 1, cursor + delta));
      cachedLines = undefined;
    };

    return {
      invalidate: () => {
        cachedLines = undefined;
      },
      handleInput(data: string) {
        if (matchesKey(data, Key.up)) return move(-1);
        if (matchesKey(data, Key.down)) return move(1);
        if (matchesKey(data, Key.pageUp)) return move(-10);
        if (matchesKey(data, Key.pageDown)) return move(10);
        if (matchesKey(data, Key.space)) {
          const option = options[cursor];
          if (option && !option.disabled) {
            selected.has(option.id) ? selected.delete(option.id) : selected.add(option.id);
            cachedLines = undefined;
          }
          return;
        }
        if (data === "a") {
          for (const option of selectable) selected.add(option.id);
          cachedLines = undefined;
          return;
        }
        if (data === "A") {
          selected.clear();
          cachedLines = undefined;
          return;
        }
        if (matchesKey(data, Key.escape)) return done(undefined);
        if (matchesKey(data, Key.enter)) return done([...selected]);
        tui.requestRender();
      },
      render(width: number) {
        if (cachedLines) return cachedLines;
        const lines: string[] = [];
        const add = (line: string) => lines.push(truncateToWidth(line, width));
        add(theme.fg("accent", "─".repeat(width)));
        add(theme.fg("text", ` ${title}`));
        if (subtitle) add(theme.fg("dim", ` ${subtitle}`));
        lines.push("");
        let lastSection: string | undefined;
        options.forEach((option, index) => {
          if (option.section && option.section !== lastSection) {
            if (lastSection !== undefined) lines.push("");
            add(theme.fg("muted", `  ${option.section}`));
            lastSection = option.section;
          }
          const marker = option.disabled
            ? theme.fg("dim", "•")
            : selected.has(option.id)
              ? theme.fg("success", "☑")
              : theme.fg("dim", "☐");
          const label = theme.fg(option.disabled ? "dim" : "text", option.label);
          const detail = option.detail ? theme.fg("dim", `  ${option.detail}`) : "";
          add(`${index === cursor ? theme.fg("accent", "> ") : "  "}${marker} ${label}${detail}`);
        });
        lines.push("");
        add(theme.fg("dim", " Space toggle • a all • A none • Enter confirm • Esc cancel"));
        add(theme.fg("accent", "─".repeat(width)));
        cachedLines = lines;
        return lines;
      },
    };
  });
}

function formatDiffSummary(diff: ScanDiff, discoveredCount: number): string[] {
  return [
    `Wykryto ${discoveredCount} model(i) na endpoincie.`,
    `  + nowe: ${diff.added.length}`,
    `  - zniknięte: ${diff.removed.length}`,
    `  ~ zmienione metadane: ${diff.changed.length}`,
    `  = bez zmian: ${diff.unchanged.length}`,
  ];
}

/** Applies a metadata update to an existing definition for the listed fields. */
function applyMetadata(existing: ModelDefinition, discovered: DiscoveredModel, fields: string[]): ModelDefinition {
  const model: ModelDefinition = { ...existing };
  if (fields.includes("name") && discovered.name) model.name = discovered.name;
  if (fields.includes("context") && contextWindowOf(discovered)) model.contextWindow = contextWindowOf(discovered);
  if (fields.includes("maxTokens") && discovered.maxTokens) model.maxTokens = discovered.maxTokens;
  if (fields.includes("reasoning") && discovered.reasoning) model.reasoning = true;
  if (fields.includes("input") && discovered.input) model.input = discovered.input;
  return model;
}

// ---------------------------------------------------------------------------
// Shared flows
// ---------------------------------------------------------------------------

interface ResolvedEndpoint {
  discoveryUrl: string;
  kind: DiscoveryKind;
  models: DiscoveredModel[];
}

/** Probes a base URL and lets the user choose which discovery endpoint to trust. */
async function chooseEndpoint(
  ctx: ExtensionCommandContext,
  baseUrl: string,
  headers: Record<string, string>,
): Promise<ResolvedEndpoint | undefined> {
  // Command handlers usually run while the agent is idle, so ctx.signal is
  // normally undefined; probes still need a cancellation source of their own.
  const signal = ctx.signal ?? new AbortController().signal;
  ctx.ui.notify(`Skanuję ${baseUrl}…`, "info");
  const { ok, failures } = await probeAll(baseUrl, headers, signal);
  if (ok.length === 0) {
    const detail = failures.map((failure) => `  ${failure.url} → ${failure.error}`).join("\n");
    ctx.ui.notify(`Nie znaleziono działającego endpointu modeli:\n${detail}`, "error");
    return undefined;
  }

  if (ok.length === 1) return { discoveryUrl: ok[0].url, kind: ok[0].kind, models: ok[0].models };

  const labels = ok.map((result) => `${result.url}  [${result.kind}, ${result.models.length} modeli]`);
  const choice = await ctx.ui.select("Preferowany endpoint skanowania", labels);
  if (!choice) return undefined;
  const picked = ok[labels.indexOf(choice)];
  return picked ? { discoveryUrl: picked.url, kind: picked.kind, models: picked.models } : undefined;
}

/** Persists provider + models and reconciles the registry. Returns false on write failure. */
async function persistProvider(
  ctx: ExtensionCommandContext,
  config: ModelsConfig,
  providerId: string,
  patch: Partial<ProviderConfig>,
): Promise<boolean> {
  patchProvider(config, providerId, patch);
  if (!saveConfig(ctx, config)) return false;
  try {
    await ctx.modelRegistry.refresh({ allowNetwork: false });
  } catch (error) {
    ctx.ui.notify(`models.json zapisany, ale przeładowanie rejestru nie powiodło się: ${String(error)}`, "warning");
  }
  return true;
}

// ---------------------------------------------------------------------------
// /custom-provider:add
// ---------------------------------------------------------------------------

async function addProvider(pi: ExtensionAPI, args: string, ctx: ExtensionCommandContext): Promise<void> {
  const config = loadConfig(ctx);
  if (!config) return;

  const urlInput = args.trim() || (await ctx.ui.input("Endpoint URL (z portem)", "http://localhost:1234"));
  const baseInput = urlInput?.trim();
  if (!baseInput) {
    ctx.ui.notify("Anulowano: URL jest wymagany.", "warning");
    return;
  }

  const authChoices = [
    "Wklej klucz API",
    "Odwołanie do zmiennej środowiskowej ($NAZWA)",
    "Bez autoryzacji (serwer lokalny)",
  ];
  const authChoice = await ctx.ui.select("Uwierzytelnianie", authChoices);
  if (!authChoice) return;

  let auth: AuthMethod;
  if (authChoice === "Wklej klucz API") {
    const key = (await ctx.ui.input("Klucz API (zostanie zapisany w auth.json, jak /login)"))?.trim();
    if (!key) {
      ctx.ui.notify("Anulowano: brak klucza.", "warning");
      return;
    }
    auth = { type: "key", key };
  } else if (authChoice.startsWith("Odwołanie")) {
    const variable = (await ctx.ui.input("Nazwa zmiennej środowiskowej", "MY_API_KEY"))?.trim();
    if (!variable) {
      ctx.ui.notify("Anulowano: brak nazwy zmiennej.", "warning");
      return;
    }
    auth = { type: "env", variable };
  } else {
    auth = { type: "keyless" };
  }

  const probeKey =
    auth.type === "key" ? auth.key : auth.type === "env" ? process.env[auth.variable] : undefined;
  const headers = buildProbeHeaders(probeKey);
  const endpoint = await chooseEndpoint(ctx, baseInput, headers);
  if (!endpoint) return;

  const suggestedApi = DEFAULT_API[endpoint.kind];
  const apiLabels = KNOWN_APIS.map((api) => (api === suggestedApi ? `${api}  (sugerowane)` : api));
  const apiChoice = await ctx.ui.select("Typ API inferencji", apiLabels);
  if (!apiChoice) return;
  const api = KNOWN_APIS[apiLabels.indexOf(apiChoice)];
  if (!api || !isKnownApi(api)) return;

  const suggestedBase = deriveBaseUrl(endpoint.discoveryUrl, endpoint.kind);
  const baseUrlInput = await ctx.ui.input("Base URL inferencji", suggestedBase);
  const inferenceBase = baseUrlInput?.trim();
  if (!inferenceBase) {
    ctx.ui.notify("Anulowano: base URL jest wymagany.", "warning");
    return;
  }

  const suggestedId = defaultProviderId(baseInput);
  const idInput = await ctx.ui.input("Id providera", suggestedId);
  const providerId = idInput?.trim();
  if (!providerId) {
    ctx.ui.notify("Anulowano: id providera jest wymagany.", "warning");
    return;
  }

  const existing = config.providers[providerId];
  if (existing) {
    const overwrite = await ctx.ui.confirm(
      `Provider "${providerId}" już istnieje. Nadpisać?`,
      "baseUrl, api i lista modeli zostaną zastąpione; headers, compat i modelOverrides zostaną zachowane.",
    );
    if (!overwrite) return;
  }

  const chatModels = endpoint.models.filter((model) => model.chat);
  const embeddingModels = endpoint.models.filter((model) => !model.chat);
  const selected = await multiSelect(
    ctx,
    `Wykryto ${endpoint.models.length} model(i) w ${endpoint.discoveryUrl}`,
    "Odznacz modele, których nie chcesz dodać.",
    [
      ...chatModels.map((model) => ({
        id: model.id,
        label: model.id,
        detail: [model.name, model.contextWindow ? `ctx: ${model.contextWindow}` : "", model.note]
          .filter(Boolean)
          .join(" • "),
        section: "Modele czatu",
        preselected: true,
      })),
      ...embeddingModels.map((model) => ({
        id: model.id,
        label: model.id,
        detail: "embedding/rerank — domyślnie pomijane",
        section: "Modele nie-czatowe",
        preselected: false,
      })),
    ],
    `Dodać wszystkie ${chatModels.length} model(i) czatu?`,
  );
  if (selected === undefined) {
    ctx.ui.notify("Anulowano.", "info");
    return;
  }
  if (selected.length === 0) {
    ctx.ui.notify("Nie wybrano żadnego modelu. Provider nie został dodany.", "warning");
    return;
  }

  const models = selected
    .map((id) => endpoint.models.find((model) => model.id === id))
    .filter((model): model is DiscoveredModel => Boolean(model))
    .map((model) => toModelDefinition(model));

  const preview = [
    `Provider: ${providerId}`,
    `Base URL: ${inferenceBase}`,
    `API: ${api}`,
    `Modele: ${models.length}`,
    `Klucz: ${auth.type === "key" ? "wklejony (auth.json)" : auth.type === "env" ? `$${auth.variable} (auth.json)` : "bez autoryzacji (placeholder)"}`,
  ].join("\n");
  const confirmed = await ctx.ui.confirm("Zapisać providera?", preview);
  if (!confirmed) return;

  const ok = await persistProvider(ctx, config, providerId, {
    baseUrl: inferenceBase,
    api,
    models,
  });
  if (!ok) return;

  // Store the credential in auth.json so the provider is usable without a
  // separate /login. Keyless servers get a placeholder so auth counts as
  // configured, matching the documented dummy-key pattern for local servers.
  // The provider must already be registered (persistProvider ran first)
  // because Models.login resolves it by id.
  const credential = auth.type === "key" ? auth.key : auth.type === "env" ? `$${auth.variable}` : "local";
  await storeCredential(ctx, providerId, credential);
  if (auth.type === "env" && process.env[auth.variable] === undefined) {
    ctx.ui.notify(`Uwaga: ${credential} nie jest ustawiona w środowisku.`, "warning");
  }

  const status = ctx.modelRegistry.getProviderAuthStatus(providerId);
  ctx.ui.notify(
    `Dodano providera "${providerId}" z ${models.length} modelami. ` +
      `Uwierzytelnianie: ${status.configured ? (status.source ?? "skonfigurowane") : "brak"}.`,
    "info",
  );
}

// ---------------------------------------------------------------------------
// /custom-provider:scan
// ---------------------------------------------------------------------------

async function scanProvider(_pi: ExtensionAPI, _args: string, ctx: ExtensionCommandContext): Promise<void> {
  const config = loadConfig(ctx);
  if (!config) return;
  const providerIds = Object.keys(config.providers)
    .filter((name) => Boolean(config.providers[name]?.baseUrl))
    .sort();
  if (providerIds.length === 0) {
    ctx.ui.notify("Brak custom providerów z baseUrl.", "warning");
    return;
  }

  const providerId = await ctx.ui.select("Provider do skanowania", providerIds);
  if (!providerId) return;
  const provider = config.providers[providerId];
  if (!provider?.baseUrl) {
    ctx.ui.notify(`Provider "${providerId}" nie ma baseUrl.`, "error");
    return;
  }

  const storedKey = await ctx.modelRegistry.getApiKeyForProvider(providerId);
  const headers = buildProbeHeaders(storedKey, provider.headers);
  const endpoint = await chooseEndpoint(ctx, provider.baseUrl, headers);
  if (!endpoint) return;

  const existing = provider.models ?? [];
  const diff = buildScanDiff(endpoint.models, existing);

  for (const line of formatDiffSummary(diff, endpoint.models.length)) ctx.ui.notify(line, "info");

  // 1. Removal: ask about every disappeared model, none preselected.
  let modelsAfterRemoval = [...existing];
  if (diff.removed.length > 0) {
    const removalIds = await multiSelect(
      ctx,
      `Modele zniknęły z ${endpoint.discoveryUrl}`,
      "Zaznacz te, które usunąć z models.json. Domyślnie żaden nie jest zaznaczony.",
      diff.removed.map((model) => ({
        id: model.id,
        label: model.id,
        detail: model.name ? `${model.name} • ctx: ${model.contextWindow ?? "?"}` : undefined,
        section: "Zniknięte z endpointu",
        preselected: false,
      })),
      // No fallback prompt: outside TUI nothing is removed unless the user
      // explicitly confirms, and even then only via the selector.
    );
    if (removalIds === undefined) {
      ctx.ui.notify("Anulowano.", "info");
      return;
    }
    if (removalIds.length > 0) {
      const removeSet = new Set(removalIds);
      modelsAfterRemoval = modelsAfterRemoval.filter((model) => !removeSet.has(model.id));
    }
  }

  // 2. Metadata updates for models that still exist.
  let modelsAfterMetadata = modelsAfterRemoval;
  if (diff.changed.length > 0) {
    const details = diff.changed
      .map((entry) => `  ${entry.existing.id}: ${entry.fields.join(", ")}`)
      .join("\n");
    const applyUpdates = await ctx.ui.confirm(
      `Zaktualizować metadane ${diff.changed.length} model(i) z endpointu?`,
      `Zmienione pola:\n${details}`,
    );
    if (applyUpdates) {
      const changedById = new Map(diff.changed.map((entry) => [entry.existing.id, entry]));
      modelsAfterMetadata = modelsAfterMetadata.map((model) => {
        const entry = changedById.get(model.id);
        return entry ? applyMetadata(model, entry.discovered, entry.fields) : model;
      });
    }
  }

  // 3. Additions: all new models preselected.
  let modelsAfterAdditions = modelsAfterMetadata;
  const existingIds = new Set(modelsAfterMetadata.map((model) => model.id));
  const addable = diff.added.filter((model) => !existingIds.has(model.id));
  if (addable.length > 0) {
    const selected = await multiSelect(
      ctx,
      `Nowe modele na ${endpoint.discoveryUrl}`,
      "Odznacz te, których nie chcesz dodać.",
      [
        ...addable
          .filter((model) => model.chat)
          .map((model) => ({
            id: model.id,
            label: model.id,
            detail: [model.name, model.contextWindow ? `ctx: ${model.contextWindow}` : "", model.note]
              .filter(Boolean)
              .join(" • "),
            section: "Modele czatu",
            preselected: true,
          })),
        ...addable
          .filter((model) => !model.chat)
          .map((model) => ({
            id: model.id,
            label: model.id,
            detail: "embedding/rerank — domyślnie pomijane",
            section: "Modele nie-czatowe",
            preselected: false,
          })),
      ],
      `Dodać ${addable.filter((model) => model.chat).length} nowych model(i) czatu?`,
    );
    if (selected === undefined) {
      ctx.ui.notify("Anulowano.", "info");
      return;
    }
    const selectedSet = new Set(selected);
    const additions = addable
      .filter((model) => selectedSet.has(model.id))
      .map((model) => toModelDefinition(model));
    modelsAfterAdditions = [...modelsAfterAdditions, ...additions];
  }

  const removedCount = existing.length - modelsAfterRemoval.length;
  const addedCount = modelsAfterAdditions.length - modelsAfterRemoval.length;
  const summary = [
    `Provider: ${providerId}`,
    `Endpoint: ${endpoint.discoveryUrl}`,
    `Dodane: ${addedCount}`,
    `Usunięte: ${removedCount}`,
    `Łącznie modeli: ${modelsAfterAdditions.length}`,
  ].join("\n");
  const confirmed = await ctx.ui.confirm("Zapisać zmiany w models.json?", summary);
  if (!confirmed) return;

  await persistProvider(ctx, config, providerId, { models: modelsAfterAdditions });
  ctx.ui.notify(
    `Zsynchronizowano "${providerId}": +${addedCount} / -${removedCount}, razem ${modelsAfterAdditions.length} modeli.`,
    "info",
  );
}

// ---------------------------------------------------------------------------
// /custom-provider:list
// ---------------------------------------------------------------------------

async function listProviders(_pi: ExtensionAPI, _args: string, ctx: ExtensionCommandContext): Promise<void> {
  const config = loadConfig(ctx);
  if (!config) return;
  const ids = Object.keys(config.providers).sort();
  if (ids.length === 0) {
    ctx.ui.notify("Brak custom providerów.", "info");
    return;
  }

  const lines: string[] = [];
  for (const id of ids) {
    const provider = config.providers[id]!;
    const status = ctx.modelRegistry.getProviderAuthStatus(id);
    const keyState = status.configured
      ? `klucz: ${status.source ?? "tak"}`
      : provider.apiKey
        ? "klucz: models.json (legacy)"
        : "klucz: brak";
    lines.push(`${id}`);
    lines.push(`  url: ${provider.baseUrl ?? "—"}`);
    lines.push(`  api: ${provider.api ?? "—"}`);
    lines.push(`  modele: ${provider.models?.length ?? 0}${provider.modelOverrides ? ` + ${Object.keys(provider.modelOverrides).length} overrides` : ""}`);
    lines.push(`  ${keyState}`);
  }
  ctx.ui.notify(`Custom providers (${ids.length}):\n${lines.join("\n")}`, "info");
}

// ---------------------------------------------------------------------------
// /custom-provider:key
// ---------------------------------------------------------------------------

async function manageKey(_pi: ExtensionAPI, _args: string, ctx: ExtensionCommandContext): Promise<void> {
  const config = loadConfig(ctx);
  if (!config) return;
  const ids = Object.keys(config.providers).sort();
  if (ids.length === 0) {
    ctx.ui.notify("Brak custom providerów.", "warning");
    return;
  }
  const providerId = await ctx.ui.select("Provider", ids);
  if (!providerId) return;

  const status = ctx.modelRegistry.getProviderAuthStatus(providerId);
  const actions = [
    status.configured ? "Zmień klucz" : "Ustaw klucz",
    "Wyczyść klucz (logout)",
    "Testuj połączenie",
  ];
  const action = await ctx.ui.select(`Klucz dla "${providerId}" (${status.configured ? status.source ?? "skonfigurowany" : "brak"})`, actions);
  if (!action) return;

  if (action === "Wyczyść klucz (logout)") {
    if (await clearCredential(ctx, providerId)) {
      ctx.ui.notify(`Wyczyszczono klucz dla "${providerId}".`, "info");
    }
    return;
  }

  if (action === "Testuj połączenie") {
    const provider = config.providers[providerId]!;
    if (!provider.baseUrl) {
      ctx.ui.notify("Provider nie ma baseUrl.", "error");
      return;
    }
    const key = await ctx.modelRegistry.getApiKeyForProvider(providerId);
    const endpoint = await chooseEndpoint(ctx, provider.baseUrl, buildProbeHeaders(key, provider.headers));
    if (endpoint) ctx.ui.notify(`Połączenie OK: ${endpoint.models.length} modeli na ${endpoint.discoveryUrl}.`, "info");
    return;
  }

  const choices = ["Wklej klucz API", "Odwołanie do zmiennej środowiskowej ($NAZWA)", "Bez autoryzacji (placeholder)"];
  const how = await ctx.ui.select("Sposób przechowania", choices);
  if (!how) return;
  let value: string;
  if (how === "Wklej klucz API") {
    const key = (await ctx.ui.input("Klucz API"))?.trim();
    if (!key) return;
    value = key;
  } else if (how.startsWith("Odwołanie")) {
    const variable = (await ctx.ui.input("Nazwa zmiennej", "MY_API_KEY"))?.trim();
    if (!variable) return;
    value = `$${variable}`;
  } else {
    value = "local";
  }
  if (await storeCredential(ctx, providerId, value)) {
    if (value.startsWith("$") && process.env[value.slice(1)] === undefined) {
      ctx.ui.notify(
        `Zapisano klucz dla "${providerId}", ale zmienna ${value} nie jest ustawiona — ` +
          `provider pozostanie niedostępny do czasu jej ustawienia.`,
        "warning",
      );
      return;
    }
    ctx.ui.notify(`Zapisano klucz dla "${providerId}" w auth.json.`, "info");
  }
}

// ---------------------------------------------------------------------------
// /custom-provider:model
// ---------------------------------------------------------------------------

async function manageModel(_pi: ExtensionAPI, _args: string, ctx: ExtensionCommandContext): Promise<void> {
  const config = loadConfig(ctx);
  if (!config) return;
  const ids = Object.keys(config.providers).sort();
  if (ids.length === 0) {
    ctx.ui.notify("Brak custom providerów.", "warning");
    return;
  }
  const providerId = await ctx.ui.select("Provider", ids);
  if (!providerId) return;
  const provider = config.providers[providerId]!;
  provider.models ??= [];

  const actions = ["Dodaj model ręcznie", "Edytuj model", "Usuń model"];
  const action = await ctx.ui.select(`Modele "${providerId}" (${provider.models.length})`, actions);
  if (!action) return;

  if (action === "Dodaj model ręcznie") {
    const id = (await ctx.ui.input("Model ID"))?.trim();
    if (!id) return;
    if (provider.models.some((model) => model.id === id)) {
      ctx.ui.notify(`Model "${id}" już istnieje.`, "warning");
      return;
    }
    const definition: ModelDefinition = { id };
    const name = (await ctx.ui.input("Nazwa wyświetlana (opcjonalnie)", id))?.trim();
    if (name && name !== id) definition.name = name;
    if (await ctx.ui.confirm("Konfiguracja zaawansowana?", "Reasoning, obrazy, context, max output.")) {
      if (await ctx.ui.confirm("Obsługuje reasoning?", "")) definition.reasoning = true;
      definition.input = (await ctx.ui.confirm("Obsługuje obrazy?", "")) ? ["text", "image"] : ["text"];
      const context = Number.parseInt((await ctx.ui.input("Context window", "128000"))?.trim() ?? "", 10);
      if (Number.isFinite(context) && context > 0) definition.contextWindow = context;
      const maxTokens = Number.parseInt((await ctx.ui.input("Max output tokens", "16384"))?.trim() ?? "", 10);
      if (Number.isFinite(maxTokens) && maxTokens > 0) definition.maxTokens = maxTokens;
    }
    provider.models.push(definition);
    if (await persistProvider(ctx, config, providerId, { models: provider.models })) {
      ctx.ui.notify(`Dodano model "${id}".`, "info");
    }
    return;
  }

  if (provider.models.length === 0) {
    ctx.ui.notify("Brak modeli do edycji.", "warning");
    return;
  }
  const labels = provider.models.map((model) => model.name ? `${model.id} (${model.name})` : model.id);
  const label = await ctx.ui.select("Model", labels);
  if (!label) return;
  const index = labels.indexOf(label);
  const model = provider.models[index]!;

  if (action === "Usuń model") {
    if (!(await ctx.ui.confirm(`Usunąć model "${model.id}"?`, ""))) return;
    provider.models.splice(index, 1);
    if (await persistProvider(ctx, config, providerId, { models: provider.models })) {
      ctx.ui.notify(`Usunięto model "${model.id}".`, "info");
    }
    return;
  }

  // Edit: sequential field prompts, keeping current values as defaults.
  const name = (await ctx.ui.input("Nazwa wyświetlana", model.name ?? model.id))?.trim();
  if (name) model.name = name;
  model.reasoning = await ctx.ui.confirm("Obsługuje reasoning?", model.reasoning ? "obecnie: tak" : "obecnie: nie");
  model.input = (await ctx.ui.confirm(`Obsługuje obrazy?`, model.input?.includes("image") ? "obecnie: tak" : "obecnie: nie"))
    ? ["text", "image"]
    : ["text"];
  const context = Number.parseInt((await ctx.ui.input("Context window", String(model.contextWindow ?? 128000)))?.trim() ?? "", 10);
  if (Number.isFinite(context) && context > 0) model.contextWindow = context;
  const maxTokens = Number.parseInt((await ctx.ui.input("Max output tokens", String(model.maxTokens ?? 16384)))?.trim() ?? "", 10);
  if (Number.isFinite(maxTokens) && maxTokens > 0) model.maxTokens = maxTokens;

  if (await persistProvider(ctx, config, providerId, { models: provider.models })) {
    ctx.ui.notify(`Zaktualizowano model "${model.id}".`, "info");
  }
}

// ---------------------------------------------------------------------------
// /custom-provider:remove
// ---------------------------------------------------------------------------

async function removeProvider(_pi: ExtensionAPI, _args: string, ctx: ExtensionCommandContext): Promise<void> {
  const config = loadConfig(ctx);
  if (!config) return;
  const ids = Object.keys(config.providers).sort();
  if (ids.length === 0) {
    ctx.ui.notify("Brak custom providerów.", "warning");
    return;
  }
  const providerId = await ctx.ui.select("Provider do usunięcia", ids);
  if (!providerId) return;
  const count = config.providers[providerId]?.models?.length ?? 0;
  const confirmed = await ctx.ui.confirm(
    `Usunąć providera "${providerId}" i ${count} model(i)?`,
    "Wpis w models.json oraz jego klucz w auth.json zostaną usunięte.",
  );
  if (!confirmed) return;

  delete config.providers[providerId];
  if (!saveConfig(ctx, config)) return;
  await clearCredential(ctx, providerId);
  try {
    await ctx.modelRegistry.refresh({ allowNetwork: false });
  } catch {
    /* nothing else to do */
  }
  ctx.ui.notify(`Usunięto providera "${providerId}".`, "info");
}

// ---------------------------------------------------------------------------
// Extension entry point
// ---------------------------------------------------------------------------

export default function customProviders(pi: ExtensionAPI): void {
  pi.registerCommand("custom-provider:add", {
    description: "Kreator: URL → auth → skan endpointów → modele → zapis",
    handler: (args, ctx) => addProvider(pi, args, ctx),
  });
  pi.registerCommand("custom-provider:scan", {
    description: "Przeskanuj endpoint i zsynchronizuj modele (dodaj/usuń/zmień)",
    handler: (args, ctx) => scanProvider(pi, args, ctx),
  });
  pi.registerCommand("custom-provider:list", {
    description: "Lista custom providerów z endpointem, api i statusem klucza",
    handler: (args, ctx) => listProviders(pi, args, ctx),
  });
  pi.registerCommand("custom-provider:key", {
    description: "Ustaw, wyczyść lub przetestuj klucz providera (auth.json)",
    handler: (args, ctx) => manageKey(pi, args, ctx),
  });
  pi.registerCommand("custom-provider:model", {
    description: "Dodaj, edytuj lub usuń pojedynczy model",
    handler: (args, ctx) => manageModel(pi, args, ctx),
  });
  pi.registerCommand("custom-provider:remove", {
    description: "Usuń providera wraz z jego kluczem",
    handler: (args, ctx) => removeProvider(pi, args, ctx),
  });

  pi.on("session_start", (_event, ctx) => {
    const legacy: string[] = [];
    try {
      for (const [name, provider] of Object.entries(readModelsJson().providers)) {
        if (typeof provider.apiKey === "string" && provider.apiKey.length > 0) legacy.push(name);
      }
    } catch {
      return;
    }
    if (legacy.length > 0) {
      ctx.ui.notify(
        `Providery ${legacy.join(", ")} trzymają apiKey w models.json. ` +
          `Użyj /custom-provider:key, aby przenieść klucz do auth.json.`,
        "warning",
      );
    }
  });
}
