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
  # NOTE: nixpkgs ships libratbag 0.18, which detects the G502 X Lightspeed
  # only when connected via USB cable (046d:c098). Wireless dongle support
  # (046d:409f) is in libratbag master. Profiles save to mouse onboard memory,
  # so configure via cable once and it works wirelessly afterwards.
  services.ratbagd.enable = true;

  environment.systemPackages = with pkgs; [
    solaar
    piper # GUI for ratbagd - remap G502 X buttons (use USB cable, see note above)
  ];

  boot.blacklistedKernelModules = [ "hid_logitech_hidpp" ];

  # environment.etc."libinput/local-overrides.quirks".text = ''
  #   [Logitech G502 X Wireless Receiver High-Res Scroll Disable]
  #   MatchVendor=0x046D
  #   MatchProduct=0xC548
  #   AttrEventCode=-REL_WHEEL_HI_RES;-REL_HWHEEL_HI_RES;
  # '';

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
