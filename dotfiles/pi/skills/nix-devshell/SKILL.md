---
name: nix-devshell
description: "Tworzy i utrzymuje wielo profilowe środowisko deweloperskie Nix oparte o flake-parts + numtide/devshell. Użyj, gdy użytkownik prosi o devshell, środowisko nix develop, dodanie profilu (np. ansible, pulumi, node, rust, go, terraform), dodanie pakietu/komendy do istniejącego devshella albo scaffolding flake.nix od zera. Uniwersalny — nie zakłada żadnego konkretnego języka ani narzędzia."
---

# Nix Devshell Skill (flake-parts + numtide/devshell)

Scaffolduj i utrzymuj środowiska deweloperskie Nix w jednym spójnym wzorcu,
niezależnie od stosu technologicznego. Skill jest **uniwersalny**: Python,
Ansible, Pulumi, Node, Rust, Go, Terraform, whatever — każdy narzędziowy
"profil" to osobny moduł Nix z tą samą wewnętrzną strukturą.

## Kiedy używać

- "przygotuj mi devshell nix" / "scaffold flake" / "dodaj profil dla X"
- "dodaj pakiet Y do profilu Z" lub "dodaj komendę"
- "zrób środowisko jak w infrastructure" / "jak ten flake"
- użytkownik pokazuje `flake.nix` z `flake-parts` + `devshell` i chce go rozszerzyć
- wymaganie: powtarzalne, hermetyczne środowisko przez `nix develop` / `direnv`

**Nie używaj**, gdy projekt wyraźnie prosi o `flake-utils`, `devshell.mkShell`
(stary styl bez flake-parts), `nix-shell`/`shell.nix`, albo devenv/shellhub.
Wtedy zapytaj, czy przejść na ten wzorzec, zamiast cicho mieszać paradygmatów.

## Architektura (jedyna akceptowalna)

Repozytorium trzyma **jeden** flake z wieloma profilami. Każdy profil to
osobny moduł pod `nix/devshells/`. Wspólne bloki (listy pakietów, komend,
startup-hooki, env) są budowane w `let` w module narzędziowym i udostępniane
innym profilom przez `_module.args` — dzięki temu profil `default` i profil
`ci` mogą składać się z tych samych klocków bez kopiowania.

```
<repo>/
├── flake.nix                # mkFlake + imports list devshelli
├── .envrc                   # direnv: use flake [+ use flake .#<profile>]
└── nix/
    └── devshells/
        ├── <tool-a>.nix      # np. ansible.nix, pulumi.nix, node.nix ...
        ├── <tool-b>.nix
        ├── tools.nix        # opcjonalne: pakiety pomocnicze / generatory
        ├── default.nix       # agregat: tool-a + tool-b + tools
        └── ci.nix           # minimalny podzbiór dla CI/CD
```

### Niezmienniki

1. **inputs** w `flake.nix`: `nixpkgs` (≥ `nixpkgs-unstable`), `flake-parts`,
   `devshell` (numtide). Nic więcej bez wyraźnego powodu.
2. **systems** zawsze obejmują `x86_64-linux`, `aarch64-linux`, `x86_64-darwin`,
   `aarch64-darwin` chyba, że projekt celuje w jedną platformę.
3. **Wszystkie devshelle** to `perSystem` moduły przez `devshell.flakeModule`.
   Żadnego top-level `devShell` z `nixpkgs.mkShell`.
4. **Każdy profil** ma: `devshell.name`, `devshell.motd`, `env`, `packages`,
   `commands` oraz zero lub więcej `devshell.startup.<id>.text`.
5. **Komendy** mają 4 pola: `name`, `category`, `help`, `command`. Krótkie
   komendy opakowują wywołania w odpowiednim katalogu (`cd <dir> && ...`).
6. **Startup-hooki** mają id `load-<coś>-env` i są idempotentne (sprawdzają
   warunki, np. istnienie pliku, zmienną `*_INITIALIZED`). Nigdy nie zakładaj,
   że uruchamiają się tylko raz.
7. **`$PRJ_ROOT`** to kanoniczny root projektu w startup-hookach i ścieżkach
   env `eval`. Nie używaj `$PWD` ani realpatha — devshell ustawia `PRJ_ROOT`.
8. **Nic specyficznego dla języka nie trafia do `flake.nix`.** Stos języka
   żyje w profilu narzędziowym. Python to *jeden z* profili, nie центральный.

### Współdzielenie klocków (`_module.args`)

Każdy profil narzędziowy buduje w `let` atrybut zbiorczy (np. `ansibleDev`,
`pulumiDev`, `nodeDev`) i wystawia go przez `_module.args`. Inne profile
(`default`, `ci`) destrukturyzują go z argumentów `perSystem`. Zasady:

- Atrybut zbiorczy zawiera dokładnie te pola, które profil udostępnia:
  `packages`, `commands`, `env`/`baseEnv`, `startup`, opcjonalnie `cli`/inne.
