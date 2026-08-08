// Adapted from moonpi's custom-provider subsystem:
// https://github.com/galatolofederico/moonpi/blob/main/src/custom-providers.ts
//
// MIT License
// Copyright (c) 2026 Federico Andrea Galatolo
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
//
// Rewritten for pi >= 0.81: providers are runtime `Provider` objects registered
// with `pi.registerProvider(createProvider(...))`. Credentials are managed by pi
// through `/login <provider>` and resolved by each provider's ApiKeyAuth. The
// extension never touches auth.json and never stores keys in models.json.

import {
  anthropicMessagesApi,
  azureOpenAIResponsesApi,
  bedrockConverseStreamApi,
  createProvider,
  googleGenerativeAIApi,
  googleVertexApi,
  mistralConversationsApi,
  openAICodexResponsesApi,
  openAICompletionsApi,
  openAIResponsesApi,
  type Api,
  type Model,
  type ProviderStreams,
} from "@earendil-works/pi-ai";
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

function isKnownApi(value: string): value is KnownApi {
  return (KNOWN_APIS as readonly string[]).includes(value);
}

interface ModelDefinition {
  id: string;
  name?: string;
  api?: KnownApi;
  baseUrl?: string;
  reasoning?: boolean;
  thinkingLevelMap?: Partial<Record<"off" | "minimal" | "low" | "medium" | "high" | "xhigh" | "max", string | null>>;
  input?: Array<"text" | "image">;
  cost?: {
    input: number;
    output: number;
    cacheRead: number;
    cacheWrite: number;
  };
  contextWindow?: number;
  maxTokens?: number;
  headers?: Record<string, string>;
  compat?: Record<string, unknown>;
}

interface ProviderConfig {
  name?: string;
  baseUrl?: string;
  /**
   * Kept for reading legacy configs only. Keys must NOT live in models.json;
   * store them via `/login <provider>` (pi writes auth.json). The extension
   * never writes this field and warns when it encounters it.
   */
  apiKey?: string;
  api?: KnownApi;
  headers?: Record<string, string>;
  compat?: Record<string, unknown>;
  authHeader?: boolean;
  models?: ModelDefinition[];
  modelOverrides?: Record<string, unknown>;
}

interface ModelsConfig {
  providers: Record<string, ProviderConfig>;
}

interface RemoteModel {
  id: string;
  name?: string;
  owned_by?: string;
  max_model_len?: number;
  context_window?: number;
  max_context_length?: number;
}

interface ModelsListResponse {
  data: RemoteModel[];
}

const modelsJsonPath = () => join(getAgentDir(), "models.json");

const API_IMPLEMENTATIONS: Record<KnownApi, () => ProviderStreams> = {
  "openai-completions": openAICompletionsApi,
  "openai-responses": openAIResponsesApi,
  "azure-openai-responses": azureOpenAIResponsesApi,
  "openai-codex-responses": openAICodexResponsesApi,
  "anthropic-messages": anthropicMessagesApi,
  "mistral-conversations": mistralConversationsApi,
  "google-generative-ai": googleGenerativeAIApi,
  "google-vertex": googleVertexApi,
  "bedrock-converse-stream": bedrockConverseStreamApi,
};

