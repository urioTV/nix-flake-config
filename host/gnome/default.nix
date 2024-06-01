{ inputs, config, pkgs, chaotic, ... }: {
  # Enable the GNOME Desktop Environment.
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.desktopManager.gnome.enable = true;

  services = { flatpak.enable = true; };

  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [ ];
  };

  environment.systemPackages = with pkgs; [
    gnome.gnome-tweaks
    gnome-extension-manager
  ];
}
