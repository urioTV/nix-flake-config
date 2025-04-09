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
    # (pkgs.vintagestory.overrideAttrs (oldAttrs: {
    #   postFixup =
    #     (oldAttrs.postFixup or "")
    #     + ''
    #       wrapProgram $out/bin/vintagestory \
    #         --set MESA_LOADER_DRIVER_OVERRIDE zink \
    #         --set GALLIUM_DRIVER zink
    #     '';
    # }))
    vintagestory

    galaxy-buds-client
  ];

  # For Vintage Story
  nixpkgs.config.permittedInsecurePackages = [
    "dotnet-runtime-wrapped-7.0.20"
    "dotnet-runtime-7.0.20"
  ];

}
