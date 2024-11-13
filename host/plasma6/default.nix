{
  inputs,
  config,
  pkgs,
  chaotic,
  ...
}:
{

  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
    # theme = "sddm-chili-theme";
    # package = pkgs.kdePackages.sddm;
  };

  services.desktopManager.plasma6.enable = true;

  services = {
    flatpak.enable = true;
  };

  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk
    ];
  };

  environment.systemPackages = with pkgs; [
    (pkgs.writeTextDir "share/sddm/themes/breeze/theme.conf.user" ''
      [General]
      background=${config.vars.wallpaper}
    '')
    # transmission_4-qt
    qbittorrent
    inputs.kwin-effects-forceblur.packages.${pkgs.system}.default
    kdePackages.filelight
    kdePackages.kalk
    kdePackages.accounts-qt
    kdePackages.kaccounts-providers
    kdePackages.kaccounts-integration
    kdePackages.kmail-account-wizard
  ];
}
