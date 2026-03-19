# NixOS Configuration for konrad-m18

This is my personal NixOS configuration for quickly setting up my laptop, codenamed `konrad-m18`. It may be somewhat chaotic, as it's primarily intended for my own use.

## Important

If you decide to use this configuration, make sure to replace `hardware-configuration.nix` with your own file, generated for your specific hardware.

## Overview

This flake uses Nix to manage the entire system configuration, including:

- **Operating System:** NixOS
- **Window Manager:** **KDE Plasma** (see `host/plasma6/default.nix`, `home/plasma-manager.nix`)
- **Home Manager:** Used to manage user-specific configurations (see `home.nix`)
- **Stylix:** Used for theming and styling (see `stylix-config.nix`)
- **Custom Packages:** Custom packages defined in `overlay.nix` and `urio-nur` flake input
- **Dotfiles:** Manages dotfiles for various applications (see `dotfiles/`)
- **Gaming:** Comprehensive gaming setup with modular configuration (see `host/gaming/`)

## Flake Inputs

This configuration uses the following main flake inputs:

- **nixpkgs:** NixOS unstable packages
- **home-manager:** User environment management
- **stylix:** System-wide styling and theming
- **urio-nur:** Personal NUR repository
- **plasma-manager:** KDE Plasma configuration management
- **apple-fonts:** Apple font collection
- **nix-alien:** Tool for running unpatched binaries
- **zen-browser:** Privacy-focused Firefox fork
- **nix-gaming:** Gaming-related packages and optimizations
- **openmw-nix:** OpenMW game engine packages
- **kwin-effects-better-blur-dx:** Better blur effect for KWin (replacing forceblur)
- **determinate:** Determinate Systems Nix installer
- **nix-flatpak:** Declarative Flatpak management
- **sops-nix:** Secrets management using sops
- **opencode-dev:** Developer version of Opencode AI
- **import-tree:** Automated directory importing for Nix
- **flake-parts:** Modular flake organization

## Structure

The repository is structured as follows:

- **`configuration.nix`:** Main NixOS system configuration file
- **`flake.nix`:** Defines the flake inputs and outputs, including NixOS configurations and Home Manager modules
- **`flake.lock`:** Records the exact versions of all flake inputs
- **`hardware-configuration.nix`:** Hardware-specific configuration (should be replaced with your own)
- **`home.nix`:** Home Manager configuration for the `urio` user
- **`nix-settings.nix`:** Nix settings
- **`overlay.nix`:** Nix package overlay for custom packages and overrides
- **`vars.nix`:** Variables used in the configuration
- **`sops-config.nix`:** Configuration for `sops-nix`
- **`AGENTS.md`:** Documentation and conventions for AI assistants
- **`dotfiles/`:** Contains dotfiles for various applications
- **`home/`:** Contains Home Manager configurations (AI, programs, services)
- **`host/`:** Contains NixOS host configurations
- **`sops/`:** Contains encrypted secrets
- **`host/gaming/`:** Modular gaming configuration (hardware, programs, audio)
- **`media/`:** Contains media files, such as images and color schemes

## Gaming Configuration

This configuration includes a comprehensive, modular gaming setup organized in `host/gaming/`:

- **Hardware:** `host/gaming/hardware/` (Steam hardware, udev rules)
- **Programs:** `host/gaming/programs/` (Steam, Launchers, Tools, Gamescope)
- **Audio:** `host/gaming/audio/` (Gaming-specific PipeWire rules)

### Gaming Features

- **Steam:** Full Steam configuration with Proton-GE compatibility layer
- **Game Launchers:** Heroic Games Launcher for Epic Games, Lutris for various platforms
- **Gaming Tools:** VkBasalt for visual enhancements, Protonplus for Proton management
- **Hardware Support:** Xbox controller support via xpadneo, Steam hardware integration
- **Audio Optimization:** Specialized PipeWire configuration for games like Warframe
- **Gamescope:** Wayland compositor for improved gaming performance
- **Custom Games:** Vintage Story, OpenMW (Morrowind), PlayStation 4 emulation

## Usage

To use this configuration:

1.  Clone the repository:

    ```bash
    git clone https://github.com/urioTV/nix-flake-config.git
    cd nix-flake-config
    ```

2.  Replace `hardware-configuration.nix` with your own hardware configuration. You can generate one using:

    ```bash
    sudo nixos-generate-config --show-hardware-config > hardware-configuration.nix
    ```

3.  Apply the configuration:

    Using **nh** (preferred):
    ```bash
    nh os switch
    ```

    Standard rebuild:
    ```bash
    sudo nixos-rebuild switch --flake .#konrad-m18
    ```

4.  Updating inputs:
    ```bash
    nix flake update
    ```

### Disabling Gaming

To disable the entire gaming setup, you can comment out the gaming imports in `host/default.nix` (if present) or the relevant modules in `configuration.nix`.

## Window Manager

This configuration uses **KDE Plasma** as the desktop environment.

## Custom Packages

This configuration includes custom Nix packages defined in `overlay.nix` and imported from `urio-nur`. These packages are automatically loaded via a Nix overlay and can be used throughout the configuration.

## Home Manager

Home Manager is used to manage user-specific configurations, such as dotfiles, shell settings, and applications. The Home Manager configuration is located in the `home.nix` file, which imports modules from the `home/` directory.

## Host Configuration

The `host/` directory contains NixOS host configurations. These configurations define system-wide settings, such as hardware configuration, networking, and services.

### Host Modules

- **`ai/`:** AI and LLM-related configurations
- **`boot-kernel-stuff/`:** Boot and kernel configurations
- **`filesystems/`:** Filesystem configurations
- **`gaming/`:** Comprehensive gaming setup (Steam, launchers, tools)
- **`hardware-stuff/`:** Hardware-specific configurations
- **`networking/`:** Network configurations
- **`pkgs/`:** System packages organized by category
- **`plasma6/`:** KDE Plasma 6 configurations
- **`programs/`:** System programs and applications
- **`services/`:** System services
- **`virtualisation/`:** Container and virtualization setup

## Additional Features

### Theming and Styling

- **Stylix** is used for theming and styling (see `stylix-config.nix`)
- **Base16 Schemes** are available in `media/base16Schemes/` for consistent color schemes across applications
- **Apple Fonts** are included via the `apple-fonts` flake input

### Development

- **Development tools** and editors are configured (see `host/pkgs/development.nix`)
- **Dotfiles** for development environments are managed in `dotfiles/`

### Virtualization

- **Podman** is configured for container management (see `host/virtualisation/default.nix`)
- **Qemu KVM** and **virt-manager** are available for virtualization (see `host/virtualisation/default.nix`)

## AI & Agent Configuration

This configuration includes advanced AI and coding agent setups:

- **Opencode:** Configured in `home/programs/ai/opencode/` with various providers and models.
- **Claude Code:** Configured in `home/programs/ai/claude-code/`.
- **System-level AI:** AI bundles and packages handled in `host/ai/`.

## Secrets Management

Secrets like API keys are managed using **sops-nix**.

- **Secrets file:** `sops/secrets/secrets.yaml` (encrypted with `age`).
- **Configuration:** `sops-config.nix`.
- **Usage:** Secrets are referenced via `config.sops.secrets.<name>.path`.

## Technical Documentation for AI

For detailed technical information, coding conventions, and common commands, refer to [AGENTS.md](file:///home/urio/nix-flake-config/AGENTS.md). This file is specifically maintained to help AI assistants understand and work with this codebase.

## Formatting

The project uses `nixfmt` for consistent formatting:

```bash
nixfmt .
```
