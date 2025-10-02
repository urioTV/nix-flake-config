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
  hardware.xpadneo.enable = true;

  # Add user to gamemode group for gaming optimizations
  users.users.urio.extraGroups = [ "gamemode" ];
}
