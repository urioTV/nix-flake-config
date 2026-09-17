/**
 * Narzędzia Confluence.
 *
 * Zakres ograniczony do tego, czego realnie używano: wyszukiwanie, odczyt
 * strony oraz lista przestrzeni. Świadomie pominięto operacje zapisu — nie
 * były używane, a każda z nich wymagałaby własnej obsługi wersji i uprawnień.
 */
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { Type } from "typebox";

import { adfToText } from "./adf.js";
import { apiGet } from "./client.js";

interface RawPage {
  id?: string;
  title?: string;
  body?: { storage?: { value?: string }; atlas_doc_format?: { value?: string } };
  version?: { number?: number };
  spaceId?: string;
}

/** Wyciąga czytelne body z odpowiedzi Confluence, niezależnie od formatu. */
function extractBody(page: RawPage | undefined): string | undefined {
  const raw = page?.body?.storage?.value ?? page?.body?.atlas_doc_format?.value;
  if (!raw) return undefined;

  // atlas_doc_format to JSON ADF; storage to XHTML.
  if (page?.body?.atlas_doc_format?.value) {
    try {
      return adfToText(JSON.parse(raw));
    } catch {
      return raw;
    }
  }

  // Proste odchudzenie XHTML do tekstu — bez zewnętrznych zależności.
  return raw
    .replace(/<br\s*\/?>/gi, "\n")
    .replace(/<\/(p|div|li|h[1-6]|tr)>/gi, "\n")
    .replace(/<[^>]+>/g, "")
    .replace(/&nbsp;/g, " ")
    .replace(/&amp;/g, "&")
    .replace(/&lt;/g, "<")
    .replace(/&gt;/g, ">")
    .replace(/&quot;/g, '"')
    .replace(/\n{3,}/g, "\n\n")
    .trim();
}

export function registerConfluenceTools(pi: ExtensionAPI): void {
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
    "confluence_search",
    "Search Confluence content with CQL (Confluence Query Language).",
    Type.Object({
      cql: Type.String({ description: "CQL query, e.g. 'space = IPCMC AND title ~ \"raport\"'." }),
      limit: Type.Optional(Type.Integer({ minimum: 1, maximum: 100 })),
      start: Type.Optional(Type.Integer({ minimum: 0 })),
      expand: Type.Optional(Type.String()),
    }),
    (params, signal) => apiGet("/wiki/rest/api/search", params, signal),
    { snippet: "Search Confluence content using CQL" },
  );

  tool(
    "confluence_list_spaces",
    "List Confluence spaces visible to the authenticated user.",
    Type.Object({
      limit: Type.Optional(Type.Integer({ minimum: 1, maximum: 100 })),
      cursor: Type.Optional(Type.String()),
      keys: Type.Optional(Type.Array(Type.String())),
      ids: Type.Optional(Type.Array(Type.String())),
      status: Type.Optional(Type.Array(Type.String())),
    }),
    (params, signal) => apiGet("/wiki/api/v2/spaces", params, signal),
    { snippet: "List Confluence spaces" },
  );

  tool(
    "confluence_get_page",
    "Get a Confluence page by id, including its readable body text. Defaults to the storage format, which this tool converts to plain text.",
    Type.Object({
      pageId: Type.String(),
      bodyFormat: Type.Optional(
        Type.Union([Type.Literal("storage"), Type.Literal("atlas_doc_format"), Type.Literal("view")]),
      ),
      includeVersion: Type.Optional(Type.Boolean()),
    }),
    async (params, signal) => {
      const page = await apiGet<RawPage>(`/wiki/api/v2/pages/${encodeURIComponent(params.pageId)}`, {
        "body-format": params.bodyFormat ?? "storage",
      }, signal);

      const text = extractBody(page);
      const summary = [
        `# ${page?.title ?? "(bez tytułu)"}`,
        `id: ${page?.id ?? params.pageId}`,
        page?.version?.number !== undefined ? `wersja: ${page.version.number}` : undefined,
        "",
        text ?? "(brak treści)",
      ]
        .filter((line) => line !== undefined)
        .join("\n");

      return { page, summary };
    },
    {
      snippet: "Read a Confluence page by id",
      guidelines: [
        "Use confluence_get_page to read a page; its `summary` field already contains the page body converted to plain text.",
      ],
    },
  );

  tool(
    "confluence_search_user",
    "Search Confluence users (legacy v1 endpoint).",
    Type.Object({
      cql: Type.String(),
      limit: Type.Optional(Type.Integer({ minimum: 1 })),
      start: Type.Optional(Type.Integer({ minimum: 0 })),
    }),
    (params, signal) => apiGet("/wiki/rest/api/search/user", params, signal),
  );
}
