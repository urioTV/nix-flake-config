/**
 * Konwersja Atlassian Document Format (ADF) ↔ tekst.
 *
 * Jira REST v3 wymaga ADF dla pól rich-text (description, comment body).
 * Przyjmujemy zarówno zwykły string, jak i gotowy dokument ADF.
 */

export interface AdfNode {
  type: string;
  text?: string;
  attrs?: Record<string, unknown>;
  content?: AdfNode[];
  marks?: Array<{ type: string }>;
}

export interface AdfDoc {
  type: "doc";
  version: 1;
  content: AdfNode[];
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

function childContent(value: Record<string, unknown>): AdfNode[] {
  return Array.isArray(value.content) ? (value.content as AdfNode[]) : [];
}

function attrs(value: Record<string, unknown>): Record<string, unknown> {
  return isRecord(value.attrs) ? value.attrs : {};
}

/** Zamienia tekst (z podziałem na akapity i twarde łamania) na dokument ADF. */
export function textToAdf(value: string): AdfDoc {
  const paragraphs = value
    .split(/\n{2,}/)
    .map((p) => p.trim())
    .filter(Boolean);

  return {
    type: "doc",
    version: 1,
    content: (paragraphs.length ? paragraphs : [""]).map((paragraph) => ({
      type: "paragraph",
      content: paragraphToContent(paragraph),
    })),
  };
}

function paragraphToContent(value: string): AdfNode[] {
  const nodes: AdfNode[] = [];
  for (const [index, line] of value.split("\n").entries()) {
    if (index > 0) nodes.push({ type: "hardBreak" });
    if (line) nodes.push({ type: "text", text: line });
  }
  return nodes;
}

/** Przyjmuje string (konwertuje) albo gotowy ADF (przepuszcza bez zmian). */
export function toAdf(value: string | unknown): unknown {
  return typeof value === "string" ? textToAdf(value) : value;
}

/** Spłaszcza ADF do czytelnego tekstu — używane przy prezentacji wyników. */
export function adfToText(value: unknown): string {
  return render(value).replace(/\n{3,}/g, "\n\n").trim();
}

function render(value: unknown): string {
  if (!isRecord(value)) return "";
  const type = typeof value.type === "string" ? value.type : "";
  const children = childContent(value).map(render).join("");

  switch (type) {
    case "doc":
      return childContent(value).map(render).join("\n");
    case "paragraph":
    case "heading":
      return `${children}\n`;
    case "hardBreak":
      return "\n";
    case "text":
      return typeof value.text === "string" ? value.text : "";
    case "bulletList":
    case "orderedList":
      return `${childContent(value).map((item) => `- ${render(item).trim()}\n`).join("")}`;
    case "listItem":
      return children;
    case "codeBlock":
      return `${children}\n`;
    case "blockquote":
      return `${children}\n`;
    case "table":
      return childContent(value).map(render).join("\n");
    case "tableRow":
      return `${childContent(value).map((cell) => render(cell).trim()).join(" | ")}\n`;
    case "tableCell":
    case "tableHeader":
      return children;
    case "rule":
      return "---\n";
    case "mediaSingle":
    case "media":
      return `[${typeof attrs(value).alt === "string" ? String(attrs(value).alt) : "media"}]\n`;
    case "mention":
      return `@${typeof attrs(value).text === "string" ? String(attrs(value).text) : "user"}`;
    case "emoji":
      return typeof attrs(value).text === "string" ? String(attrs(value).text) : "";
    case "inlineCard":
    case "blockCard":
      return typeof attrs(value).url === "string" ? String(attrs(value).url) : "";
    default:
      return children;
  }
}
