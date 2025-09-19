# NixOS Configuration for konrad-m18

This is my personal NixOS configuration for quickly setting up my laptop, codenamed `konrad-m18`. It may be somewhat chaotic, as it's primarily intended for my own use.

## Important

If you decide to use this configuration, make sure to replace `hardware-configuration.nix` with your own file, generated for your specific hardware.

## Overview

This flake uses Nix to manage the entire system configuration, including:

- **Operating System:** NixOS
- **Window Manager:**
    - **KDE Plasma:** The default window manager (see `host/plasma6/default.nix`, `home/plasma-manager.nix`).
- **Home Manager:** Used to manage user-specific configurations (see `home.nix`).
- **Stylix:** Used for theming and styling (see `host/stylix.nix` and `home/stylixHome.nix`).
- **Chaotic-Nyx:** An unofficial binary cache for a large collection of Nix packages, which can significantly speed up installations and system updates. It provides bleeding-edge packages, including `-git` versions, similar to the Chaotic-AUR project for Arch Linux.
- **Custom Packages:** A collection of custom Nix packages (see `custom-pkgs/`).
- **Dotfiles:** Manages dotfiles for various applications (see `dotfiles/`).

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
- **`dotfiles/`:** Contains dotfiles for various applications, such as Zed.
- **`home/`:** Contains Home Manager configurations.
- **`host/`:** Contains NixOS host configurations.
- **`media/`:** Contains media files, such as images and color schemes.

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

## Window Manager

This configuration uses **KDE Plasma** as the default window manager.

## Custom Packages

This configuration includes custom Nix packages defined in `custom-pkgs/overlay.nix`. These packages are automatically loaded via a Nix overlay and can be used throughout the configuration.

For example, `scopebuddy` and `vintagestory` are defined in `custom-pkgs/` and can be added to your environment like any other package.

## Home Manager

Home Manager is used to manage user-specific configurations, such as dotfiles, shell settings, and applications. The Home Manager configuration is located in the `home.nix` file, which imports modules from the `home/` directory.

## Host Configuration

The `host/` directory contains NixOS host configurations. These configurations define system-wide settings, such as hardware configuration, networking, and services. The main file is `host/default.nix`, which imports other modules from the same directory.

## Additional Features

### Theming and Styling

- **Stylix** is used for theming and styling (see `host/stylix.nix` and `home/stylixHome.nix`).
- **Base16 Schemes** are available in `media/base16Schemes/` for consistent color schemes across applications.
- **Apple Fonts** are included via the `apple-fonts` flake input.

### Gaming

- **Gamescope** is configured for better gaming performance (see `host/programs/gaming.nix`).
- **Steam** is configured with custom compatibility packages (see `host/programs/gaming.nix`).
- **Custom gaming packages** like `scopebuddy` and `vintagestory` are defined in `custom-pkgs/`.

### Development

- **Zed Editor** is configured with custom settings (see `dotfiles/zed/`).
- **Development tools** like `dotnet-sdk`, `nixd`, and `nixfmt-rfc-style` are included (see `host/pkgs/development.nix`).

### Virtualization

- **Podman** is configured for container management (see `host/virtualisation/default.nix`).
- **Qemu KVM** and **virt-manager** are available for virtualization (see `host/virtualisation/default.nix`).

### VR Gaming

- **ALVR** and **Envision** are configured for VR gaming (see `host/vr-gaming/default.nix`).
- **OpenComposite** and **Wivrn** are available for VR compatibility (see `host/vr-gaming/default.nix`).