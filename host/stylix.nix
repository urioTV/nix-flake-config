{
  config,
  lib,
  pkgs,
  ...
}:
{
  stylix.enable = true;
  stylix.autoEnable = true;
  stylix.image = config.vars.wallpaper;
  stylix.base16Scheme = config.vars.base16Scheme;
  stylix.cursor.package = pkgs.bibata-cursors;
  stylix.cursor.name = "Bibata-Modern-Classic";
  stylix.targets.gnome.enable = true;
  stylix.targets.gtk.enable = true;
  stylix.cursor.size = 20;
  stylix.polarity = "dark";

}
