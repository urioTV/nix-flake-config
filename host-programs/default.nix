{ config, lib, pkgs, ... }: {
  programs = {
    steam = {
      enable = true;
      # Gamescope Fix
      package = pkgs.steam.override {
        extraEnv = { };
        extraPkgs = pkgs:
          with pkgs; [
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
          ];
      };
      remotePlay.openFirewall =
        true; # Open ports in the firewall for Steam Remote Play
      dedicatedServer.openFirewall =
        true; # Open ports in the firewall for Source Dedicated Server
    };
    zsh.enable = true;
    corectrl = {
      enable = true;
      gpuOverclock.enable = true;
      # gpuOverclock.ppfeaturemask = "0xffffffff";
    };
    gamescope = {
      enable = true;
      # capSysNice = true;
      package = pkgs.gamescope_git;
      env = { SDL_VIDEODRIVER = "x11"; };
      args = [ "-h 1200" "-w 1920" "-H 1200" "-W 1920" ];
    };
    nix-ld.enable = true;
    java = {
      enable = true;
      package = pkgs.jdk17;
    };
  };
}