# AGENTS.md - Development Guidelines for NixOS Flake Configuration

## Build / Lint / Test Commands

### Building the Configuration
```bash
nh os build                              # Build NixOS config (recommended)
sudo nixos-rebuild switch --flake .#konrad-m18  # Alternative
home-manager switch --flake .#urio       # Build Home Manager config
nix flake check                          # Check flake for errors
nix-instantiate --parse <file.nix>       # Syntax check without building
```

### Formatting
```bash
nixfmt --check .                         # Check formatting
nixfmt <file.nix>                        # Format specific file
```

### Testing / Validation
No formal unit tests. Validate via:
```bash
nix-instantiate --parse <file.nix>       # Quick syntax check
nix eval .#nixosConfigurations.konrad-m18.config.system.build.toplevel
nix eval .#nixosConfigurations.konrad-m18.config.environment.systemPackages
```

## Code Style Guidelines

### File Structure
- **Modular organization**: Configurations under `host/`, `home/`, `sops/`
- **Use `import-tree`**: Automatic module discovery via `(import-tree ./dir).imports`
- **Naming**: Lowercase with hyphens (`boot-kernel-stuff/`, `hardware-stuff/`)
- **Entry points**: Each module has `default.nix` as main file

### Imports Pattern
```nix
{ config, lib, pkgs, inputs, ... }:
{
  imports = [ ./submodule.nix ] ++ (import-tree ./subdir).imports;
  # Configuration here
}
```

### Function Arguments
- Destructure attribute sets in function arguments
- Order: `config`, `lib`, `pkgs`, `inputs`, then `...`
- Use `@` pattern when needing both set and individual fields

### Formatting (nixfmt)
- 2-space indentation
- No trailing commas in attribute sets
- Break long lines at 80-100 characters
- Empty line between top-level attribute sets

### Naming Conventions
- **Files/Directories**: lowercase with hyphens (`development.nix`, `gaming/`)
- **Variables**: camelCase (`nixpkgs`, `importTree`, `systemPackages`)
- **Configuration keys**: dot-separated lowercase (`services.xserver.enable`)
- **Hostnames**: lowercase with hyphens (`konrad-m18`)

### Types and Values
- Use `lib.mkDefault` for overridable defaults
- Use `lib.mkForce` to override hard values
- Use `config.lib.file.mkOutOfStoreSymlink` for dotfile symlinks
- Prefer `with pkgs; [...]` for package lists

### Error Handling
- Nix is declarative - errors caught at evaluation time
- Use `lib.mkIf` for conditional configuration
- Use `lib.optional` for optional list elements
- Use `lib.optionalString` for optional strings

### Module Patterns

#### NixOS Module
```nix
{ config, lib, pkgs, ... }:
{
  imports = [ ./other.nix ];
  services.someService.enable = true;
  environment.systemPackages = with pkgs; [ package1 package2 ];
}
```

#### Home Manager Module
```nix
{ config, pkgs, lib, ... }:
{
  home.packages = with pkgs; [ ... ];
  programs.someApp.enable = true;
  xdg.configFile."app/config".source = ./config;
}
```

### Flake Structure
- Use `.follows` for sharing nixpkgs across flakes
- Comment inputs by category (`# Apps`, `# Gaming`, `# Secrets`)
- Use `flake-parts` for modular structure
- Define reusable modules in `flake.nixosModules.*` and `flake.homeModules.*`

### Sensitive Data
- **NEVER** commit passwords, API keys, or secrets
- Use `sops-nix` for encrypted secrets (see `sops/`)
- SSH keys: public keys only
- Reference secrets via `sops-config.nix`

### Common Patterns

#### Shared Module Pattern (NixOS + Home Manager)
```nix
let
  sharedConfig = { inputs, inputs' }: { ... };
in
{
  flake.nixosModules.nix-settings = { ... }: { imports = [ (sharedConfig { inherit inputs inputs'; }) ]; };
  flake.homeModules.nix-settings = { ... }: { imports = [ (sharedConfig { inherit inputs inputs'; }) ]; };
}
```

#### Package Overlays
```nix
final: prev: {
  custom-package = prev.callPackage ./custom-pkgs/package.nix { };
}
```

## Pre-commit Checklist
- [ ] Configuration builds: `nh os build`
- [ ] No syntax errors: `nix-instantiate --parse`
- [ ] Formatted: `nixfmt --check`
- [ ] Flake checks pass: `nix flake check`
- [ ] Changes documented in comments
- [ ] Module imports correct and complete
- [ ] No unnecessary/commented-out code
- [ ] No sensitive info committed (use sops-nix)

## Useful Commands
```bash
nix search nixpkgs <package-name>        # Search packages
nix-collect-garbage -d                   # Garbage collection
nix flake update <input-name>            # Update flake inputs
```
