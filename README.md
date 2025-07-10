# NixOS Configuration for konrad-m18

This is my personal NixOS configuration for quickly setting up my laptop, codenamed `konrad-m18`. It may be somewhat chaotic, as it's primarily intended for my own use.

## Important

If you decide to use this configuration, make sure to replace `hardware-configuration.nix` with your own file, generated for your specific hardware.

## Overview

This flake uses Nix to manage the entire system configuration, including:

- **Operating System:** NixOS
- **Window Manager:** KDE Plasma (see `host/plasma6/default.nix`, `home/plasma-manager.nix`)
- **Home Manager:** Used to manage user-specific configurations (see `home.nix`)
- **Stylix:** Used for theming and styling (see `host/stylix.nix` and `home/stylixHome.nix`). To configure Stylix, see the [Stylix documentation](https://github.com/danth/stylix).
- **Chaotic:** Used for additional packages and configurations. See the [Chaotic documentation](https://github.com/chaotic-cx/nyx).
- **Custom Packages:** A collection of custom Nix packages (see `custom-pkgs/`)

## Structure

The repository is structured as follows:

- **`configuration.nix`:** Main NixOS system configuration file.
- **`flake.nix`:** Defines the flake inputs and outputs, including NixOS configurations and Home Manager modules.
- **`flake.lock`:** Records the exact versions of all flake inputs.
- **`hardware-configuration.nix`:** Hardware-specific configuration (should be replaced with your own).
- **`home.nix`:** Home Manager configuration for the `urio` user.
- **`nix-settings.nix`:** Nix settings.
- **`overlay.nix`:** Nix package overlay for custom packages and overrides.
- **`vars.nix`:** Variables used in the configuration.
- **`custom-pkgs/`:** Contains custom Nix package definitions.

- **`home/`:** Contains Home Manager configurations.

- **`host/`:** Contains NixOS host configurations.

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

    ```bash
    sudo nixos-rebuild switch --flake .#konrad-m18
    ```

## Custom Packages

This configuration includes custom Nix packages defined in `custom-pkgs/overlay.nix`. These packages are integrated into the system via a Nix overlay.

For example, to use `scopebuddy` and `vintagestory`:

## Home Manager

Home Manager is used to manage user-specific configurations, such as dotfiles, shell settings, and applications. The Home Manager configuration is located in the `home.nix` file.

## Host Configuration

The `host/` directory contains NixOS host configurations. These configurations define system-wide settings, such as hardware configuration, networking, and services.

## Media

The `media/` directory contains media files, such as images and color schemes.
