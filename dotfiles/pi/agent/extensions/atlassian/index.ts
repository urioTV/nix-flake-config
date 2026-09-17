/**
 * Atlassian (Jira + Confluence) dla Pi.
 *
 * Własna implementacja zastępująca @pi-stef/atlassian. Powstała, ponieważ
 * oryginał nie wystawiał `createmeta`, przez co agent nie mógł poznać
 * wymaganych pól i tworzenie zgłoszeń kończyło się błędem 400. Drugą wadą
 * było gubienie ciała odpowiedzi błędu — komunikat mówił tylko
 * "400 Bad Request", bez wskazania brakującego pola.
 *
 * Ten plugin:
 *   - wystawia `jira_create_meta` (createmeta per projekt i typ zgłoszenia),
 *   - dołącza treść błędu Jiry do komunikatu (errorMessages + errors),
 *   - wczytuje konfigurację z env albo ~/.pi/sf/atlassian/config.json.
 *
 * Obejmuje też Tempo (Timesheets) — osobny produkt z własnym hostem
 * (`api.tempo.io`) i własnym tokenem Bearer. Szczegóły w `tempo.ts`.
 */
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

import { AtlassianError } from "./client.js";
import { configPaths, loadConfig, resetConfigCache } from "./config.js";
import { registerConfluenceTools } from "./confluence.js";
import { registerJiraTools } from "./jira.js";
import { registerTempoTools, resetTempoCache } from "./tempo.js";

export default function atlassian(pi: ExtensionAPI): void {
  registerJiraTools(pi);
  registerConfluenceTools(pi);
  registerTempoTools(pi);

  // Konfiguracja może się pojawić po starcie (np. użytkownik tworzy plik).
  // Czyścimy cache przy nowej sesji, żeby nie trzymać nieaktualnego stanu.
  pi.on("session_start", () => {
    resetConfigCache();
    resetTempoCache();
  });

  // Ostrzeżenie na starcie, jeśli brak konfiguracji — lepiej teraz niż w trakcie
  // wykonywania zadania. Brak konfiguracji nie blokuje startu Pi.
  pi.on("session_start", (_event, ctx) => {
    try {
      const config = loadConfig();
      ctx.ui.notify(`Atlassian: połączono z ${config.baseUrl}`, "info");
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      ctx.ui.notify(`Atlassian: ${message}`, "warning");
    }
  });

  // Spójny format błędów: komunikat zawiera już ciało odpowiedzi Jiry.
  pi.on("session_shutdown", () => {
    resetConfigCache();
    resetTempoCache();
  });
}

export { AtlassianError, configPaths, loadConfig };
