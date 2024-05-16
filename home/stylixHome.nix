{ config, lib, pkgs, ... }: {
  stylix.autoEnable = true;
  stylix.image = ../tech-driad.png;
  stylix.base16Scheme = ../catppuccin/mocha.yaml;
  # stylix.targets.gnome.enable = true;
  stylix.polarity = "dark";
  stylix.targets.vscode.enable = false;
  stylix.cursor.package = pkgs.qogir-icon-theme;
  stylix.cursor.name = "Qogir Cursors";
  # stylix.cursor.size = 24;

  gtk.iconTheme.package = pkgs.papirus-icon-theme;
  gtk.iconTheme.name = "Papirus";
  gtk.cursorTheme.package = pkgs.qogir-icon-theme;
  gtk.cursorTheme.name = "Qogir Cursors";

  gtk = {
    enable = true;

    gtk3.extraConfig = {
      Settings = ''
        gtk-application-prefer-dark-theme=1
      '';
    };

    gtk4.extraConfig = {
      Settings = ''
        gtk-application-prefer-dark-theme=1
	      gtk-cursor-theme-name=Qogir Cursors
      '';
    };
  };
}
