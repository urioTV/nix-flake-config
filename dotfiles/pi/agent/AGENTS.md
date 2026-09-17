# Globalne instrukcje (Pi Coding Agent)

## Lokalizacja konfiguracji Pi

Konfiguracja Pi, którą widzisz pod `~/.pi`, jest **lustrzanym odbiciem przez Home Manager** (out-of-store symlink z `modules/ai/pi/_pi.nix`) katalogu `~/nix-flake-config/dotfiles/pi`. Obie ścieżki wskazują na **te same pliki** — to nie są dwie kopie. Nie zdziw się więc, gdy `~/.pi/...` i `~/nix-flake-config/dotfiles/pi/...` okażą się identyczne.

- Zmiany w plikach pod `dotfiles/pi` są **żywe od razu** (symlink), bez `nixos-rebuild`. Wyjątek: moduły Nix (`modules/**`, `host/**`, `home/**`) wymagają `nh os switch` (lub `sudo nixos-rebuild switch --flake .#konrad-desktop`).
- Konfiguracja agenta siedzi w `dotfiles/pi/agent/` (settings.json, extensions/, skills/); `~/.pi` jest symlinkiem wygenerowanym przez home-manager.
- Część stanu runtime (`sessions/`, `vstack/`, `kendex/`, `npm/`, `git/`, `auth.json`, `models.json`, `sf/`) jest celowo poza kontrolą wersji i nie pojawi się w `git status`.
- Nie kopiuj konfiguracji do innych lokalizacji ani nie zakładaj, że `~/.pi` jest niezależnym katalogiem.
- Zmiany konfiguracji pi wymagają `/reload` w pi albo restartu procesu.

## Środowisko: NixOS (konrad-desktop, natywny Linux)

Ten host to **NixOS** (konrad-desktop, zarządzany flakes + home-manager + sops-nix + stylix). Nie jest to typowa dystrybucja Linuksa.

- **Korzystaj z narzędzi Nix** zamiast instalować rzeczy imperatywnie: `nix run`, `nix shell`, `nix build`, `nix develop`, `nh os switch`.
  - Format: `nixfmt .`, check: `nixfmt --check .`.
- **Nie zakładaj, że zwykłe skrypty i pliki wykonywalne zadziałają** jak na innych dystro:
  - `apt`, `dnf`, `pacman`, `pip install`, `npm install -g` itp. nie zadziałają — `/nix/store` jest read-only, nie ma `/usr/bin`, `/usr/lib` ani globalnego systemu pakietów.
  - Skrypty zakładające ścieżki typu `/usr/bin/env python`, `#!/bin/sh` z systemowym `/bin` czy ładowanie `.so` z `/usr/lib` mogą się nie uruchomić — brakuje interpreterów i bibliotek w standardowych lokalizacjach.
  - Prekompilowane binarki z internetu często nie działają bez `autoPatchelfHook` / `patchelf` (interpreter ELF wskazuje na nieistniejące `/lib64/ld-linux-*`).
  - Rozwiązanie: użyj `nix-shell`/`nix develop` z odpowiednimi pakietami, albo dodaj pakiet do modułu Nix w `modules/` lub `home/`.
- Trwałe zmiany pakietów, usług i zmiennych środowiskowych rób w plikach Nix (`modules/**`, `home/**`, `host/**`), nie ręcznie w `~/.bashrc`.
- Sekrety pochodzą z sops-nix (`sops/secrets/`); w środowisku są wystawiane jako `$(cat ${config.sops.secrets.*.path})`. Nie zapisuj sekretów plaintextem w repo i **nigdy nie odszyfrowuj ani nie odsłaniaj zawartości plików z `sops/`**.
- Desktop ma lokalny serwer llama.cpp (modele llama.cpp/llama-swap w `enabledModels`) — nie sugeruj chmurowych API tam, gdzie działa lokalny model.
