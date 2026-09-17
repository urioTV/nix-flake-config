/**
 * Narzędzia Tempo (Timesheets) — logowanie własnego czasu pracy.
 *
 * Tempo to OSOBNY produkt, nie część Jiry:
 *   - inny host:  https://api.tempo.io/4   (nie `<domena>.atlassian.net`)
 *   - inna auth:  `Bearer <token Tempo>`   (nie `Basic email+token`)
 *
 * Token Tempo jest unikalny dla instancji i NIE jest tym samym co token
 * Atlassian — próba użycia tokenu Atlassian kończy się `401` (sprawdzone
 * empirycznie dla wszystkich trzech wariantów: brak, Basic, Bearer).
 * Generuje się go w Tempo: Settings → Data Access → API Integration.
 *
 * Dwie pułapki API, które ten moduł obsługuje za agenta:
 *   1. `issueId` musi być NUMERYCZNY — klucz `IPCMC-123` daje 400.
 *      Rozwiązywaniem zajmuje się {@link resolveIssueId}.
 *   2. `startDate` to data kalendarzowa, nie znacznik czasu. Liczona w czasie
 *      LOKALNYM — liczenie w UTC przesuwa wpis o dzień w okolicach północy,
 *      a te wpisy trafiają do raportów kierownictwa.
 */
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { Type } from "typebox";

import { apiGet, clean, formatErrorBody } from "./client.js";
import { loadTempoToken } from "./config.js";

/** Bazowy URL Tempo REST API v4. */
const TEMPO_BASE = "https://api.tempo.io/4";

/** Maksymalna długość ciała błędu dołączanego do komunikatu. */
const MAX_ERROR_BODY = 2000;

export class TempoError extends Error {
  constructor(
    message: string,
    readonly status: number,
    readonly method: string,
    readonly path: string,
    readonly body: string,
  ) {
    super(message);
    this.name = "TempoError";
  }
}

/* ── transport ──────────────────────────────────────────────────────────── */

interface TempoRequestOptions {
  method?: string;
  query?: Record<string, unknown>;
  body?: unknown;
  signal?: AbortSignal;
}

/**
 * Żądanie do Tempo. Analogiczne do `request()` z `client.ts`, ale z nagłówkiem
 * Bearer i innym hostem — dlatego osobna funkcja, a nie parametr w tamtej.
 */
