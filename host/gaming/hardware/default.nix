{
  config,
  lib,
  pkgs,
  chaotic,
  ...
}:
{
  imports = [
    ./udev-rules.nix
  ];

  # Gaming hardware support
  hardware.steam-hardware.enable = true;
  # hardware.xpadneo.enable = true;

  # hardware.openrazer = {
  #   enable = true;
  #   users = [ "urio" ];
  # };

  environment.systemPackages = with pkgs; [
    # polychromatic
  ];

  # Add user to gamemode group for gaming optimizations
  users.users.urio.extraGroups = [ "gamemode" ];
}
