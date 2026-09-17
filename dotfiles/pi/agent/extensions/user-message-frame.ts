import {
  getMarkdownTheme,
  type ExtensionAPI,
  type ExtensionContext,
  UserMessageComponent,
} from "@earendil-works/pi-coding-agent";
import { Markdown, truncateToWidth, visibleWidth } from "@earendil-works/pi-tui";

const PATCH = Symbol.for("urio.pi.user-message-frame.patch");
const OSC133_START = "\x1b]133;A\x07";
const OSC133_END = "\x1b]133;B\x07";
const OSC133_FINAL = "\x1b]133;C\x07";

type PromptZones = { start: boolean; end: boolean; final: boolean };

type PatchState = {
  activeContext?: ExtensionContext;
  originalRender: (width: number) => string[];
};

function takePromptZones(lines: string[]): { lines: string[]; zones: PromptZones } {
  const zones: PromptZones = { start: false, end: false, final: false };
  const cleanLines = lines.map((line) => {
    let clean = line;
    if (clean.includes(OSC133_START)) {
      zones.start = true;
      clean = clean.split(OSC133_START).join("");
    }
    if (clean.includes(OSC133_END)) {
      zones.end = true;
      clean = clean.split(OSC133_END).join("");
    }
    if (clean.includes(OSC133_FINAL)) {
      zones.final = true;
      clean = clean.split(OSC133_FINAL).join("");
    }
    return clean;
  });
  return { lines: cleanLines, zones };
}

function restorePromptZones(lines: string[], zones: PromptZones): string[] {
  if (lines.length === 0) return lines;
  const framed = [...lines];
  if (zones.start) framed[0] = `${OSC133_START}${framed[0]}`;
  const end = `${zones.end ? OSC133_END : ""}${zones.final ? OSC133_FINAL : ""}`;
  if (end) framed[framed.length - 1] = `${end}${framed[framed.length - 1]}`;
  return framed;
}

function renderMarkdown(component: unknown, width: number, context: ExtensionContext): string[] | undefined {
  const text = (component as { text?: unknown })?.text;
  if (typeof text !== "string") return undefined;

  return new Markdown(
    text,
    0,
    0,
    getMarkdownTheme(),
    { color: (content: string) => context.ui.theme.fg("userMessageText", content) },
    { preserveOrderedListMarkers: true, preserveBackslashEscapes: true },
  ).render(width);
}

function frame(lines: string[], width: number, context: ExtensionContext): string[] {
  if (width < 4 || lines.length === 0) return lines;

  const { lines: body, zones } = takePromptZones(lines);
  const innerWidth = width - 2;
  const contentWidth = Math.max(1, innerWidth - 1);
  const border = (text: string) => context.ui.theme.fg("borderAccent", text);
  const marker = (text: string) => context.ui.theme.fg("accent", text);
  const topLeft = "━ ";
  const topRight = ` ${"━".repeat(Math.max(0, innerWidth - visibleWidth(topLeft) - 2))}`;

  const top = `${border("┏")}${border(topLeft)}${marker("π")}${border(topRight)}${border("┓")}`;
  const bottom = `${border("┗")}${border("━".repeat(innerWidth))}${border("┛")}`;
  const content = body.map((line) => {
    const clipped = truncateToWidth(line, contentWidth, "");
    const padding = " ".repeat(Math.max(0, contentWidth - visibleWidth(clipped)));
    return `${border("┃")} ${clipped}${padding}${border("┃")}`;
  });

  return restorePromptZones([top, ...content, bottom], zones);
}

export default function userMessageFrame(pi: ExtensionAPI): void {
  const prototype = UserMessageComponent.prototype as Record<PropertyKey, unknown>;
  if (typeof prototype.render !== "function") return;

  let state = prototype[PATCH] as PatchState | undefined;
  if (!state) {
    state = { originalRender: prototype.render as (width: number) => string[] };
    prototype[PATCH] = state;
    prototype.render = function renderFramedUserMessage(this: unknown, width: number): string[] {
      const context = state?.activeContext;
      if (!context?.hasUI || width < 4) return state!.originalRender.call(this, width);

      const markdown = renderMarkdown(this, width - 2, context);
      return markdown ? frame(markdown, width, context) : state!.originalRender.call(this, width);
    };
  }

  pi.on("session_start", (_event, context) => {
    state!.activeContext = context;
  });

  pi.on("session_shutdown", () => {
    if (prototype[PATCH] === state) {
      prototype.render = state!.originalRender;
      delete prototype[PATCH];
    }
    state!.activeContext = undefined;
  });
}