async function tempoRequest<T = unknown>(path: string, options: TempoRequestOptions = {}): Promise<T> {
  const method = options.method ?? "GET";
  const url = new URL(`${TEMPO_BASE}${path.startsWith("/") ? path : `/${path}`}`);

  for (const [key, value] of Object.entries(options.query ?? {})) {
    if (value === undefined || value === null || value === "") continue;
    if (Array.isArray(value)) {
      for (const item of value) url.searchParams.append(key, String(item));
      continue;
    }
    url.searchParams.set(key, String(value));
  }

  const headers: Record<string, string> = {
    Authorization: `Bearer ${loadTempoToken()}`,
    Accept: "application/json",
  };

  const init: RequestInit = { method, headers, signal: options.signal };
  if (options.body !== undefined) {
    headers["Content-Type"] = "application/json";
    init.body = JSON.stringify(clean(options.body as Record<string, unknown>));
  }

  const response = await fetch(url, init);

  if (!response.ok) {
    const raw = await response.text().catch(() => "");
    const detail = formatErrorBody(raw);
    throw new TempoError(
      `Tempo API ${response.status} ${response.statusText} dla ${method} ${path}` + (detail ? `\n→ ${detail}` : ""),
      response.status,
      method,
      path,
      raw.length > MAX_ERROR_BODY ? `${raw.slice(0, MAX_ERROR_BODY)}...` : raw,
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

/* ── pomocnicze ─────────────────────────────────────────────────────────── */

const DATE_RE = /^\d{4}-\d{2}-\d{2}$/;

/** Dzisiejsza data w czasie LOKALNYM. UTC przesunęłoby wpis o dzień. */
function todayLocal(): string {
  const d = new Date();
  const p = (n: number) => String(n).padStart(2, "0");
  return `${d.getFullYear()}-${p(d.getMonth() + 1)}-${p(d.getDate())}`;
}

function requireDate(value: string | undefined, field: string): string {
  const date = value ?? todayLocal();
  if (!DATE_RE.test(date)) {
    throw new Error(`${field} musi mieć format RRRR-MM-DD (otrzymano "${date}").`);
  }
  return date;
}

/**
 * Godziny → sekundy, z walidacją.
 *
 * Górna granica 24 h jest celowa: wpisy zasilają raporty kierownictwa, więc
 * literówka rzędu `hours: 80` ma być zatrzymana, a nie zapisana.
 */
function hoursToSeconds(hours: number, field = "hours"): number {
  if (typeof hours !== "number" || !Number.isFinite(hours) || hours <= 0) {
    throw new Error(`${field} musi być liczbą większą od 0 (otrzymano ${hours}).`);
  }
  if (hours > 24) {
    throw new Error(
      `${field} = ${hours} przekracza 24 h na dobę. Sprawdź wartość — te wpisy trafiają do raportów kierownictwa.`,
    );
  }
  const seconds = Math.round(hours * 3600);
  if (seconds < 60) {
    throw new Error(
      `${field} = ${hours} h to ${seconds} s, a Tempo przyjmuje minimum 1 minutę ` +
        `("Duration must be at least one minute"). Podaj wartość odpowiadającą co najmniej 1 minucie.`,
    );
  }
  return seconds;
}

const TIME_RE = /^([01]\d|2[0-3]):([0-5]\d)(?::([0-5]\d))?$/;

/**
 * Godzina w formacie wymaganym przez Tempo.
 *
 * Tempo przyjmuje wyłącznie `HH:MM:SS` — `HH:MM` kończy się błędem
 * `400 "Non valid time '08:00': format must be HH:MM:SS"`. Przyjmujemy więc
 * oba warianty i dopełniamy sekundy, żeby agent nie musiał znać tego
 * wymagania. Wykryte empirycznie przy pierwszym realnym zapisie.
 */
function requireTime(value: string | undefined, field: string): string | undefined {
  if (value === undefined) return undefined;
  const m = TIME_RE.exec(value.trim());
  if (!m) {
    throw new Error(`${field} musi mieć format HH:MM albo HH:MM:SS (otrzymano "${value}").`);
  }
  return `${m[1]}:${m[2]}:${m[3] ?? "00"}`;
}

/**
 * Tempo wymaga NUMERYCZNEGO id zgłoszenia; klucz trzeba rozwiązać w Jirze.
 * Bez tego `tempo_create_worklog` z kluczem `IPCMC-123` kończy się 400.
 */
async function resolveIssueId(issue: string, signal?: AbortSignal): Promise<number> {
  const trimmed = issue.trim();
  if (/^\d+$/.test(trimmed)) return Number(trimmed);

  const data = await apiGet<{ id?: string }>(
    `/rest/api/3/issue/${encodeURIComponent(trimmed)}`,
    { fields: "id" },
    signal,
  );
  const id = Number(data?.id);
  if (!Number.isFinite(id)) {
    throw new Error(`Nie udało się ustalić numerycznego id dla zgłoszenia "${issue}".`);
  }
  return id;
}

let cachedAccountId: string | undefined;

/** accountId właściciela tokenu — Tempo wymaga go w `authorAccountId`. */
async function currentAccountId(signal?: AbortSignal): Promise<string> {
  if (cachedAccountId) return cachedAccountId;
  const me = await apiGet<{ accountId?: string }>("/rest/api/3/myself", {}, signal);
  if (!me?.accountId) {
    throw new Error("Nie udało się odczytać accountId z Jira /myself — sprawdź konfigurację Atlassian.");
  }
  cachedAccountId = me.accountId;
  return cachedAccountId;
}

/** Czyści cache tożsamości przy nowej sesji. */
export function resetTempoCache(): void {
  cachedAccountId = undefined;
}

export interface WorklogSummary {
  worklogId?: number;
  issueId?: number;
  date?: string;
  hours?: number;
  description?: string;
  startTime?: string;
  billableHours?: number;
  attributes?: string[];
}

interface RawWorklog {
  tempoWorklogId?: number;
  issue?: { id?: number };
  timeSpentSeconds?: number;
  billableSeconds?: number;
  startDate?: string;
  startTime?: string;
  description?: string;
  attributes?: { values?: Array<{ key?: string; value?: string }> };
}

/**
 * Redukuje worklog Tempo do pól istotnych dla agenta.
 * Sekundy przeliczamy na godziny — agent i użytkownik myślą w godzinach.
 */
function summarizeWorklog(raw: unknown): WorklogSummary {
  const w = (raw ?? {}) as RawWorklog;
  const values = w.attributes?.values;
  return {
    worklogId: w.tempoWorklogId,
    issueId: w.issue?.id,
    date: w.startDate,
    hours: typeof w.timeSpentSeconds === "number" ? w.timeSpentSeconds / 3600 : undefined,
    description: w.description,
    startTime: w.startTime,
    billableHours: typeof w.billableSeconds === "number" ? w.billableSeconds / 3600 : undefined,
    attributes: values?.length ? values.map((a) => `${a.key}=${a.value}`) : undefined,
  };
}

interface WorklogFilter {
  from: string;
  to: string;
  authorIds?: string[];
  issueIds?: string[];
  projectIds?: string[];
}

/**
 * Wyszukiwanie worklogów — `POST /worklogs/search`.
 *
 * Wybrane zamiast `GET /worklogs`, bo kontrakt tego pierwszego jest
 * potwierdzony w działających klientach (`from`/`to` w ciele, `offset`/`limit`
 * w query), a nie rekonstruowany z dokumentacji.
 */
async function findWorklogs(
  filter: WorklogFilter,
  signal?: AbortSignal,
  limit = 1000,
): Promise<WorklogSummary[]> {
  const data = await tempoRequest<{ results?: unknown[] }>("/worklogs/search", {
    method: "POST",
    query: { offset: 0, limit },
    body: filter,
    signal,
  });
  return (data?.results ?? []).map(summarizeWorklog);
}

/* ── narzędzia ──────────────────────────────────────────────────────────── */

export function registerTempoTools(pi: ExtensionAPI): void {
  const tool = (
    name: string,
    description: string,
    parameters: unknown,
    execute: (params: any, signal?: AbortSignal) => Promise<unknown>,
    options?: { snippet?: string; guidelines?: string[] },
  ): void => {
    pi.registerTool({
      name,
      label: name,
      description,
      promptSnippet: options?.snippet,
      promptGuidelines: options?.guidelines,
      parameters: parameters as never,
      async execute(_id: string, params: any, signal?: AbortSignal) {
        const result = await execute(params, signal);
        const text =
          result === undefined
            ? `${name}: wykonano.`
            : typeof result === "string"
              ? result
              : JSON.stringify(result, null, 2);
        return { content: [{ type: "text", text }], details: result ?? {} };
      },
    });
  };

  tool(
    "tempo_create_worklog",
    "Log work time on a Jira issue in Tempo. Use this to record how many hours were spent on a task on a given day. The Jira issue key is resolved to Tempo's numeric id automatically.",
    Type.Object({
      issue: Type.String({ description: "Jira issue key (e.g. IPCMC-123) or numeric id." }),
      hours: Type.Number({ description: "Hours worked, e.g. 1.5 or 3. Must be > 0 and <= 24." }),
      date: Type.Optional(
        Type.String({ description: "Work date as YYYY-MM-DD. Defaults to today in LOCAL time. Pass explicitly when logging a past day." }),
      ),
      description: Type.Optional(
        Type.String({ description: "What was done. This text feeds management reports — be specific." }),
      ),
      startTime: Type.Optional(
        Type.String({ description: "Optional start time. HH:MM or HH:MM:SS — seconds are filled in automatically." }),
      ),
      billableHours: Type.Optional(
        Type.Number({ description: "Optional billable hours, only if different from `hours`." }),
      ),
      attributes: Type.Optional(
        Type.Array(Type.Object({ key: Type.String(), value: Type.String() }), {
          description:
            "Tempo work attributes, e.g. an Account. Use tempo_list_work_attributes to discover valid keys.",
        }),
      ),
      allowDuplicate: Type.Optional(
        Type.Boolean({
          description:
            "Log even if an entry already exists for the same issue and day. Default false — the tool refuses rather than silently double-logging hours.",
        }),
      ),
    }),
    async (params, signal) => {
      const date = requireDate(params.date, "date");
      const timeSpentSeconds = hoursToSeconds(params.hours);
      const issueId = await resolveIssueId(params.issue, signal);
      const authorAccountId = await currentAccountId(signal);

      // Zabezpieczenie przed podwójnym zalogowaniem: ten sam dzień + to samo
      // zgłoszenie. Duplikat zawyża godziny w raportach, a wykrycie go po
      // fakcie jest trudne, bo Tempo nie oznacza takich wpisów.
      if (!params.allowDuplicate) {
        const existing = await findWorklogs(
          { from: date, to: date, issueIds: [String(issueId)], authorIds: [authorAccountId] },
          signal,
          50,
        );
        if (existing.length) {
          throw new Error(
            `NIE utworzono wpisu — dla ${params.issue} w dniu ${date} istnieje już ${existing.length} wpis(ów):\n` +
              existing
                .map(
                  (w) =>
                    `  • worklogId=${w.worklogId}  ${w.hours} h` +
                    (w.description ? `  — ${w.description}` : "") +
                    (w.startTime ? `  (od ${w.startTime})` : ""),
                )
                .join("\n") +
              `\nJeśli to pomyłka: tempo_update_worklog (popraw) albo tempo_delete_worklog (usuń).` +
              `\nJeśli to świadomie osobny wpis: powtórz z allowDuplicate=true.`,
          );
        }
      }

      const created = await tempoRequest("/worklogs", {
        method: "POST",
        body: {
          authorAccountId,
          issueId,
          startDate: date,
          timeSpentSeconds,
          attributes: params.attributes ?? [],
          billableSeconds: params.billableHours === undefined ? undefined : hoursToSeconds(params.billableHours, "billableHours"),
          description: params.description,
          startTime: requireTime(params.startTime, "startTime"),
        },
        signal,
      });

      return { created: summarizeWorklog(created) };
    },
    {
      snippet: "Log hours worked on a Jira issue in Tempo",
      guidelines: [
        "Use tempo_create_worklog to record time spent on a task; it refuses duplicate entries for the same issue and day unless allowDuplicate is true.",
        "Before logging a past day, check tempo_get_worklogs for that date first — it avoids both duplicates and gaps.",
      ],
    },
  );

  tool(
    "tempo_get_worklogs",
    "List Tempo worklogs for a date range, optionally filtered by issue or project. Use it to verify what is already logged — this is the reliable way to check a day is complete before adding entries.",
    Type.Object({
      from: Type.Optional(Type.String({ description: "Start date YYYY-MM-DD. Defaults to today (local time)." })),
      to: Type.Optional(Type.String({ description: "End date YYYY-MM-DD. Defaults to the same day as `from`." })),
      issue: Type.Optional(Type.String({ description: "Filter by a single Jira issue key or numeric id." })),
      projectId: Type.Optional(Type.String({ description: "Filter by Jira project id." })),
      onlyMine: Type.Optional(
        Type.Boolean({ description: "Limit to your own worklogs. Default true; set false to include the whole team." }),
      ),
      limit: Type.Optional(Type.Integer({ minimum: 1, maximum: 1000 })),
    }),
    async (params, signal) => {
      const from = requireDate(params.from, "from");
      const to = params.to ? requireDate(params.to, "to") : from;

      const issueIds = params.issue ? [String(await resolveIssueId(params.issue, signal))] : undefined;
      const authorIds = params.onlyMine === false ? undefined : [await currentAccountId(signal)];

      const worklogs = await findWorklogs(
        {
          from,
          to,
          issueIds,
          authorIds,
          projectIds: params.projectId ? [params.projectId] : undefined,
        },
        signal,
        params.limit ?? 100,
      );

      const totalHours = worklogs.reduce((sum, w) => sum + (w.hours ?? 0), 0);
      return { range: { from, to }, count: worklogs.length, totalHours, worklogs };
    },
    {
      snippet: "Read Tempo worklogs for a date range",
      guidelines: [
        "Use tempo_get_worklogs to check what is already logged for a day before adding hours.",
      ],
    },
  );

  tool(
    "tempo_update_worklog",
    "Correct an existing Tempo worklog — wrong hours, wrong date or wrong description. The issue cannot be changed; delete and recreate if the entry belongs to a different task.",
    Type.Object({
      worklogId: Type.Integer({ description: "Tempo worklog id, as returned by tempo_get_worklogs." }),
      date: Type.String({ description: "Work date YYYY-MM-DD." }),
      hours: Type.Number({ description: "Corrected hours, e.g. 1.5." }),
      description: Type.Optional(Type.String({ description: "Corrected description." })),
      startTime: Type.Optional(
        Type.String({ description: "Corrected start time. HH:MM or HH:MM:SS — seconds are filled in automatically." }),
      ),
      billableHours: Type.Optional(Type.Number({ description: "Corrected billable hours." })),
    }),
    async (params, signal) => {
      const updated = await tempoRequest(`/worklogs/${params.worklogId}`, {
        method: "PUT",
        body: {
          authorAccountId: await currentAccountId(signal),
          startDate: requireDate(params.date, "date"),
          timeSpentSeconds: hoursToSeconds(params.hours),
          billableSeconds: params.billableHours === undefined ? undefined : hoursToSeconds(params.billableHours, "billableHours"),
          description: params.description,
          startTime: requireTime(params.startTime, "startTime"),
        },
        signal,
      });
      return { updated: summarizeWorklog(updated) };
    },
  );

  tool(
    "tempo_delete_worklog",
    "Permanently delete a Tempo worklog. Cannot be undone — the hours disappear from management reports. Confirm the exact entry with the user before calling this.",
    Type.Object({
      worklogId: Type.Integer({ description: "Tempo worklog id, as returned by tempo_get_worklogs." }),
    }),
    async (params, signal) => {
      await tempoRequest(`/worklogs/${params.worklogId}`, { method: "DELETE", signal });
      return { deleted: params.worklogId };
    },
    {
      guidelines: [
        "tempo_delete_worklog is irreversible and affects reported hours — confirm the specific worklogId with the user first.",
      ],
    },
  );

  tool(
    "tempo_list_work_attributes",
    "List Tempo work attributes — the custom fields a worklog can carry, such as an Account. Use this when creating a worklog fails because a required attribute is missing.",
    Type.Object({}),
    async (_params, signal) =>
      tempoRequest("/work-attributes", { signal }),
    {
      guidelines: [
        "If tempo_create_worklog fails with a missing attribute, use tempo_list_work_attributes to discover valid keys, then pass them via `attributes`.",
      ],
    },
  );

  tool(
    "tempo_list_accounts",
    "List Tempo accounts. Needed when worklogs require an Account attribute — pass the account key through the `attributes` parameter of tempo_create_worklog.",
    Type.Object({}),
    async (_params, signal) =>
      tempoRequest("/accounts", { signal }),
  );
}
