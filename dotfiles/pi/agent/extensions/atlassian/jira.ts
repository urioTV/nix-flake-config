/**
 * Narzędzia Jira.
 *
 * `jira_create_meta` jest sercem tej implementacji: bez niego agent nie wie,
 * które pola są wymagane na ekranie tworzenia danego projektu i dostaje 400.
 * Ekrany bywają nietypowe (np. wymagany `duedate` i `labels`), więc agent
 * MUSI najpierw odczytać schemat, a dopiero potem tworzyć zgłoszenie.
 */
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { Type } from "typebox";

import { toAdf } from "./adf.js";
import { apiGet, apiPost, apiPut, request } from "./client.js";

const anyRecord = Type.Record(Type.String(), Type.Any());
const stringArray = Type.Array(Type.String());

/* ── createmeta ─────────────────────────────────────────────────────────── */

export interface CreateMetaField {
  fieldId: string;
  name: string;
  required: boolean;
  schemaType?: string;
  schemaItems?: string;
  custom?: boolean;
  allowedValues?: unknown[];
  hasDefaultValue?: boolean;
}

/** Pojedyncze pole createmeta, zredukowane do rzeczy potrzebnych agentowi. */
function summarizeField(raw: unknown): CreateMetaField | undefined {
  if (typeof raw !== "object" || raw === null) return undefined;
  const f = raw as Record<string, unknown>;
  const fieldId = typeof f.fieldId === "string" ? f.fieldId : typeof f.key === "string" ? f.key : undefined;
  if (!fieldId) return undefined;

  const schema = (f.schema ?? {}) as Record<string, unknown>;
  const allowed = Array.isArray(f.allowedValues)
    ? f.allowedValues.map((v) => {
        if (typeof v !== "object" || v === null) return v;
        const r = v as Record<string, unknown>;
        // Priorytety i podobne mają `name`; niektóre pola `value`.
        return r.name ?? r.value ?? r.id ?? r.key ?? v;
      })
    : undefined;

  return {
    fieldId,
    name: typeof f.name === "string" ? f.name : fieldId,
    required: f.required === true,
    schemaType: typeof schema.type === "string" ? schema.type : undefined,
    schemaItems: typeof schema.items === "string" ? schema.items : undefined,
    custom: typeof schema.custom === "string" ? true : undefined,
    allowedValues: allowed?.length ? allowed : undefined,
    hasDefaultValue: f.hasDefaultValue === true ? true : undefined,
  };
}

interface CreateMetaProject {
  id: string;
  key: string;
  name: string;
  issueTypes: Array<{
    id: string;
    name: string;
    subtask: boolean;
    requiredFields: CreateMetaField[];
    optionalFields: CreateMetaField[];
  }>;
}

async function fetchCreateMeta(
  projectKeyOrId: string,
  issueTypeId: string | undefined,
  signal?: AbortSignal,
): Promise<CreateMetaProject> {
  if (issueTypeId) {
    const data = await apiGet<Record<string, unknown>>(
      `/rest/api/3/issue/createmeta/${encodeURIComponent(projectKeyOrId)}/issuetypes/${encodeURIComponent(issueTypeId)}`,
      { maxResults: 200 },
      signal,
    );
    const fields = (Array.isArray(data?.values) ? data.values : Array.isArray(data?.fields) ? data.fields : [])
      .map(summarizeField)
      .filter((x): x is CreateMetaField => x !== undefined);

    return {
      id: "",
      key: projectKeyOrId,
      name: projectKeyOrId,
      issueTypes: [
        {
          id: issueTypeId,
          name: issueTypeId,
          subtask: false,
          requiredFields: fields.filter((f) => f.required),
          optionalFields: fields.filter((f) => !f.required),
        },
      ],
    };
  }

  const data = await apiGet<Record<string, unknown>>(
    `/rest/api/3/issue/createmeta/${encodeURIComponent(projectKeyOrId)}/issuetypes`,
    { maxResults: 100 },
    signal,
  );
  const list = Array.isArray(data?.issueTypes) ? data.issueTypes : Array.isArray(data?.values) ? data.values : [];

  const issueTypes: CreateMetaProject["issueTypes"] = [];
  for (const entry of list) {
    if (typeof entry !== "object" || entry === null) continue;
    const t = entry as Record<string, unknown>;
    const id = typeof t.id === "string" ? t.id : undefined;
    if (!id) continue;

    // Lista typów nie zawiera pól — trzeba dopytać per typ.
    let requiredFields: CreateMetaField[] = [];
    let optionalFields: CreateMetaField[] = [];
    try {
      const detail = await fetchCreateMeta(projectKeyOrId, id, signal);
      requiredFields = detail.issueTypes[0]?.requiredFields ?? [];
      optionalFields = detail.issueTypes[0]?.optionalFields ?? [];
    } catch {
      // Brak uprawnień do metadanych jednego typu nie może wywalić całości.
    }

    issueTypes.push({
      id,
      name: typeof t.name === "string" ? t.name : id,
      subtask: t.subtask === true,
      requiredFields,
      optionalFields,
    });
  }

  const project = (data?.projects as unknown[])?.[0] as Record<string, unknown> | undefined;
  return {
    id: typeof project?.id === "string" ? project.id : "",
    key: typeof project?.key === "string" ? project.key : projectKeyOrId,
    name: typeof project?.name === "string" ? project.name : projectKeyOrId,
    issueTypes,
  };
}