function registerConfiguredProvider(
  pi: ExtensionAPI,
  providerName: string,
  config: ProviderConfig,
): void {
  if (!config.baseUrl) throw new Error(`Provider "${providerName}" has no baseUrl.`);
  if (config.api !== undefined && !isKnownApi(config.api)) {
    throw new Error(`Provider "${providerName}" uses unsupported api "${config.api}".`);
  }

  const models = (config.models ?? []).map((model): Model<Api> => {
    const api = model.api ?? config.api;
    if (!api || !isKnownApi(api)) {
      throw new Error(`Model "${model.id}" has no supported api.`);
    }

    return {
      id: model.id,
      name: model.name ?? model.id,
      api,
      provider: providerName,
      baseUrl: model.baseUrl ?? config.baseUrl!,
      reasoning: model.reasoning ?? false,
      thinkingLevelMap: model.thinkingLevelMap,
      input: model.input ?? ["text"],
      cost: model.cost ?? { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 },
      contextWindow: model.contextWindow ?? 128_000,
      maxTokens: model.maxTokens ?? 16_384,
      headers: model.headers,
      compat: { ...config.compat, ...model.compat },
    } as Model<Api>;
  });

  const usedApis = new Set(models.map((model) => model.api));
  if (usedApis.size === 0 && config.api) usedApis.add(config.api);
  if (usedApis.size === 0) {
    throw new Error(`Provider "${providerName}" has no API implementation.`);
  }
  const api = Object.fromEntries(
    [...usedApis].map((name) => [name, API_IMPLEMENTATIONS[name as KnownApi]()]),
  ) as Partial<Record<Api, ProviderStreams>>;

  pi.registerProvider(createProvider({
    id: providerName,
    name: config.name ?? providerName,
    baseUrl: config.baseUrl,
    headers: config.headers,
    auth: {
      apiKey: {
        name: `${config.name ?? providerName} API key`,
        async login(interaction) {
          const key = await interaction.prompt({
            type: "secret",
            message: `Enter API key for ${config.name ?? providerName}`,
          });
          return { type: "api_key", key };
        },
        async resolve({ credential }) {
          if (credential?.key) {
            return config.authHeader
              ? {
                  auth: { headers: { Authorization: `Bearer ${credential.key}` } },
                  source: "stored credential",
                }
              : { auth: { apiKey: credential.key }, source: "stored credential" };
          }
          return { auth: {}, source: "keyless provider" };
        },
      },
    },
    models,
    api,
  }));
}

function applyConfiguredProvider(
  pi: ExtensionAPI,
  providerName: string,
  config: ProviderConfig,
  ctx: ExtensionCommandContext,
): boolean {
  try {
    registerConfiguredProvider(pi, providerName, config);
    return true;
  } catch (error) {
    ctx.ui.notify(
      `Cannot register provider "${providerName}": ${error instanceof Error ? error.message : String(error)}`,
      "error",
    );
    return false;
  }
}

/** Matches Pi's JSONC support: strips // comments and trailing commas. */
function stripJsonComments(input: string): string {
  return input
    .replace(/"(?:\\.|[^"\\])*"|\/\/[^\n]*/g, (match) =>
      match[0] === '"' ? match : "",
    )
    .replace(/"(?:\\.|[^"\\])*"|,(\s*[}\]])/g, (match, tail) =>
      tail ?? (match[0] === '"' ? match : ""),
    );
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
  const directory = dirname(path);
  const temporaryPath = `${path}.tmp-${process.pid}`;
  mkdirSync(directory, { recursive: true });

  try {
    writeFileSync(temporaryPath, `${JSON.stringify(config, null, 2)}\n`, {
      encoding: "utf8",
      mode: 0o600,
    });
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
    ctx.ui.notify(
      `Cannot read ${modelsJsonPath()}: ${error instanceof Error ? error.message : String(error)}`,
      "error",
    );
    return undefined;
  }
}

function saveConfig(ctx: ExtensionCommandContext, config: ModelsConfig): boolean {
  try {
    writeModelsJson(config);
    return true;
  } catch (error) {
    ctx.ui.notify(
      `Cannot write ${modelsJsonPath()}: ${error instanceof Error ? error.message : String(error)}`,
      "error",
    );
    return false;
  }
}

