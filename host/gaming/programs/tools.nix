{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
{
  environment.systemPackages = with pkgs; [
    # Gaming tools and utilities
    vkbasalt
    limo
    protonplus
    lsfg-vk
    lsfg-vk-ui
    mangohud
    goverlay
    winetricks
    wineWow64Packages.stable

    # Custom tools
    gperftools

  ];
}
