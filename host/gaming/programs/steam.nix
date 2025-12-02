{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
{
  programs.steam = {
    enable = true;
    # Gamescope Fix
    package = pkgs.steam.override {
      # extraEnv = { SDL_VIDEODRIVER = "x11"; };
      extraPkgs =
        pkgs: with pkgs; [
          xorg.libXcursor
          xorg.libXi
          xorg.libXinerama
          xorg.libXScrnSaver
          libpng
          libpulseaudio
          libvorbis
          stdenv.cc.cc.lib
          libkrb5
          keyutils
          curl
          openssl
          xdg-utils
        ];
    };
    extraCompatPackages = with pkgs; [
      proton-ge-custom
      proton-cachyos_nightly_x86_64_v4
    ];
    remotePlay.openFirewall = true; # Open ports in the firewall for Steam Remote Play
    dedicatedServer.openFirewall = true; # Open ports in the firewall for Source Dedicated Server
  };
}
