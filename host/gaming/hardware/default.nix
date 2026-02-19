{
  config,
  lib,
  pkgs,
  chaotic,
  ...
}:
{

  # Gaming hardware support
  hardware.steam-hardware.enable = true;
  # hardware.xpadneo.enable = true;

  # Mouse configuration daemon (required for Piper)
  services.ratbagd.enable = true;

  environment.systemPackages = with pkgs; [
    piper
  ];

  # Logitech hardware support (Solaar + udev rules)
  hardware.logitech.wireless.enable = true;
  hardware.logitech.wireless.enableGraphical = true; # Installs Solaar GUI

  # hardware.openrazer = {
  #   enable = true;
  #   users = [ "urio" ];
  # };

  # Add user to gamemode group for gaming optimizations
  users.users.urio.extraGroups = [ "gamemode" ];
}
