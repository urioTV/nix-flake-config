# AGENTS.md - Development Guidelines for NixOS Flake Configuration

## Project Overview
This repository contains a NixOS configuration using **Flakes**, **Home Manager**, and **flake-parts**.
It manages the system configuration for host `konrad-m18` and home configuration for user `urio`.

## Build, Lint, and Test Commands

### 1. Build Configuration
*   **NixOS System (Preferred)**:
    ```bash
    nh os build
    ```
*   **NixOS System (Alternative)**:
    ```bash
    sudo nixos-rebuild switch --flake .#konrad-m18
    ```
*   **Home Manager**:
    ```bash
    home-manager switch --flake .#urio
    ```

### 2. Linting and Formatting
*   **Check Formatting**:
    ```bash
    nixfmt --check .
    ```
*   **Format All Files**:
    ```bash
    nixfmt .
    ```
*   **Format Single File**:
    ```bash
    nixfmt path/to/file.nix
    ```

### 3. Testing and Validation
Since this is a configuration repo, "testing" means validating syntax and evaluation.

*   **Syntax Check (Fast)**:
    ```bash
    nix-instantiate --parse .
    ```
*   **Full Flake Check**:
    ```bash
    nix flake check
    ```
*   **Validate Specific Attribute (Single Test Equivalent)**:
    Use `nix eval` to check if a specific part of the config evaluates correctly.
    ```bash
    # Check system packages
    nix eval .#nixosConfigurations.konrad-m18.config.environment.systemPackages
    
    # Check a specific service enablement
    nix eval .#nixosConfigurations.konrad-m18.config.services.openssh.enable
    ```

## Code Style Guidelines

### File Structure & Organization
*   **Modular Design**: Keep configs small and focused.
    *   `host/`: Machine-specific configurations.
    *   `home/`: User-specific Home Manager configurations.
    *   `sops/`: Secrets management.
*   **Import Tree**: Use `import-tree` for automatic module discovery.
    ```nix
    imports = [ ./manual-import.nix ] ++ (import-tree ./directory).imports;
    ```
*   **Entry Points**: Use `default.nix` as the entry point for directories.

### Nix Language Patterns
*   **Function Arguments**: Always destructure. Use `...` for extensibility.
    ```nix
    { config, lib, pkgs, inputs, ... }:
    ```
*   **Indentation**: 2 spaces. No tabs.
*   **Lists**: Multi-line lists should have one element per line.
*   **Attribute Sets**: No trailing commas. Empty line between top-level attributes.

### Naming Conventions
*   **Files/Directories**: `kebab-case` (e.g., `hardware-configuration.nix`, `gaming-laptop/`).
*   **Variables**: `camelCase` (e.g., `systemPackages`, `myCustomVar`).
*   **Hostnames**: `kebab-case` (e.g., `konrad-m18`).

### Types and Values
*   **Defaults**: Use `lib.mkDefault` for values that might be overridden.
*   **Forcing**: Use `lib.mkForce` sparingly, only when necessary to override defaults.
*   **Packages**: Prefer `with pkgs; [ ... ]` for readability in package lists.

### Error Handling
*   **Conditionals**: Use `lib.mkIf` for enabling modules/settings conditionally.
*   **Optionals**: Use `lib.optional` (list) or `lib.optionalString` (string) to avoid null errors.
*   **Assertions**: Use `assertions` list in modules to enforce valid configurations.
    ```nix
    config.assertions = [
      { assertion = config.services.foo.enable -> config.services.bar.enable;
        message = "Foo requires Bar"; }
    ];
    ```

## Flake & Module Architecture

### Flake Parts
This repo uses `flake-parts` to structure the flake.
*   Define reusable modules in `flake.nixosModules` or `flake.homeModules`.
*   Use `perSystem` for system-specific outputs (devShells, packages).

### Shared Configuration
Share config between NixOS and Home Manager using the shared module pattern:
```nix
let shared = { ... }: { ... }; in {
  flake.nixosModules.shared = shared;
  flake.homeModules.shared = shared;
}
```

## Security & Secrets
*   **Tool**: `sops-nix` is used for secret management.
*   **Rule**: **NEVER** commit plain-text secrets (passwords, keys, tokens).
*   **Config**: Secrets are defined in `sops/` and referenced via `config.sops.secrets`.
*   **SSH Keys**: Only commit public keys.

## Agent Workflow
1.  **Discovery**: Before making changes, run `ls -R` or `find .` to understand the directory structure.
2.  **Validation**: ALWAYS run `nix-instantiate --parse .` after modifying `.nix` files to catch syntax errors immediately.
3.  **Formatting**: Run `nixfmt <file>` on any file you modify.
4.  **Verification**: If possible, run `nix flake check` before finishing a task.
5.  **Commit Messages**: Use conventional commits (e.g., `feat: add zsh plugin`, `fix: correct font path`).

## Useful Commands Reference
*   `nix search nixpkgs <query>`: Find packages.
*   `nix repl`: Interactive shell to explore `pkgs` or `lib`.
*   `nix-collect-garbage -d`: Clean up old generations.
*   `nix flake update`: Update lockfile.