/* ── rejestracja ────────────────────────────────────────────────────────── */

export function registerJiraTools(pi: ExtensionAPI): void {
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

  /* ── metadane tworzenia ─────────────────────────────────────────────── */

  tool(
    "jira_create_meta",
    "Get the create-screen metadata for a Jira project: which issue types exist and exactly which fields are REQUIRED to create each one. Call this BEFORE jira_create_issue, because required fields vary per project and per issue type.",
    Type.Object({
      projectKeyOrId: Type.String({ description: "Project key (e.g. IPCMC) or numeric id." }),
      issueTypeId: Type.Optional(
        Type.String({ description: "Narrow to one issue type id. Omit to get every type in the project." }),
      ),
    }),
    async (params, signal) => {
      const meta = await fetchCreateMeta(params.projectKeyOrId, params.issueTypeId, signal);

      const lines: string[] = [`Projekt ${meta.key}${meta.name !== meta.key ? ` (${meta.name})` : ""}`];
      for (const t of meta.issueTypes) {
        lines.push(`\n=== ${t.name} (id=${t.id}${t.subtask ? ", podzadanie" : ""})`);
        if (!t.requiredFields.length) {
          lines.push("  brak pól wymaganych");
        } else {
          lines.push(`  WYMAGANE (${t.requiredFields.length}):`);
          for (const f of t.requiredFields) {
            const allowed = f.allowedValues ? ` | dozwolone: ${f.allowedValues.slice(0, 10).join(", ")}` : "";
            lines.push(`    • ${f.name} → \`${f.fieldId}\` (${f.schemaType ?? "?"}${f.custom ? ", custom" : ""})${allowed}`);
          }
        }
        if (t.optionalFields.length) {
          lines.push(`  opcjonalne: ${t.optionalFields.map((f) => f.fieldId).join(", ")}`);
        }
      }

      return { ...meta, summary: lines.join("\n") };
    },
    {
      snippet: "Read required fields for creating a Jira issue in a project",
      guidelines: [
        "Use jira_create_meta before jira_create_issue to learn which fields are REQUIRED for that project and issue type.",
        "jira_create_meta returns one entry per issue type, each with requiredFields listing the exact fieldId values jira_create_issue must receive in `fields`.",
      ],
    },
  );

  /* ── wyszukiwanie i odczyt ──────────────────────────────────────────── */

  tool(
    "jira_search_issues",
    "Search Jira issues with JQL. Returns issues with the requested fields.",
    Type.Object({
      jql: Type.String({ description: "JQL query, e.g. 'project = IPCMC AND status != Done ORDER BY created DESC'." }),
      fields: Type.Optional(stringArray),
      expand: Type.Optional(stringArray),
      maxResults: Type.Optional(Type.Integer({ minimum: 1, maximum: 100 })),
      nextPageToken: Type.Optional(Type.String()),
      fieldsByKeys: Type.Optional(Type.Boolean()),
    }),
    (params, signal) =>
      apiPost(
        "/rest/api/3/search/jql",
        {
          jql: params.jql,
          fields: params.fields,
          expand: params.expand,
          maxResults: params.maxResults,
          nextPageToken: params.nextPageToken,
          fieldsByKeys: params.fieldsByKeys,
        },
        signal,
      ),
    { snippet: "Search Jira issues using JQL" },
  );

  tool(
    "jira_get_issue",
    "Get a single Jira issue by key or id.",
    Type.Object({
      issueIdOrKey: Type.String(),
      fields: Type.Optional(stringArray),
      expand: Type.Optional(stringArray),
      fieldsByKeys: Type.Optional(Type.Boolean()),
    }),
    (params, signal) =>
      apiGet(
        `/rest/api/3/issue/${encodeURIComponent(params.issueIdOrKey)}`,
        { fields: params.fields, expand: params.expand, fieldsByKeys: params.fieldsByKeys },
        signal,
      ),
  );

  tool(
    "jira_list_projects",
    "List Jira projects visible to the authenticated user.",
    Type.Object({
      query: Type.Optional(Type.String()),
      maxResults: Type.Optional(Type.Integer({ minimum: 1, maximum: 100 })),
      startAt: Type.Optional(Type.Integer({ minimum: 0 })),
      action: Type.Optional(Type.String()),
    }),
    (params, signal) => apiGet("/rest/api/3/project/search", params, signal),
    { snippet: "List Jira projects" },
  );

  tool(
    "jira_search_issues_by_project",
    "List issues from one project. Convenience wrapper over jira_search_issues.",
    Type.Object({
      projectKeyOrId: Type.String(),
      fields: Type.Optional(stringArray),
      maxResults: Type.Optional(Type.Integer({ minimum: 1, maximum: 100 })),
      nextPageToken: Type.Optional(Type.String()),
    }),
    (params, signal) =>
      apiPost(
        "/rest/api/3/search/jql",
        {
          jql: `project = "${params.projectKeyOrId.replace(/"/g, '\\"')}" ORDER BY created DESC`,
          fields: params.fields,
          maxResults: params.maxResults,
          nextPageToken: params.nextPageToken,
        },
        signal,
      ),
  );

  tool(
    "jira_get_user_profile",
    "Get a single Jira user profile by accountId. NOTE: Jira Cloud requires accountId — the legacy username and key parameters are rejected with HTTP 400. To find someone by name or email, use jira_search_users first and take the accountId from the result.",
    Type.Object({
      accountId: Type.String({ description: "Atlassian accountId (e.g. from jira_search_users or jira_get_assignable_users)." }),
    }),
    (params, signal) => apiGet("/rest/api/3/user", params, signal),
  );

  tool(
    "jira_search_users",
    "Find Jira users by display name or email address. Returns accountId values — use one with jira_update_issue (`fields.assignee.accountId`) to assign an issue. Use this instead of jira_get_user_profile when you only know a person's name.",
    Type.Object({
      query: Type.String({ description: "Display name or email fragment, e.g. 'Lemański' or 'lemanski@gumed.edu.pl'." }),
      maxResults: Type.Optional(Type.Integer({ minimum: 1, maximum: 1000 })),
      startAt: Type.Optional(Type.Integer({ minimum: 0 })),
    }),
    (params, signal) => apiGet("/rest/api/3/user/search", params, signal),
    {
      snippet: "Find a Jira user's accountId by name or email",
      guidelines: [
        "Use jira_search_users to obtain an accountId before assigning an issue; jira_get_user_profile requires an accountId and cannot search by name.",
      ],
    },
  );

  tool(
    "jira_get_assignable_users",
    "List the users who can be assigned issues in a project (or on a specific issue). Returns accountId values suitable for jira_update_issue.",
    Type.Object({
      project: Type.Optional(Type.String({ description: "Project key, e.g. IPCMC." })),
      issueKey: Type.Optional(Type.String({ description: "Restrict to users assignable on this specific issue." })),
      query: Type.Optional(Type.String()),
      maxResults: Type.Optional(Type.Integer({ minimum: 1, maximum: 1000 })),
    }),
    (params, signal) =>
      apiGet("/rest/api/3/user/assignable/search", {
        project: params.project,
        issueKey: params.issueKey,
        query: params.query,
        maxResults: params.maxResults,
      }, signal),
    {
      snippet: "List users assignable in a Jira project",
      guidelines: [
        "Use jira_get_assignable_users to check who may be assigned before setting an assignee on a Jira issue.",
      ],
    },
  );

  tool(
    "jira_get_edit_meta",
    "Get the edit-screen metadata for an existing issue: which fields are editable for THAT issue right now, which are required, and what values each accepts. The editable field set depends on the issue type and status, so check this before editing. jira_update_issue only sends the fields you name; jira_get_edit_meta tells you which names are valid.",
    Type.Object({
      issueIdOrKey: Type.String(),
      includeOptional: Type.Optional(
        Type.Boolean({ description: "Include optional (non-required) fields too. Defaults to true." }),
      ),
    }),
    async (params, signal) => {
      const data = await apiGet<Record<string, unknown>>(
        `/rest/api/3/issue/${encodeURIComponent(params.issueIdOrKey)}/editmeta`,
        {},
        signal,
      );

      const raw = (data?.fields ?? {}) as Record<string, unknown>;
      const fields = Object.entries(raw)
        .map(([id, value]) => {
          const summary = summarizeField({ fieldId: id, ...(value as Record<string, unknown>) });
          if (!summary) return undefined;
          const required = (value as Record<string, unknown>).required === true;
          return { ...summary, fieldId: id, required };
        })
        .filter((x): x is CreateMetaField => x !== undefined);

      const requiredFields = fields.filter((f) => f.required);
      const optionalFields = fields.filter((f) => !f.required);
      const shown = params.includeOptional === false ? requiredFields : fields;

      const lines = [`Pola edytowalne dla ${params.issueIdOrKey} (${fields.length}):`];
      for (const f of shown) {
        const allowed = f.allowedValues ? ` | dozwolone: ${f.allowedValues.slice(0, 10).join(", ")}` : "";
        lines.push(
          `  ${f.required ? "[WYMAGANE]" : "          "} ${f.name} → \`${f.fieldId}\` (${f.schemaType ?? "?"}${f.custom ? ", custom" : ""})${allowed}`,
        );
      }
      if (!shown.length) lines.push("  brak pol " + (params.includeOptional === false ? "wymaganych" : "edytowalnych"));

      return { issueIdOrKey: params.issueIdOrKey, requiredFields, optionalFields, summary: lines.join("\n") };
    },
    {
      snippet: "Read which fields are editable on an existing Jira issue",
      guidelines: [
        "Use jira_get_edit_meta before jira_update_issue to learn which fields are editable for that issue and what values they accept.",
      ],
    },
  );

  tool(
    "jira_search_fields",
    "Search the global Jira field catalog (all custom fields, by id/name/type). To learn which fields are REQUIRED for a project, use jira_create_meta instead.",
    Type.Object({
      query: Type.Optional(Type.String()),
      type: Type.Optional(Type.String()),
      id: Type.Optional(stringArray),
      maxResults: Type.Optional(Type.Integer({ minimum: 1 })),
      startAt: Type.Optional(Type.Integer({ minimum: 0 })),
    }),
    (params, signal) => apiGet("/rest/api/3/field/search", params, signal),
  );

  /* ── tworzenie i edycja ─────────────────────────────────────────────── */

  tool(
    "jira_create_issue",
    "Create a Jira issue. IMPORTANT: call jira_create_meta first for this project to learn the required fields — screens are often custom and the API rejects the request with 400 when a required field is missing. Put every field (standard or custom) in `fields`.",
    Type.Object({
      projectKey: Type.Optional(Type.String()),
      projectId: Type.Optional(Type.Union([Type.String(), Type.Integer()])),
      issueTypeName: Type.Optional(Type.String()),
      issueTypeId: Type.Optional(Type.String()),
      summary: Type.Optional(Type.String()),
      description: Type.Optional(Type.Any()),
      fields: Type.Optional(anyRecord),
      update: Type.Optional(anyRecord),
    }),
    async (params, signal) => {
      const fields: Record<string, unknown> = { ...(params.fields ?? {}) };

      if (params.projectId !== undefined) fields.project = { id: String(params.projectId) };
      else if (params.projectKey) fields.project = { key: params.projectKey };

      if (params.issueTypeId) fields.issuetype = { id: params.issueTypeId };
      else if (params.issueTypeName) fields.issuetype = { name: params.issueTypeName };

      if (params.summary !== undefined) fields.summary = params.summary;
      if (params.description !== undefined) fields.description = toAdf(params.description);

      if (!fields.project) throw new Error("jira_create_issue: wymagane projectKey albo projectId.");
      if (!fields.issuetype) throw new Error("jira_create_issue: wymagane issueTypeName albo issueTypeId.");
      if (!fields.summary) throw new Error("jira_create_issue: wymagane summary.");

      const body: Record<string, unknown> = { fields };
      if (params.update !== undefined) body.update = params.update;
      return apiPost("/rest/api/3/issue", body, signal);
    },
    {
      snippet: "Create a Jira issue",
      guidelines: [
        "Use jira_create_meta before jira_create_issue so the request carries every field the project's create screen marks as required.",
      ],
    },
  );

  tool(
    "jira_batch_create_issues",
    "Create several Jira issues in one request. Each entry takes the same arguments as jira_create_issue. Call jira_create_meta first.",
    Type.Object({
      issues: Type.Array(anyRecord, { minItems: 1, maxItems: 50 }),
    }),
    async (params, signal) => {
      const issueUpdates = (params.issues as Array<Record<string, unknown>>).map((raw) => {
        const fields: Record<string, unknown> = { ...((raw.fields as Record<string, unknown>) ?? {}) };
        if (raw.projectId !== undefined) fields.project = { id: String(raw.projectId) };
        else if (raw.projectKey) fields.project = { key: raw.projectKey };
        if (raw.issueTypeId) fields.issuetype = { id: raw.issueTypeId };
        else if (raw.issueTypeName) fields.issuetype = { name: raw.issueTypeName };
        if (raw.summary !== undefined) fields.summary = raw.summary;
        if (raw.description !== undefined) fields.description = toAdf(raw.description);
        return raw.update === undefined ? { fields } : { fields, update: raw.update };
      });
      return apiPost("/rest/api/3/issue/bulk", { issueUpdates }, signal);
    },
  );

  tool(
    "jira_update_issue",
    "Update fields on an existing Jira issue.",
    Type.Object({
      issueIdOrKey: Type.String(),
      summary: Type.Optional(Type.String()),
      description: Type.Optional(Type.Any()),
      fields: Type.Optional(anyRecord),
      update: Type.Optional(anyRecord),
      notifyUsers: Type.Optional(Type.Boolean()),
    }),
    async (params, signal) => {
      const fields: Record<string, unknown> = { ...(params.fields ?? {}) };
      if (params.summary !== undefined) fields.summary = params.summary;
      if (params.description !== undefined) fields.description = toAdf(params.description);

      const body: Record<string, unknown> = {};
      if (Object.keys(fields).length) body.fields = fields;
      if (params.update !== undefined) body.update = params.update;

      return apiPut(
        `/rest/api/3/issue/${encodeURIComponent(params.issueIdOrKey)}`,
        body,
        signal,
      );
    },
  );

  tool(
    "jira_delete_issue",
    "Permanently delete a Jira issue. This cannot be undone. Set deleteSubtasks=true to delete a parent issue together with its subtasks (otherwise the request fails when subtasks exist).",
    Type.Object({
      issueIdOrKey: Type.String(),
      deleteSubtasks: Type.Optional(
        Type.Boolean({ description: "Delete the issue's subtasks as well. Required when the issue has subtasks." }),
      ),
    }),
    async (params, signal) => {
      await request(`/rest/api/3/issue/${encodeURIComponent(params.issueIdOrKey)}`, {
        method: "DELETE",
        query: { deleteSubtasks: params.deleteSubtasks },
        signal,
      });
      return `Usunięto ${params.issueIdOrKey}.`;
    },
    {
      snippet: "Delete a Jira issue permanently",
      guidelines: [
        "jira_delete_issue permanently deletes a Jira issue and cannot be undone — confirm the exact issue key with the user first.",
      ],
    },
  );

  /* ── komentarze i przejścia ─────────────────────────────────────────── */

  tool(
    "jira_add_comment",
    "Add a comment to a Jira issue.",
    Type.Object({
      issueIdOrKey: Type.String(),
      body: Type.Any({ description: "Comment text, or an ADF document." }),
      visibility: Type.Optional(anyRecord),
    }),
    (params, signal) =>
      apiPost(
        `/rest/api/3/issue/${encodeURIComponent(params.issueIdOrKey)}/comment`,
        { body: toAdf(params.body), visibility: params.visibility },
        signal,
      ),
  );

  tool(
    "jira_get_transitions",
    "List the workflow transitions available for a Jira issue, with their ids.",
    Type.Object({ issueIdOrKey: Type.String() }),
    (params, signal) => apiGet(`/rest/api/3/issue/${encodeURIComponent(params.issueIdOrKey)}/transitions`, {}, signal),
    { snippet: "List available workflow transitions for a Jira issue" },
  );

  tool(
    "jira_transition_issue",
    "Move a Jira issue to another status. Get the transition id from jira_get_transitions first.",
    Type.Object({
      issueIdOrKey: Type.String(),
      transitionId: Type.String(),
      fields: Type.Optional(anyRecord),
      update: Type.Optional(anyRecord),
      comment: Type.Optional(Type.Any()),
    }),
    async (params, signal) => {
      const body: Record<string, unknown> = { transition: { id: params.transitionId } };
      if (params.fields !== undefined) body.fields = params.fields;
      if (params.update !== undefined) body.update = params.update;
      if (params.comment !== undefined) {
        const existing = (params.update as Record<string, unknown> | undefined) ?? {};
        const comments = Array.isArray(existing.comment) ? existing.comment : [];
        body.update = { ...existing, comment: [...comments, { add: { body: toAdf(params.comment) } }] };
      }
      return apiPost(`/rest/api/3/issue/${encodeURIComponent(params.issueIdOrKey)}/transitions`, body, signal);
    },
    {
      snippet: "Transition a Jira issue to a new status",
      guidelines: ["Use jira_get_transitions before jira_transition_issue to obtain the valid transition id."],
    },
  );

  tool(
    "jira_get_issue_link_types",
    "List the Jira issue link types (e.g. Blocks, Relates).",
    Type.Object({}),
    (_params, signal) => apiGet("/rest/api/3/issueLinkType", {}, signal),
  );

  /* ── Agile: tablice, sprinty, backlog ───────────────────────────────── */

  tool(
    "jira_get_agile_boards",
    "List Jira Software Agile boards (scrum/kanban). Use the returned board id with the sprint and backlog tools.",
    Type.Object({
      name: Type.Optional(Type.String()),
      projectKeyOrId: Type.Optional(Type.String()),
      type: Type.Optional(Type.Union([Type.Literal("scrum"), Type.Literal("kanban"), Type.Literal("simple")])),
      maxResults: Type.Optional(Type.Integer({ minimum: 1, maximum: 50 })),
      startAt: Type.Optional(Type.Integer({ minimum: 0 })),
    }),
    (params, signal) => apiGet("/rest/agile/1.0/board", params, signal),
    {
      snippet: "List Jira Agile boards",
      guidelines: [
        "Use jira_get_agile_boards to obtain a board id, then jira_get_sprints_from_board and jira_get_board_issues with that id.",
      ],
    },
  );

  tool(
    "jira_get_sprints_from_board",
    "List the sprints of an Agile board, optionally filtered by state.",
    Type.Object({
      boardId: Type.Integer(),
      state: Type.Optional(
        Type.Array(Type.Union([Type.Literal("future"), Type.Literal("active"), Type.Literal("closed")])),
      ),
      maxResults: Type.Optional(Type.Integer({ minimum: 1, maximum: 50 })),
      startAt: Type.Optional(Type.Integer({ minimum: 0 })),
    }),
    (params, signal) => {
      const { boardId, ...query } = params;
      return apiGet(`/rest/agile/1.0/board/${encodeURIComponent(boardId)}/sprint`, query, signal);
    },
    { snippet: "List sprints from a Jira Agile board" },
  );

  tool(
    "jira_get_board_issues",
    "List the issues on an Agile board, with optional JQL narrowing.",
    Type.Object({
      boardId: Type.Integer(),
      jql: Type.Optional(Type.String()),
      fields: Type.Optional(stringArray),
      maxResults: Type.Optional(Type.Integer({ minimum: 1, maximum: 100 })),
      startAt: Type.Optional(Type.Integer({ minimum: 0 })),
    }),
    (params, signal) => {
      const { boardId, ...query } = params;
      return apiGet(`/rest/agile/1.0/board/${encodeURIComponent(boardId)}/issue`, query, signal);
    },
    { snippet: "List issues on a Jira Agile board" },
  );
}

export { fetchCreateMeta };
