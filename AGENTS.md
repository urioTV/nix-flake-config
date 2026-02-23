# AGENTS.md - NixOS Flake Configuration

**Host:** konrad-m18 | **User:** urio

## OVERVIEW
NixOS config using **Flakes**, **Home Manager**, **flake-parts**, **sops-nix**. Single-host laptop with gaming support.

## STRUCTURE
```
./
├── flake.nix          # Entry point, nixosConfigurations
├── configuration.nix  # System module (imports host/* via import-tree)
├── home.nix           # Home-Manager module (imports home/*)
├── vars.nix           # Shared options (wallpaper, base16Scheme)
├── host/              # System-level configs
│   ├── gaming/        # Gaming (audio, hardware, programs)
│   ├── pkgs/          # Custom packages
│   └── */             # ai, plasma6, networking, etc.
├── home/              # User-level (programs, services, pkgs)
├── sops/              # Secrets (secrets.yaml)
└── dotfiles/          # Editor configs (zed, antigravity)
```

## WHERE TO LOOK
| Task | Location |
|------|----------|
| System package | `host/programs/` or module-specific |
| User package | `home/programs/`, `home/pkgs/` |
| Gaming | `host/gaming/{audio,hardware,programs}/` |
| Secrets | `sops/secrets/secrets.yaml` → `config.sops.secrets.*` |
| Custom packages | `host/pkgs/*.nix` |
| Shared options | `vars.nix` |
| Module providers | Search `flake.nixosModules`, `flake.homeModules` |

## COMMANDS

### Build
```bash
nh os build                           # Preferred
sudo nixos-rebuild switch --flake .#konrad-m18
home-manager switch --flake .#urio
```

### Lint & Format
```bash
nixfmt --check .                      # Check
nixfmt .                              # Format all
nixfmt path/to/file.nix               # Format single
```

### Validate
```bash
nix-instantiate --parse .             # Syntax (fast)
nix flake check                       # Full check
nix eval .#nixosConfigurations.konrad-m18.config.environment.systemPackages
```

## CONVENTIONS

### Naming
*   **Files/Dirs:** `kebab-case`
*   **Variables:** `camelCase`
*   **Hostnames:** `kebab-case`

### Module Pattern
```nix
{ config, lib, pkgs, inputs, ... }:  # Always destructure with ...
```

```nix
# Shared between NixOS and HM
let shared = { ... }: { ... }; in {
  flake.nixosModules.shared = shared;
  flake.homeModules.shared = shared;
}
```

### Style
*   **Indentation:** 2 spaces, no tabs
*   **Lists:** One element per line (multi-line)
*   **Packages:** `with pkgs; [ ... ]`
*   **Defaults:** `lib.mkDefault` for overridable, `lib.mkForce` sparingly
*   **Conditionals:** `lib.mkIf`, `lib.optional`, `lib.optionalString`
*   **Imports:** `(import-tree ./directory).imports` for auto-discovery

## ANTI-PATTERNS
*   **NEVER** commit plain-text secrets (passwords, keys, tokens)
*   **NEVER** modify `hardware-configuration.nix` (generated)
*   **ALWAYS** run `nix-instantiate --parse .` after editing `.nix` files
*   **DON'T** use `lib.mkForce` unless necessary
*   **DON'T** skip `nixfmt` before committing

## WORKFLOW
1.  **Discovery:** `find . -type f -name "*.nix"` to understand structure
2.  **Edit:** Make changes
3.  **Validate:** `nix-instantiate --parse .`
4.  **Format:** `nixfmt <modified-files>`
5.  **Verify:** `nix flake check` (if possible)
6.  **Commit:** Conventional commits (`feat:`, `fix:`, `refactor:`)

## SECRETS
*   **Tool:** `sops-nix`
*   **Location:** `sops/secrets/secrets.yaml`
*   **Age key:** `/home/urio/.ssh/id_ed25519`
*   **Usage:** `config.sops.secrets.<name>.path`
*   **Available:** `openrouter_api_key`, `context7_api_key`, `github_token`, `nano-gpt_api_key`, `z-ai_api_key`

## USEFUL COMMANDS
```bash
nix search nixpkgs <query>    # Find packages
nix repl                      # Interactive pkgs/lib exploration
nix-collect-garbage -d        # Clean old generations
nix flake update              # Update lockfile
nh os switch                  # Build + switch (nh helper)
```
