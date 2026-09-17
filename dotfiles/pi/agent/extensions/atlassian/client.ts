/**
 * Klient HTTP dla Jira i Confluence.
 *
 * Kluczowa różnica względem oryginalnego pluginu: ciało odpowiedzi błędu JEST
 * przekazywane do wiadomości. Jira w 400 zwraca `{"errorMessages":[...],"errors":{...}}`
 * — bez tego agent nie wie, którego pola brakuje i zgaduje (a Jira odrzuca).
 */
import { authHeader, loadConfig } from "./config.js";

export interface RequestOptions {
  method?: string;
  body?: unknown;
  query?: Record<string, unknown>;
  signal?: AbortSignal;
}

/** Maksymalna długość ciała błędu dołączanego do komunikatu. */
const MAX_ERROR_BODY = 2000;

export class AtlassianError extends Error {
  constructor(
    message: string,
    readonly status: number,
    readonly method: string,
    readonly path: string,
    readonly body: string,
  ) {
    super(message);
    this.name = "AtlassianError";
  }
}

/** Usuwa `undefined` z obiektu; `null` zostaje (Jira czasem wymaga jawnego null). */
function clean(value: Record<string, unknown>): Record<string, unknown> {
  return Object.fromEntries(Object.entries(value).filter(([, v]) => v !== undefined));
}

/**
 * Serializuje ciało błędu do czytelnej postaci.
 *
 * Atlassian używa trzech różnych formatów i wszystkie muszą być obsłużone,
 * inaczej agent dostaje surowy JSON zamiast powodu odmowy:
 *
 *   Jira          {"errorMessages":["..."],"errors":{"field":"..."}}
 *   Confluence v1 {"message":"...","statusCode":403}
 *   Confluence v2 {"errors":[{"status":404,"code":"...","title":"..."}]}
 */
export function formatErrorBody(raw: string): string {
  if (!raw) return "";
  try {
    const parsed: unknown = JSON.parse(raw);
    if (typeof parsed === "object" && parsed !== null) {
      const record = parsed as Record<string, unknown>;
      const lines: string[] = [];

      // `errors` jest w Jirze mapą fieldId → komunikat, a w Confluence v2
      // tablicą obiektów {status, code, title, detail}.
      const errors = record.errors;
      const errorValues: string[] = [];

      if (Array.isArray(errors)) {
        for (const entry of errors) {
          if (typeof entry !== "object" || entry === null) {
            if (typeof entry === "string" && entry) lines.push(entry);
            continue;
          }
          const e = entry as Record<string, unknown>;
          const text = [e.title, e.detail, e.message, e.code]
            .filter((v): v is string => typeof v === "string" && v.length > 0)
            .join(": ");
          const withStatus = text && e.status !== undefined ? `${e.status} ${text}` : text;
          if (withStatus) lines.push(withStatus);
        }
      } else if (typeof errors === "object" && errors !== null) {
        for (const [field, msg] of Object.entries(errors as Record<string, unknown>)) {
          if (typeof msg !== "string" || !msg) continue;
          errorValues.push(msg);
          lines.push(`${field}: ${msg}`);
        }
      }

      // Confluence v1 używa pojedynczego `message`.
      if (typeof record.message === "string" && record.message) lines.push(record.message);

      // `errorMessages` powtarza zwykle te same treści bez klucza pola, więc
      // dodajemy tylko te, których wcześniejsze sekcje jeszcze nie pokryły.
      const messages = record.errorMessages;
      if (Array.isArray(messages)) {
        for (const m of messages) {
          if (typeof m !== "string" || !m) continue;
          const alreadyCovered =
            errorValues.some((value) => m === value || m.endsWith(value) || m.endsWith(`: ${value}`)) ||
            lines.includes(m);
          if (!alreadyCovered) lines.push(m);
        }
      }

      if (lines.length) return lines.join("; ");
    }
  } catch {
    // Nie-JSON — zwracamy surowy tekst.
  }
  return raw.length > MAX_ERROR_BODY ? `${raw.slice(0, MAX_ERROR_BODY)}...` : raw;
}

function buildUrl(baseUrl: string, path: string, query?: Record<string, unknown>): string {
  const url = new URL(`${path.startsWith("/") ? "" : "/"}${path}`, baseUrl);
  for (const [key, value] of Object.entries(query ?? {})) {
    if (value === undefined || value === null || value === "") continue;
    if (Array.isArray(value)) {
      for (const item of value) url.searchParams.append(key, String(item));
      continue;
    }
    url.searchParams.set(key, String(value));
  }
  return url.toString();
}

/** Wykonuje żądanie i zwraca sparsowany JSON (albo undefined dla pustego ciała). */
export async function request<T = unknown>(path: string, options: RequestOptions = {}): Promise<T> {
  const config = loadConfig();
  const method = options.method ?? "GET";
  const url = buildUrl(config.baseUrl, path, options.query);

  const headers: Record<string, string> = {
    Authorization: authHeader(config),
    Accept: "application/json",
  };

  const init: RequestInit = { method, headers, signal: options.signal };
  if (options.body !== undefined) {
    headers["Content-Type"] = "application/json";
    init.body = JSON.stringify(options.body);
  }

  const response = await fetch(url, init);

  if (!response.ok) {
    const raw = await response.text().catch(() => "");
    const detail = formatErrorBody(raw);
    throw new AtlassianError(
      `Atlassian API ${response.status} ${response.statusText} dla ${method} ${path}` +
        (detail ? `\n→ ${detail}` : ""),
      response.status,
      method,
      path,
      raw,
    );
  }

  const text = await response.text();
  if (!text) return undefined as T;
  try {
    return JSON.parse(text) as T;
  } catch {
    return text as unknown as T;
  }
}

export const apiGet = <T = unknown>(path: string, query?: Record<string, unknown>, signal?: AbortSignal) =>
  request<T>(path, { query, signal });

export const apiPost = <T = unknown>(path: string, body?: unknown, signal?: AbortSignal) =>
  request<T>(path, { method: "POST", body: body === undefined ? undefined : clean(body as Record<string, unknown>), signal });

export const apiPut = <T = unknown>(path: string, body?: unknown, signal?: AbortSignal) =>
  request<T>(path, { method: "PUT", body: body === undefined ? undefined : clean(body as Record<string, unknown>), signal });

export { clean };
