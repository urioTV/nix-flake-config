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
      # "gg.minion.Minion"
      "io.github.flattool.Warehouse"
      # "io.github.ryubing.Ryujinx"
      # "la.ogri.strongbox"
      "net.codelogistics.clicker"
      # "org.prismlauncher.PrismLauncher"
    ];
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
    inputs.kwin-effects-forceblur.packages.${pkgs.system}.default
    kdePackages.filelight
    kdePackages.kalk
    kdePackages.accounts-qt
    kdePackages.kaccounts-providers
    kdePackages.kaccounts-integration
    kdePackages.kmail-account-wizard
  ];

  environment.sessionVariables = {
    KWIN_USE_OVERLAYS = "1";
  };
}
