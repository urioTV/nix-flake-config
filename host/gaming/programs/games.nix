{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
{
  programs.vintagestory = {
    enable = true;
    version = "1.21.6";
    hash = "sha256-LkiL/8W9MKpmJxtK+s5JvqhOza0BLap1SsaDvbLYR0c=";
  };

  environment.systemPackages = with pkgs; [
    # Specific games
    # vintagestory
    # shadps4_git

    # Morrowind
    # openmw
    # openmw-dev
    inputs.hytale-launcher.packages.${pkgs.system}.default
  ];

  # # For Vintage Story
  # nixpkgs.config.permittedInsecurePackages = [
  #   "gradle-7.6.6"
  #   "dotnet-runtime-wrapped-7.0.20"
  #   "dotnet-runtime-7.0.20"
  # ];
}
