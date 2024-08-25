{ inputs, config, pkgs, chaotic, ... }: {

  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
    # theme = "sddm-chili-theme";
    # package = pkgs.kdePackages.sddm;
  };

  services.desktopManager.plasma6.enable = true;

  services = { flatpak.enable = true; };

  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [ kdePackages.kalk xdg-desktop-portal-gtk ];
  };

  environment.systemPackages = with pkgs; [
    (pkgs.writeTextDir "share/sddm/themes/breeze/theme.conf.user" ''
      [General]
      background=${config.vars.wallpaper}
    '')
    transmission_4-qt
    inputs.kwin-effects-forceblur.packages.${pkgs.system}.default
  ];
}