- Profil narzędziowy deklaruje **zarówno** swój `devshells.<tool>` (kompletny
  profil do samodzielnego `nix develop .#<tool>`), **jak i** `_module.args`
  (klocki do reuse'u). To dwie odrębne sekcje tego samego modułu.
- `default.nix` składa klocki addytywnie: `env = a.env ++ b.env`,
  `packages = a.packages ++ b.packages`, `commands = a.commands ++ b.commands`,
  a startup-hooki listuje każdy z `devshell.startup.load-<tool>-env.text`.
- `ci.nix` to **świadomy podzbiór**: mniejsza lista `packages` (często własna,
  nie `a.packages ++ b.packages`), ale ten sam `env` i te same startup-hooki.
  Komentarz w module tłumaczy, czego celowo brakuje vs `default`.

## Scaffolding krok po kroku

Wykonuj sekwencyjnie, bez pytania o potwierdzenie między krokami, chyba że
wymaga tego konflikt z istniejącym kodem.

1. **Rozpoznanie**: `ls` repo + ew. `cat flake.nix` jeśli istnieje. Zdecyduj:
   - scaffold od zera → idź do 2,
   - rozszerzenie istniejącego flake w tym wzorcu → idź do 3.
2. **Od zera**:
   a. Stwórz `flake.nix` z wzorca `templates/flake.nix`. Uzupełnij `description`
      i listę `imports` pasującą do profili projektu.
   b. Stwórz `nix/devshells/` i po jednym module na profil narzędziowy
      wg `templates/devshell-module.nix`. Nazwij plik małymi literami
      (`ansible.nix`, `pulumi.nix`, `node.nix`, `rust.nix`, `terraform.nix`...).
   c. Stwórz `nix/devshells/default.nix` wg `templates/default.nix`
      agregujący wszystkie profile.
   d. Stwórz `nix/devshells/ci.nix` wg `templates/ci.nix` — minimalny podzbiór.
   e. Stwórz `.envrc` wg `templates/envrc`. Nigdy nie commituj prawdziwego
      `.envrc` z sekretami — `.envrc` jest bezpieczny do commitowania, ale
      gitignore'uj lokalne pliki sekretów.
3. **Rozszerzenie istniejącego flake**:
   a. Dodaj nowy plik `nix/devshells/<tool>.nix` wg wzorca.
   b. Dopisz `./nix/devshells/<tool>.nix` do `imports` w `flake.nix`.
   c. Jeśli nowy profil ma wejść do `default`/`ci`, zaktualizuj ich `env`,
      `packages`, `commands`, `devshell.startup`.
   d. Zaktualizuj `.envrc` o komentarz z alternatywnym `use flake .#<tool>`.
4. **Dodanie pakietu/komendy do istniejącego profilu**: edytuj tylko ten jeden
   moduł, w sekcji `let` odpowiedniej listy (`*Packages` / `*Commands`),
   a jeśli dodajesz nową kategorię komend — utrzymuj spójność `category`
   w całym profilu. Nie duplikuj pakietu w `ci.nix`, chyba że tam też jest
   potrzebny.
5. **Weryfikacja** — uruchom po kolei i **zatrzymaj się na pierwszym błędzie**:
   - `nix flake check --no-build` (walidacja flake)
   - `nix flake show` (wypisz `devShells.<system>.<profile>`)
   - `nix develop .#<profile> -c <cmd>` albo `nix develop .#default` i interaktywnie
   - jeśli jest direnv: `direnv allow` i sprawdź, czy `use flake` się załadował
6. **Zgłoś rezultat**: lista profili, ścieżki utworzonych/edytowanych plików,
   komendy weryfikacyjne, które przeszły.

## Zasady pisania modułów

### Sekcja `let` — klocki

Buduj listy nazywając je `<tool>Packages`, `<tool>Commands`, `<tool>Startup`,
`<tool>Env`/`baseEnv`. Następnie złóż je w atrybut `<tool>Dev`:

```nix
<tool>Dev = {
  inherit <tool>Packages <tool>Commands <tool>Startup <tool>Env;
};
```

W `in` wystaw **dwa** rzeczy:
- `_module.args = { inherit <tool>Dev; };`
- `devshells.<tool> = { devshell.name = "..."; ... }` — kompletny profil.

### Startup-hooki — kanon

- id: `load-<tool>-env` (i drugi jak trzeba, np. `load-<tool>-aws`).
- idempotentność: pierwszy wiersz sprawdza `if [ -z "''${<TOOL>_DEVSHELL_INITIALIZED:-}" ]`
  i ustawia flagę na końcu bloku.
- pliki projekto-we: sprawdzaj `if [ -f "$PRJ_ROOT/<path>" ]` przed użyciem.
- materiaizacja sekretów w runtime (klucze, tokeny): używaj `$XDG_RUNTIME_DIR`
  z fallbackiem na `/tmp`, `chmod 700/600`, `ssh-keygen -y -f ... > .pub`.
- fail-closed: jeśli narzędzie potrzebuje sekretu, a go nie ma — ustaw pustą/
  fałszywą wartość i ostrzeż na stderr, zamiast cicho dziedziczyć `~/.ssh`
  czy ssh-agent.
- hooki nie powinny `exit`ować shella; używaj `return 1` w funkcjach lub
  ostrzeżeń.

### `env`

Lista atrybutów `{ name, value } | { name, eval }`. `value` dla stałych,
`eval` dla ścieżek/wyrażeń shellowych (`$PRJ_ROOT/...`). Używaj `eval` tam,
gdzie wartość zależy od środowiska runtime.

### `commands`

Każda komenda:
```nix
{
  name = "<tool>-<akcja>";
  category = "<tool>";
  help = "Krótki opis po angielsku lub polsku — match języka repo";
  command = "cd <dir> && <tool> <args>";   # albo z "$@" do przekazania argumentów
}
```

### `motd`

Funkcja `motd = profile: '' ... ''` — krótki baner z nazwą projektu, profilem,
`$PRJ_ROOT` i istotnym statusem. Końcówka `$(type -p menu &>/dev/null && menu)`
uruchamia menu komend devshella. Trzymaj ten sam `motd` we wszystkich profilach,
zmieniając tylko nazwę profilu.

### Sekrety i zewnętrzne kontrakty (opcjonalnie)

Jeśli projekt potrzebuje ładować lokalne sekrety (vault, fnox, 1password-cli,
doppler, aws-vault...), dodaj **osobny** moduł ładowacza (wzorzec:
`nix/devshells/fnox.nix`), który wystawia przez `_module.args` funkcję
`loadX` (string ze skryptem shellowym). Inne startup-hooki wywołują ją jako
pierwszą linię: `${loadX}`. Zasady:

- provider-neutralny kontrakt: plik kontraktu (np. `fnox.toml`) jest
  commitowany i deklaruje wymagane zmienne; provider jest opt-in przez
  gitignored plik lokalny (np. `fnox.local.toml`). Bez niego hook jest no-op.
- CI **nigdy** nie używa tego loadera — sprawdź `if [ -z "''${CI:-}" ]`.
- Sekrety nie trafiają do `env` devshella na sztywno; ładowacz je eksportuje
  w runtime po uwierzytelnieniu operatora.

## Ograniczenia i pułapki

- **Nie mieszaj stylu `mkShell` z `devshell.flakeModule`** w jednym flake.
  To powoduje dziwne błędy eval.
- **`pkgs` bierzesz z argumentu `perSystem`**, nie z `inputs.nixpkgs.legacyPackages`.
  flake-parts podaje je gotowe.
- **Każda lista pakietów** to `with pkgs; [ ... ]` wewnątrz `perSystem`, gdzie
  masz `pkgs` w scope. Nie `import <nixpkgs>`.
- **Pakiet niestandardowy** (np. własny wrapper CLI z `stdenv.mkDerivation`):
  zdefiniuj w `let` w tym samym module narzędziowym (jak `pulumiCli` w
  `pulumi.nix`), użyj `autoPatchelfHook`+`makeWrapper` na Linuxie, wystaw
  przez `<tool>Dev.<cli>` jeśli `ci.nix` musi go użyć.
- **Startup-hooki są shellowe** (`bash`). Używaj `''${VAR:-}` dla bezpiecznego
  expandowania, `''` dla dosłownego `${}` w Nix, `<<'HEREDOC'` z cytowanym
  znacznikiem dla treści, których Nix nie ma interpretować.
- **Systemy macOS**: pakiety Linux-only chroń przez
  `pkgs.lib.optionals pkgs.stdenv.hostPlatform.isLinux [ ... ]`.
- **`.envrc` commituj**, ale `.envrc.local` / `<tool>.local.toml` / pliki
  sekretów dodaj do `.gitignore`.
- **Komentarze po polsku lub angielsku** — match języka istniejącego kodu
  w repo. Nie mieszaj w jednym module.

## Szablony referencyjne

Czytaj pliki w `templates/` obok tego SKILL.md i adaptuj (zmień nazwy
profili, pakiety, komendy, startup-hooki — struktura zostaje):

- `templates/flake.nix` — szkielet flake z `flake-parts` + `devshell`.
- `templates/devshell-module.nix` — wzorzec pojedynczego profilu narzędziowego
  z `let`/`_module.args`/`devshells.<tool>`.
- `templates/default.nix` — agregat profili.
- `templates/ci.nix` — minimalny podzbiór dla CI.
- `templates/envrc` — `.envrc` z `use flake` i komentarzami alternatyw.

Po zakończeniu scaffoldu **zawsze** uruchom `nix flake check --no-build`
i zgłoś, które komendy weryfikacyjne przeszły, a które nie.
