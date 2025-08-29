{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
{
  environment.systemPackages = with pkgs; [
    heroic
    lutris
    vkbasalt
    vintagestory
    shadps4_git
    limo
    scopebuddy
    protonplus
    lsfg-vk
    lsfg-vk-ui

    # Morrowind
    # openmw
    openmw-dev
  ];

  # For Vintage Story
  nixpkgs.config.permittedInsecurePackages = [
    "dotnet-runtime-wrapped-7.0.20"
    "dotnet-runtime-7.0.20"
  ];

  programs = {
    steam = {
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
      ];
      remotePlay.openFirewall = true; # Open ports in the firewall for Steam Remote Play
      dedicatedServer.openFirewall = true; # Open ports in the firewall for Source Dedicated Server
    };
    gamescope = {
      enable = true;
      # capSysNice = true;
      env = {
        # SDL_VIDEODRIVER = "x11";
      };
      args = [
        "-h 1200"
        "-w 1920"
        "-H 1200"
        "-W 1920"
        # "--adaptive-sync"
      ];
    };
    # gamemode = {
    #   enable = true;
    #   enableRenice = true;
    #   settings = {
    #     general = {
    #       renice = 10;
    #       reaper_freq = 5;
    #       desiredgov = "performance";
    #       igpu_desiredgov = "powersave";
    #       igpu_power_threshold = 0.3;
    #     };
    #     custom = {
    #       start = "${pkgs.libnotify}/bin/notify-send 'GameMode started'";
    #       end = "${pkgs.libnotify}/bin/notify-send 'GameMode ended'";
    #     };
    #   };
    # };
  };

}
