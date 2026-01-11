{
  config,
  lib,
  pkgs,
  ...
}:
{
  stylix = {
    enable = true;
    autoEnable = true;
    image = config.vars.wallpaper;
    base16Scheme = config.vars.base16Scheme;
    polarity = "dark";

    cursor = {
      package = pkgs.bibata-cursors;
      name = "Bibata-Modern-Classic";
      size = 20;
    };

    targets = {
      gnome.enable = true;
      gtk.enable = true;
      chromium.enable = false;
      grub.enable = false;
    };
  };

  qt.platformTheme = lib.mkForce "kde";
}
