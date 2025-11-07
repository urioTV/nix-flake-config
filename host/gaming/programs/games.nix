{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
{
  environment.systemPackages = with pkgs; [
    # Specific games
    vintagestory
    shadps4_git

    # Morrowind
    # openmw
    # openmw-dev
  ];

  # For Vintage Story
  nixpkgs.config.permittedInsecurePackages = [
    "gradle-7.6.6"
    "dotnet-runtime-wrapped-7.0.20"
    "dotnet-runtime-7.0.20"
  ];
}
