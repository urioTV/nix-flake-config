{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  hydralauncher-wayland = pkgs.hydralauncher.overrideAttrs (oldAttrs: {
    nativeBuildInputs = (oldAttrs.nativeBuildInputs or [ ]) ++ [ pkgs.makeWrapper ];

    extraInstallCommands = (oldAttrs.extraInstallCommands or "") + ''
      wrapProgram $out/bin/hydralauncher \
        --add-flags "\''${NIXOS_OZONE_WL:+\''${WAYLAND_DISPLAY:+--ozone-platform-hint=auto --enable-features=UseOzonePlatform,WaylandWindowDecorations --enable-wayland-ime=true}}"
    '';
  });
in
{
  environment.systemPackages = with pkgs; [
    # Gaming launchers
    hydralauncher-wayland
    heroic
    lutris
  ];
}
