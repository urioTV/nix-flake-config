# Własny plugin Atlassian

Własna implementacja integracji Jira + Confluence dla Pi. Zastępuje
`@pi-stef/atlassian`, usunięty z `settings.json` i `npm/package.json`
(kolizja nazw narzędzi uniemożliwia równoległe działanie obu).

## Dlaczego własny plugin

Oryginał miał dwa realne braki, które blokowały pracę:

1. **Brak `createmeta`** — plugin nie wystawiał żadnego narzędzia do odczytu
   wymaganych pól ekranu tworzenia. Agent zgadywał, a Jira odrzucała żądanie
   błędem 400. W projektach z nietypowym ekranem (np. IPCMC wymaga `duedate`
   i `labels`) tworzenie zgłoszeń było praktycznie niemożliwe.

2. **Gubienie ciała błędu** — komunikat brzmiał tylko
   `Atlassian API error 400 Bad Request`, mimo że `responseText` był
   przechwytywany. Agent nie wiedział, którego pola brakuje.

## Co ten plugin robi inaczej

- `jira_create_meta` — czyta `GET /rest/api/3/issue/createmeta/{proj}/issuetypes`
  i zwraca `requiredFields` per typ zgłoszenia, wraz z `allowedValues`.
- `client.ts` dołącza do komunikatu błędu mapę `errors` (fieldId → komunikat)
  oraz `errorMessages` bez duplikatów.

## Struktura

| Plik | Rola |
|---|---|
| `index.ts` | punkt wejścia, rejestracja, cykl życia konfiguracji |
| `config.ts` | źródła konfiguracji: env → plik JSON |
| `client.ts` | fetch + nagłówki + formatowanie błędów |
| `adf.ts` | konwersja ADF ↔ tekst (Jira v3 wymaga ADF) |
| `jira.ts` | narzędzia Jira (metadane, CRUD, Agile) |
| `confluence.ts` | narzędzia Confluence (read-only) |
| `tempo.ts` | narzędzia Tempo (logowanie czasu pracy) |

## Zakres

Zakres wybrano na podstawie realnego użycia w sesjach (62 wywołania Jira,
4 Confluence). Świadomie pominięto operacje zapisu w Confluence oraz
`jira_delete_*` — nie były używane, a każda wymaga własnej obsługi
uprawnień i wersji.

## Konfiguracja

Kolejność źródeł (pierwsze wygrywa):

1. Zmienne środowiskowe: `ATLASSIAN_BASE_URL` (lub `ATLASSIAN_DOMAIN`),
   `ATLASSIAN_EMAIL`, `ATLASSIAN_API_TOKEN` — oraz `TEMPO_API_TOKEN` dla Tempo
2. Plik wskazany przez `ATLASSIAN_CONFIG`
3. `$PI_CODING_AGENT_DIR/sf/atlassian/config.json` (domyślnie `~/.pi/sf/...`)

Sekret nigdy nie trafia do logów ani komunikatów błędów.

## Tempo (Timesheets)

Tempo to **osobny produkt**, nie część Jiry — inny host i inne poświadczenie:

| | Jira / Confluence | Tempo |
|---|---|---|
| host | `<domena>.atlassian.net` | `api.tempo.io/4` |
| auth | `Basic` (email + token) | `Bearer` (sam token) |

**Token Tempo jest inny niż token Atlassian.** Token Atlassian nie działa
w Tempo — zweryfikowane empirycznie: `401` bez tokenu, z tokenem Atlassian
w `Basic` oraz z tokenem Atlassian jako `Bearer`. Token generuje się w Tempo:
**Settings → Data Access → API Integration → New Token**.

Pole `tempoToken` dopisuje się do tego samego pliku co resztę konfiguracji
(`~/.pi/sf/atlassian/config.json`) albo podaje przez `TEMPO_API_TOKEN`. Brak
tokenu **nie wyłącza** narzędzi Jira i Confluence — błąd pojawia się dopiero
przy wywołaniu narzędzia Tempo.

### Narzędzia

Zakres dobrany pod realny przypadek użycia: logowanie własnych godzin pracy na
zadania, które potem zasilają raporty kierownictwa.

