{ config, lib, pkgs, ... }: {
  stylix.enable = true;
  stylix.autoEnable = true;
  stylix.image = ../tech-driad.png;
  stylix.base16Scheme = ../catppuccin/mocha.yaml;
  stylix.cursor.package = pkgs.bibata-cursors;
  stylix.cursor.name = "Bibata-Modern-Classic";
  stylix.targets.gnome.enable = true;
  stylix.cursor.size = 20;
  stylix.polarity = "dark";

}
