{ config, lib, pkgs, urio-wallpaper, ... }: {
  stylix.enable = true;
  stylix.autoEnable = true;
  stylix.image = config.vars.wallpaper;
  stylix.base16Scheme = config.vars.base16Scheme;
  stylix.targets.gnome.enable = true;
  stylix.targets.gtk.enable = true;
  stylix.polarity = "dark";
  stylix.targets.vscode.enable = false;
  stylix.cursor.package = pkgs.bibata-cursors;
  stylix.cursor.name = "Bibata-Modern-Classic";
  stylix.cursor.size = 20;

  gtk.cursorTheme.package = pkgs.bibata-cursors;
  gtk.cursorTheme.name = "Bibata-Modern-Classic";
  gtk.cursorTheme.size = 20;

  gtk.iconTheme.package = pkgs.papirus-icon-theme;
  gtk.iconTheme.name = "Papirus";

  gtk = {
    enable = true;

    gtk3.extraConfig = { gtk-application-prefer-dark-theme = 1; };

    gtk4.extraConfig = {
      gtk-application-prefer-dark-theme = 1;
      #gtk-cursor-theme-name = "Qogir Cursors";
    };
  };

  xdg.systemDirs.data = [
    "${pkgs.gtk3}/share/gsettings-schemas/${pkgs.gtk3.name}"
    "${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/${pkgs.gsettings-desktop-schemas.name}"
  ];

}
