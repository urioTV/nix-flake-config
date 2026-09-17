/**
 * Wczytywanie konfiguracji Atlassian.
 *
 * Kolejność źródeł (pierwsze wygrywa):
 *   1. Zmienne środowiskowe ATLASSIAN_*
 *   2. Plik JSON wskazany przez ATLASSIAN_CONFIG
 *   3. ~/.pi/sf/atlassian/config.json  (albo $PI_CODING_AGENT_DIR/sf/atlassian/config.json)
 *
 * Sekret nigdy nie jest logowany ani zwracany w komunikatach błędów.
 */
import { existsSync, readFileSync } from "node:fs";
import { homedir } from "node:os";
import { join } from "node:path";

export interface AtlassianConfig {
  baseUrl: string;
  email: string;
  apiToken: string;
  /**
   * Token Tempo (Bearer). Osobny od tokenu Atlassian — Tempo to inny produkt
   * i inny host (`api.tempo.io`). Opcjonalny: brak nie blokuje Jiry/Confluence.
   */
  tempoToken?: string;
}

/** Zmienne środowiskowe rozpoznawane dla każdego pola (pierwsza niepusta wygrywa). */
const ENV_KEYS = {
  baseUrl: ["ATLASSIAN_BASE_URL", "ATLASSIAN_DOMAIN"],
  email: ["ATLASSIAN_EMAIL", "ATLASSIAN_USERNAME"],
  apiToken: ["ATLASSIAN_API_TOKEN", "ATLASSIAN_PASSWORD"],
  tempoToken: ["TEMPO_API_TOKEN", "TEMPO_TOKEN", "ATLASSIAN_TEMPO_TOKEN"],
} as const;

function firstEnv(names: readonly string[]): string | undefined {
  for (const name of names) {
    const value = process.env[name]?.trim();
    if (value) return value;
  }
  return undefined;
}

function agentDir(): string {
  return process.env.PI_CODING_AGENT_DIR?.trim() || join(homedir(), ".pi", "agent");
}

/** Ścieżki plików konfiguracji sprawdzane po kolei. */
export function configPaths(): string[] {
  const explicit = process.env.ATLASSIAN_CONFIG?.trim();
  if (explicit) return [explicit];

  const agent = agentDir();
  return [
    // Obecny format: ~/.pi/sf/atlassian/config.json
    join(agent, "sf", "atlassian", "config.json"),
    // Historyczne położenie (katalog agenta = ~/.pi), zachowane dla zgodności.
    join(agent, "..", "sf", "atlassian", "config.json"),
  ];
}

function readFileConfig(): Partial<AtlassianConfig> | undefined {
  for (const path of configPaths()) {
    try {
      if (!existsSync(path)) continue;
      const raw: unknown = JSON.parse(readFileSync(path, "utf8"));
      if (typeof raw !== "object" || raw === null) continue;
      const record = raw as Record<string, unknown>;

      const baseUrl = record.baseUrl ?? record.domain;
      return {
        baseUrl: typeof baseUrl === "string" ? baseUrl : undefined,
        email: typeof record.email === "string" ? record.email : undefined,
        apiToken: typeof record.apiToken === "string" ? record.apiToken : undefined,
        tempoToken: typeof record.tempoToken === "string" ? record.tempoToken : undefined,
      };
    } catch {
      // Nieczytelny plik nie może wywalić całego rozszerzenia — próbujemy następny.
      continue;
    }
  }
  return undefined;
}

/** Normalizuje bazowy URL: dokłada https:// gdy brak schematu, ucina końcowe ukośniki. */
export function normalizeBaseUrl(value: string): string {
  const trimmed = value.trim().replace(/\/+$/, "");
  return /^https?:\/\//i.test(trimmed) ? trimmed : `https://${trimmed}`;
}

let cached: AtlassianConfig | undefined;

export function loadConfig(): AtlassianConfig {
  if (cached) return cached;

  const fromFile = readFileConfig() ?? {};

  const baseUrl = firstEnv(ENV_KEYS.baseUrl) ?? fromFile.baseUrl;
  const email = firstEnv(ENV_KEYS.email) ?? fromFile.email;
  const apiToken = firstEnv(ENV_KEYS.apiToken) ?? fromFile.apiToken;

  const missing: string[] = [];
  if (!baseUrl) missing.push("ATLASSIAN_BASE_URL (lub ATLASSIAN_DOMAIN)");
  if (!email) missing.push("ATLASSIAN_EMAIL");
  if (!apiToken) missing.push("ATLASSIAN_API_TOKEN");

  if (missing.length) {
    throw new Error(
      `Brak konfiguracji Atlassian. Ustaw: ${missing.join(", ")} ` +
        `albo utwórz plik ${configPaths()[0]} z polami baseUrl, email, apiToken.`,
    );
  }

  cached = {
    baseUrl: normalizeBaseUrl(baseUrl as string),
    email: email as string,
    apiToken: apiToken as string,
    tempoToken: firstEnv(ENV_KEYS.tempoToken) ?? fromFile.tempoToken,
  };
  return cached;
}

/**
 * Token Tempo, wymagany dopiero przy użyciu narzędzi Tempo.
 *
 * Celowo nie jest częścią sprawdzenia `missing` w {@link loadConfig}: brak
 * tokenu Tempo nie może wyłączyć narzędzi Jira i Confluence.
 */
export function loadTempoToken(): string {
  const config = loadConfig();
  if (!config.tempoToken) {
    throw new Error(
      "Brak tokenu Tempo. Wygeneruj go w Tempo: Settings → Data Access → API Integration → New Token, " +
        `potem dopisz pole "tempoToken" do ${configPaths()[0]} (albo ustaw TEMPO_API_TOKEN).`,
    );
  }
  return config.tempoToken;
}

/** Nagłówek Basic auth. Trzymany osobno, żeby nigdy nie trafił do logów. */
export function authHeader(config: AtlassianConfig): string {
  return `Basic ${Buffer.from(`${config.email}:${config.apiToken}`).toString("base64")}`;
}

export function resetConfigCache(): void {
  cached = undefined;
}
