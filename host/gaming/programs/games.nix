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
    openmw-dev
  ];

  # For Vintage Story
  nixpkgs.config.permittedInsecurePackages = [
    "dotnet-runtime-wrapped-7.0.20"
    "dotnet-runtime-7.0.20"
  ];
}
