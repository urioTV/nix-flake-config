# AGENTS.md - Gaming Module

## OVERVIEW
Gaming stack: Steam, Proton, launchers, audio tuning, hardware support.

## STRUCTURE
```
gaming/
├── audio/           # PipeWire gaming audio rules
├── hardware/        # Controllers, mice, udev rules
└── programs/        # Steam, launchers, games, tools
```

## WHERE TO LOOK
| Task | File |
|------|------|
| Steam config | `programs/steam.nix` |
| Proton versions | `programs/steam.nix` → `extraCompatPackages` |
| Game launchers | `programs/launchers.nix` |
| Audio fixes | `audio/pipewire-gaming.nix` |
| Controller/mouse | `hardware/default.nix` |

## CONVENTIONS
*   Steam overrides: use `pkgs.steam.override { extraPkgs = ...; }`
*   Proton from NUR: `nur.repos.mio.proton-*`
*   Audio rules: `services.pipewire.extraConfig."pipewire-pulse"`
*   Hardware groups: add user to `gamemode` group

## ANTI-PATTERNS
*   **DON'T** enable both `xpadneo` and generic Xbox driver
*   **DON'T** hardcode Proton paths - use `extraCompatPackages`
