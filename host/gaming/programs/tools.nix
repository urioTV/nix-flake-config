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
    scopebuddy
    protonplus
    lsfg-vk
    lsfg-vk-ui
  ];
}
