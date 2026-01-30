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

  # 1. Obsługa demona `ratbagd` (niezbędne dla Pipera)
  # To włącza usługę w tle i nadaje odpowiednie uprawnienia DBus.
  services.ratbagd.enable = true;

  # 2. Instalacja graficznego interfejsu Piper
  environment.systemPackages = with pkgs; [
    piper
  ];

  # 3. Obsługa sprzętu Logitech (Solaar i reguły udev)
  # To automatycznie instaluje Solaar i wgrywa reguły udev dla odbiorników Lightspeed/Unifying.
  hardware.logitech.wireless.enable = true;
  hardware.logitech.wireless.enableGraphical = true; # To instaluje GUI Solaar

  # hardware.openrazer = {
  #   enable = true;
  #   users = [ "urio" ];
  # };

  # Add user to gamemode group for gaming optimizations
  users.users.urio.extraGroups = [ "gamemode" ];
}
