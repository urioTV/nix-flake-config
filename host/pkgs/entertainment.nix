{
  config,
  lib,
  pkgs,
  chaotic,
  inputs,
  ...
}:
{

  imports = [
    # Include the results of the hardware scan.

  ];

  environment.systemPackages = with pkgs; [
    # Entertainment and Media
    vlc
    heroic
    lutris
    openmw
    vkbasalt
    vintagestory

    galaxy-buds-client
  ];

  # For Vintage Story
  nixpkgs.config.permittedInsecurePackages = [
    "dotnet-runtime-wrapped-7.0.20"
    "dotnet-runtime-7.0.20"
  ];

}
