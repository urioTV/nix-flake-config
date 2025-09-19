# Configuration Cleanup

## Hyprland Removal - 2025-09-19

Complete removal of Hyprland configuration from master branch:

### Files Removed:
- `dotfiles/hypr/hyprland.conf` - Main Hyprland configuration
- `home/hyprland/default.nix` - Home Manager Hyprland module
- `host/hyprland/default.nix` - System-level Hyprland configuration

### Files Updated:
- `README.md` - Removed all Hyprland references and mentions

### Backup:
All removed Hyprland configuration is preserved in the `hyprland-old-config` branch for future reference.

### System Configuration:
The system now uses KDE Plasma as the sole desktop environment.
