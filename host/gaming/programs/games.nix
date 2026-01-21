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
    version = "1.21.0";
    hash = "sha256-90YQOur7UhXxDBkGLSMnXQK7iQ6+Z8Mqx9PEG6FEXBs=";
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

  # For Vintage Story
  nixpkgs.config.permittedInsecurePackages = [
    "gradle-7.6.6"
    "dotnet-runtime-wrapped-7.0.20"
    "dotnet-runtime-7.0.20"
  ];
}
