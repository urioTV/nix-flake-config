{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
{
  imports = [
    ./steam.nix
    ./launchers.nix
    ./tools.nix
    ./games.nix
    ./gamescope.nix
  ];
}
