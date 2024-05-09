{ config, lib, pkgs, ... }: {
  stylix.autoEnable = true;
  stylix.image = ../tech-driad.png;
  stylix.base16Scheme = ../catppuccin/mocha.yaml;
  stylix.targets.gnome.enable = true;
  stylix.polarity = "dark";
  stylix.targets.vscode.enable = false;
  stylix.cursor.package = pkgs.catppuccin-cursors.mochaDark;
  stylix.cursor.name = "Catppuccin-Mocha-Dark-Cursors";
  # stylix.cursor.size = 24;
}
