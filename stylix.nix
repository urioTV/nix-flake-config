{ config, lib, pkgs, ... }:
{
  stylix.autoEnable = true;
  stylix.image = ./tech-driad.png;
  stylix.base16Scheme = ./catppuccin/mocha.yaml;
  stylix.targets.gnome.enable = true;
  stylix.polarity = "dark";
}