function resolveEnvironmentVariables(value: string): string | undefined {
  let unresolved = false;
  const escapedDollar = "\u0000PI_LITERAL_DOLLAR\u0000";
  const escapedBang = "\u0000PI_LITERAL_BANG\u0000";
  const result = value
    .replace(/\$\$/g, escapedDollar)
    .replace(/\$!/g, escapedBang)
    .replace(/\$\{([A-Za-z_][A-Za-z0-9_]*)\}|\$([A-Za-z_][A-Za-z0-9_]*)/g, (_match, braced, plain) => {
      const name = braced ?? plain;
      const resolved = process.env[name];
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

/** Finds providers that still keep an API key in models.json (legacy). */
function findLegacyApiKeys(): string[] {
  let config: ModelsConfig;
  try {
    config = readModelsJson();
  } catch {
    return [];
  }
  return Object.entries(config.providers)
    .filter(([, providerConfig]) => typeof providerConfig.apiKey === "string" && providerConfig.apiKey.length > 0)
    .map(([name]) => name)
    .sort();
}

function modelContextWindow(model: RemoteModel): number | undefined {
  const value = model.max_model_len ?? model.context_window ?? model.max_context_length;
  return typeof value === "number" && Number.isFinite(value) && value > 0 ? value : undefined;
}

function modelsEndpoint(baseUrl: string): string {
  const normalized = baseUrl.replace(/\/+$/, "");
  return normalized.endsWith("/v1") ? `${normalized}/models` : `${normalized}/v1/models`;
}

async function addProvider(pi: ExtensionAPI, _args: string, ctx: ExtensionCommandContext): Promise<void> {
  const config = loadConfig(ctx);
  if (!config) return;

  const providerInput = await ctx.ui.input("Provider name (for example: my-vllm)", "my-provider");
  const providerName = providerInput?.trim();
  if (!providerName) {
    ctx.ui.notify("Cancelled: provider name is required.", "warning");
    return;
  }

  if (config.providers[providerName]) {
    const overwrite = await ctx.ui.confirm(
      `Provider "${providerName}" already exists. Overwrite it?`,
      "The existing provider configuration and its model list will be replaced.",
    );
    if (!overwrite) return;
  }

  const selectedApi = await ctx.ui.select("API type", [...KNOWN_APIS]);
  if (!selectedApi || !isKnownApi(selectedApi)) return;
  const api = selectedApi;

  const defaultUrl = api === "anthropic-messages"
    ? "https://api.anthropic.com"
    : api === "google-generative-ai"
      ? "https://generativelanguage.googleapis.com/v1beta"
      : "http://localhost:8000/v1";
  const baseUrlInput = await ctx.ui.input("Base URL", defaultUrl);
  const baseUrl = baseUrlInput?.trim();
  if (!baseUrl) {
    ctx.ui.notify("Cancelled: base URL is required.", "warning");
    return;
  }

  config.providers[providerName] = {
    baseUrl,
    api,
    models: [],
  };

  if (!saveConfig(ctx, config)) return;
  if (!applyConfiguredProvider(pi, providerName, config.providers[providerName]!, ctx)) return;

  ctx.ui.notify(
    `Added and registered provider "${providerName}". ` +
      `Run /login ${providerName} to store its API key in auth.json ` +
      `(skip for keyless servers), then use /custom-provider:scan-models or /custom-provider:add-model.`,
    "info",
  );
}

async function addModel(pi: ExtensionAPI, _args: string, ctx: ExtensionCommandContext): Promise<void> {
  const config = loadConfig(ctx);
  if (!config) return;
  const providerNames = Object.keys(config.providers).sort();
  if (providerNames.length === 0) {
    ctx.ui.notify("No custom providers found. Use /custom-provider:add-provider first.", "warning");
    return;
  }

  const providerName = await ctx.ui.select("Provider", providerNames);
  if (!providerName) return;
  const provider = config.providers[providerName]!;

  const idInput = await ctx.ui.input("Model ID", "");
  const id = idInput?.trim();
  if (!id) {
    ctx.ui.notify("Cancelled: model ID is required.", "warning");
    return;
  }
  if ((provider.models ?? []).some((model) => model.id === id)) {
    ctx.ui.notify(`Model "${id}" already exists in "${providerName}".`, "warning");
    return;
  }

  const displayName = await ctx.ui.input("Display name (optional)", id);
  const advanced = await ctx.ui.confirm(
    "Configure advanced model options?",
    "Reasoning, image input, context window, and maximum output tokens.",
  );
  const model: ModelDefinition = {
    id,
    ...(displayName?.trim() && displayName.trim() !== id ? { name: displayName.trim() } : {}),
  };

  if (advanced) {
    model.reasoning = await ctx.ui.confirm("Does the model support reasoning?", "");
    model.input = (await ctx.ui.confirm("Does the model support image input?", ""))
      ? ["text", "image"]
      : ["text"];

    const contextInput = await ctx.ui.input("Context window", "128000");
    const contextWindow = Number.parseInt(contextInput?.trim() ?? "", 10);
    if (Number.isFinite(contextWindow) && contextWindow > 0) model.contextWindow = contextWindow;

    const maxTokensInput = await ctx.ui.input("Maximum output tokens", "16384");
    const maxTokens = Number.parseInt(maxTokensInput?.trim() ?? "", 10);
    if (Number.isFinite(maxTokens) && maxTokens > 0) model.maxTokens = maxTokens;
  }

  provider.models ??= [];
  provider.models.push(model);
  if (!saveConfig(ctx, config)) return;
  if (!applyConfiguredProvider(pi, providerName, provider, ctx)) return;
  ctx.ui.notify(`Added and registered model "${id}" in "${providerName}".`, "info");
}

async function chooseDiscoveredModels(
  ctx: ExtensionCommandContext,
  providerName: string,
  models: RemoteModel[],
  existingIds: Set<string>,
): Promise<string[] | undefined> {
  if (ctx.mode !== "tui") {
    ctx.ui.notify("Interactive model discovery requires TUI mode.", "warning");
    return undefined;
  }

  return ctx.ui.custom<string[]>((tui, theme, _keybindings, done) => {
    let cursor = 0;
    let cachedLines: string[] | undefined;
    const selected = new Set<number>();
    const addable = new Set(
      models.flatMap((model, index) => existingIds.has(model.id) ? [] : [index]),
    );

    const refresh = () => {
      cachedLines = undefined;
      tui.requestRender();
    };

    return {
      invalidate: () => { cachedLines = undefined; },
      handleInput(data: string) {
        if (matchesKey(data, Key.up)) cursor = Math.max(0, cursor - 1);
        else if (matchesKey(data, Key.down)) cursor = Math.min(models.length - 1, cursor + 1);
        else if (matchesKey(data, Key.space) && addable.has(cursor)) {
          selected.has(cursor) ? selected.delete(cursor) : selected.add(cursor);
        } else if (data === "a") {
          for (const index of addable) selected.add(index);
        } else if (data === "A") selected.clear();
        else if (matchesKey(data, Key.escape)) return done([]);
        else if (matchesKey(data, Key.enter)) {
          const indices = selected.size > 0 ? [...selected] : [...addable];
          return done(indices.sort((a, b) => a - b).map((index) => models[index]!.id));
        } else return;
        refresh();
      },
      render(width: number) {
        if (cachedLines) return cachedLines;
        const lines: string[] = [];
        const add = (line: string) => lines.push(truncateToWidth(line, width));
        add(theme.fg("accent", "─".repeat(width)));
        add(theme.fg("text", ` Found ${models.length} models at ${providerName}`));
        lines.push("");
        models.forEach((model, index) => {
          const available = addable.has(index);
          const marker = available
            ? selected.has(index) ? theme.fg("success", "☑") : theme.fg("dim", "☐")
            : theme.fg("dim", "■");
          const context = modelContextWindow(model);
          const metadata = `${context ? ` (ctx: ${context})` : ""}${model.owned_by ? ` — ${model.owned_by}` : ""}${available ? "" : " [already added]"}`;
          const label = theme.fg(available ? "text" : "dim", `${model.id}${metadata}`);
          add(`${index === cursor ? theme.fg("accent", "> ") : "  "}${marker} ${label}`);
        });
        lines.push("");
        add(theme.fg("dim", " Space toggle • Enter confirm (all new if none selected) • a/A all/none • Esc cancel"));
        add(theme.fg("accent", "─".repeat(width)));
        cachedLines = lines;
        return lines;
      },
    };
  });
}

async function scanModels(pi: ExtensionAPI, _args: string, ctx: ExtensionCommandContext): Promise<void> {
  const config = loadConfig(ctx);
  if (!config) return;
  // Discovery uses an OpenAI-compatible /v1/models endpoint independently
  // from the inference API. Servers such as LM Studio may serve inference via
  // anthropic-messages while still exposing model discovery at /v1/models.
  const providerNames = Object.keys(config.providers)
    .filter((name) => Boolean(config.providers[name]!.baseUrl))
    .sort();

  if (providerNames.length === 0) {
    ctx.ui.notify("No custom providers with a base URL found.", "warning");
    return;
  }

  const providerName = await ctx.ui.select("Provider to scan", providerNames);
  if (!providerName) return;
  const provider = config.providers[providerName]!;
  if (!provider.baseUrl) {
    ctx.ui.notify(`Provider "${providerName}" has no base URL.`, "error");
    return;
  }

  const endpoint = modelsEndpoint(provider.baseUrl);
  ctx.ui.notify(`Scanning ${endpoint}…`, "info");

  let remoteModels: RemoteModel[];
  try {
    const headers: Record<string, string> = { Accept: "application/json" };
    for (const [name, value] of Object.entries(provider.headers ?? {})) {
      const resolved = resolveEnvironmentVariables(value);
      if (resolved === undefined) throw new Error(`Header ${name} references a missing environment variable.`);
      headers[name] = resolved;
    }
    // Official credential read through pi's model registry (including auth.json).
    const apiKey = await ctx.modelRegistry.getApiKeyForProvider(providerName);
    if (apiKey) headers.Authorization = `Bearer ${apiKey}`;
    // Keyless servers (e.g. local LM Studio/LiteLLM) are scanned without Authorization.

    const response = await fetch(endpoint, {
      headers,
      signal: AbortSignal.timeout(15_000),
    });
    if (!response.ok) throw new Error(`HTTP ${response.status} ${response.statusText}`);
    const body = await response.json() as Partial<ModelsListResponse>;
    if (!Array.isArray(body.data)) throw new Error('Expected an OpenAI-compatible { "data": [...] } response.');
    remoteModels = body.data
      .filter((model): model is RemoteModel => typeof model?.id === "string" && model.id.length > 0)
      .filter((model, index, all) => all.findIndex((candidate) => candidate.id === model.id) === index)
      .sort((a, b) => a.id.localeCompare(b.id));
  } catch (error) {
    ctx.ui.notify(`Model discovery failed at ${endpoint}: ${error instanceof Error ? error.message : String(error)}`, "error");
    return;
  }

  if (remoteModels.length === 0) {
    ctx.ui.notify("The endpoint returned no models.", "info");
    return;
  }

  const existingIds = new Set((provider.models ?? []).map((model) => model.id));
  if (remoteModels.every((model) => existingIds.has(model.id))) {
    ctx.ui.notify(`All ${remoteModels.length} discovered models are already configured.`, "info");
    return;
  }

  const selectedIds = await chooseDiscoveredModels(ctx, providerName, remoteModels, existingIds);
  if (!selectedIds || selectedIds.length === 0) {
    ctx.ui.notify("No models added.", "info");
    return;
  }

  provider.models ??= [];
  for (const id of selectedIds) {
    if (existingIds.has(id)) continue;
    const remote = remoteModels.find((model) => model.id === id)!;
    const contextWindow = modelContextWindow(remote);
    provider.models.push({
      id,
      ...(remote.name && remote.name !== id ? { name: remote.name } : {}),
      ...(contextWindow ? { contextWindow } : {}),
    });
    existingIds.add(id);
  }

  if (!saveConfig(ctx, config)) return;
  if (!applyConfiguredProvider(pi, providerName, provider, ctx)) return;
  ctx.ui.notify(`Added and registered ${selectedIds.length} model(s) in "${providerName}".`, "info");
}

async function removeProvider(pi: ExtensionAPI, _args: string, ctx: ExtensionCommandContext): Promise<void> {
  const config = loadConfig(ctx);
  if (!config) return;
  const names = Object.keys(config.providers).sort();
  if (names.length === 0) {
    ctx.ui.notify("No custom providers found.", "warning");
    return;
  }
  const name = await ctx.ui.select("Provider to remove", names);
  if (!name) return;
  const count = config.providers[name]!.models?.length ?? 0;
  if (!await ctx.ui.confirm(
    `Remove provider "${name}" and ${count} model(s) from ${modelsJsonPath()}?`,
    `Its stored credential (if any) stays in auth.json — run /logout ${name} to clear it.`,
  )) return;

  delete config.providers[name];
  if (!saveConfig(ctx, config)) return;
  pi.unregisterProvider(name);
  ctx.ui.notify(
    `Removed and unregistered provider "${name}". Run /logout ${name} if it had a stored key.`,
    "info",
  );
}

async function removeModel(pi: ExtensionAPI, _args: string, ctx: ExtensionCommandContext): Promise<void> {
  const config = loadConfig(ctx);
  if (!config) return;
  const providerNames = Object.keys(config.providers)
    .filter((name) => (config.providers[name]!.models?.length ?? 0) > 0)
    .sort();
  if (providerNames.length === 0) {
    ctx.ui.notify("No custom models found.", "warning");
    return;
  }
  const providerName = await ctx.ui.select("Provider", providerNames);
  if (!providerName) return;
  const models = config.providers[providerName]!.models!;
  const labels = models.map((model) => model.name ? `${model.id} (${model.name})` : model.id);
  const label = await ctx.ui.select("Model to remove", labels);
  if (!label) return;
  const index = labels.indexOf(label);
  const model = models[index]!;
  if (!await ctx.ui.confirm(`Remove model "${model.id}" from "${providerName}"?`, "")) return;
  models.splice(index, 1);
  if (!saveConfig(ctx, config)) return;
  if (!applyConfiguredProvider(pi, providerName, config.providers[providerName]!, ctx)) return;
  ctx.ui.notify(`Removed model "${model.id}" and updated "${providerName}".`, "info");
}

export default function customProviders(pi: ExtensionAPI): void {
  try {
    const config = readModelsJson();
    for (const [providerName, providerConfig] of Object.entries(config.providers)) {
      registerConfiguredProvider(pi, providerName, providerConfig);
    }
  } catch (error) {
    console.error(
      `[custom-providers] Cannot register providers from ${modelsJsonPath()}:`,
      error instanceof Error ? error.message : String(error),
    );
  }

  pi.on("session_start", (_event, ctx) => {
    const legacy = findLegacyApiKeys();
    if (legacy.length > 0) {
      ctx.ui.notify(
        `Providers ${legacy.join(", ")} keep an apiKey in models.json. ` +
          `Remove it and run /login <provider> to store keys in auth.json instead.`,
        "warning",
      );
    }
  });

  pi.registerCommand("custom-provider:add-provider", {
    description: "Add and register a custom provider",
    handler: (args, ctx) => addProvider(pi, args, ctx),
  });
  pi.registerCommand("custom-provider:add-model", {
    description: "Add and register a model for a custom provider",
    handler: (args, ctx) => addModel(pi, args, ctx),
  });
  pi.registerCommand("custom-provider:scan-models", {
    description: "Discover and register OpenAI-compatible models",
    handler: (args, ctx) => scanModels(pi, args, ctx),
  });
  pi.registerCommand("custom-provider:remove-provider", {
    description: "Remove and unregister a custom provider",
    handler: (args, ctx) => removeProvider(pi, args, ctx),
  });
  pi.registerCommand("custom-provider:remove-model", {
    description: "Remove a model from a custom provider",
    handler: (args, ctx) => removeModel(pi, args, ctx),
  });
}