| Narzędzie | Rola |
|---|---|
| `tempo_create_worklog` | zaloguj czas (zgłoszenie, data, godziny, opis) |
| `tempo_get_worklogs` | odczyt wpisów w zakresie dat / per zgłoszenie |
| `tempo_update_worklog` | popraw wpis (godziny, data, opis) |
| `tempo_delete_worklog` | usuń wpis |
| `tempo_list_work_attributes` | jakie atrybuty przyjmuje worklog (np. Account) |
| `tempo_list_accounts` | lista kont Tempo |

### Zabezpieczenia wpisane w narzędzia

Wpisy trafiają do raportów, więc pomyłka ma realne skutki. Dlatego:

- **Odmowa duplikatu.** `tempo_create_worklog` najpierw sprawdza, czy dla tej
  samej pary (zgłoszenie, dzień) istnieje już wpis. Jeśli tak — **nie tworzy
  niczego**, tylko zwraca listę istniejących wpisów i wskazuje
  `tempo_update_worklog` / `tempo_delete_worklog`. Świadome powtórzenie wymaga
  `allowDuplicate: true`.
- **Data lokalna, nie UTC.** `startDate` to data kalendarzowa liczona w czasie
  lokalnym; liczenie w UTC przesuwałoby wpis o dzień w okolicach północy.
- **Walidacja godzin.** `hours` musi być `> 0` i `<= 24` — literówka rzędu
  `80` jest zatrzymywana, a nie zapisywana.

### Pułapka: `issueId` musi być numeryczne

Tempo nie przyjmuje klucza zgłoszenia. `IPCMC-123` kończy się `400`; potrzebne
jest numeryczne `id`. `tempo.ts` rozwiązuje to samo przez Jira
`GET /rest/api/3/issue/{key}?fields=id`, więc w parametrach narzędzi można
podawać klucz. To najczęstszy błąd zgłaszany na forach Atlassian.

### Termin ważności tokenu

Domyślnie **30 dni**. Po wygaśnięciu narzędzia Tempo przestają działać —
cicho, bez ostrzeżenia w UI. Scope'u istniejącego tokenu nie da się zmienić;
trzeba wygenerować nowy. Rozróżnienie scope: **View** = tylko `GET`,
**Manage** = `GET/PUT/POST/DELETE`.

## Ograniczenia

- **Tylko Jira Cloud i Confluence Cloud.** Endpointy v3 i v2 API.
- Tylko typowe ścieżki API; brak `createmeta` dla pól wymaganych przy
  *przejściach* (transition screen) — `jira_get_transitions` zwraca
  dostępne przejścia, ale nie ich wymagane pola.
- Confluence jest read-only.

## Edycja zadań — co jest potrzebne

`jira_update_issue` wysyła tylko te pola, które nazwiesz (edycja jest
patch-owa — brakujące pola z createmeta nie blokują `PUT`, inaczej niż przy
tworzeniu). Ale **zestaw edytowalnych pól zależy od typu zgłoszenia i statusu**,
więc przed edycją sprawdź `jira_get_edit_meta`.

Przypisywanie osoby wymaga `accountId`. `jira_get_user_profile` przyjmuje
**tylko** `accountId` — parametry `username` i `key` są odrzucane przez Jira
Cloud z HTTP 400. Aby znaleźć osobę po nazwisku lub mailu, użyj
`jira_search_users`, a listę osób możliwych do przypisania w projekcie daje
`jira_get_assignable_users`.

## Trzy formaty błędów Atlassian

`client.ts` rozpoznaje wszystkie trzy, bo inaczej agent dostaje surowy JSON
zamiast powodu odmowy:

| Format | Kształt |
|---|---|
| Jira | `errorMessages: [...]` + `errors: {field: msg}` |
| Confluence v1 | `{ message, statusCode }` |
| Confluence v2 | `errors: [{ status, code, title, detail }]` |

## Confluence wymaga dostępu

Jeśli wszystkie wywołania `confluence_*` kończą się błędem
`403 "Request rejected because caller cannot access Confluence"`, to konto nie
ma dostępu do produktu Confluence na tej instancji — nie jest to błąd pluginu.

## Rozwój

Testowanie pojedynczego rozszerzenia bez reszty środowiska:

```bash
pi -ne -e ~/nixos-wsl-config/dotfiles/pi/agent/extensions/atlassian -p "test"
```

`-ne` pomija wszystkie inne rozszerzenia — konieczne, bo inny plugin
Atlassian kolidowałby nazwami narzędzi.

Po zmianie źródeł wystarczy `/reload` w Pi (katalog jest auto-discoverowany,
`pi-update` nie usuwa `extensions/`).
