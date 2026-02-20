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
    autoNumlock = true;
    wayland.enable = true;
  };

  services.desktopManager.plasma6.enable = true;

  services.flatpak = {
    enable = true;
    update = {
      onActivation = true;
    };
    packages = [
      "com.github.tchx84.Flatseal"
      "com.microsoft.Edge"
      "com.mikrotik.WinBox"
      "com.rustdesk.RustDesk"
      "com.spotify.Client"
      "com.stremio.Stremio"
      "io.github.flattool.Warehouse"
      "net.codelogistics.clicker"
      "com.usebottles.bottles"
    ];
    overrides = {
      global = {
        Context.filesystems = [
          "/run/current-system/sw/share/icons:ro"
          "/run/current-system/sw/share/fonts:ro"
        ];
      };
    };
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
    inputs.kwin-effects-better-blur-dx.packages.${pkgs.system}.default
    kdePackages.filelight
    kdePackages.kalk
    kdePackages.accounts-qt
    kdePackages.kaccounts-providers
    kdePackages.kaccounts-integration
    kdePackages.kmail-account-wizard
    adwaita-icon-theme
  ];

  environment.sessionVariables = {
    KWIN_USE_OVERLAYS = "1";
  };
}
