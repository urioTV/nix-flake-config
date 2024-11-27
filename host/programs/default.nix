{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
{
  imports = [ ./nix-ld.nix ];
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
          ];
      };
      extraCompatPackages = with pkgs; [ ];
      remotePlay.openFirewall = true; # Open ports in the firewall for Steam Remote Play
      dedicatedServer.openFirewall = true; # Open ports in the firewall for Source Dedicated Server
    };
    zsh = {
      enable = true;
    };
    corectrl = {
      enable = true;
      gpuOverclock.enable = true;
      # gpuOverclock.ppfeaturemask = "0xffffffff";
    };
    gamescope = {
      enable = true;
      # capSysNice = true;
      env = {
        SDL_VIDEODRIVER = "x11";
      };
      args = [
        "-h 1200"
        "-w 1920"
        "-H 1200"
        "-W 1920"
        "--adaptive-sync"
      ];
    };
    gamemode = {
      enable = true;
      enableRenice = true;
      settings = {
        general = {
          renice = 10;
          reaper_freq = 5;
          desiredgov = "performance";
          igpu_desiredgov = "powersave";
          igpu_power_threshold = 0.3;
        };
        custom = {
          start = "${pkgs.libnotify}/bin/notify-send 'GameMode started'";
          end = "${pkgs.libnotify}/bin/notify-send 'GameMode ended'";
        };
      };
    };
    nix-ld.enable = true;
    java = {
      enable = true;
      package = pkgs.corretto21;
    };
    appimage = {
      enable = true;
      binfmt = true;
    };
  };

  # security.wrappers.steam = {
  #   owner = "root";
  #   group = "root";
  #   source = "${pkgs.steam}/bin/steam";
  #   capabilities = "cap_sys_nice=eip";
  # };

  # virtualisation.virtualbox.host.enable = true;
  # users.extraGroups.vboxusers.members = [ "urio" ];

  # Qemu KVM and virt-manager

  programs.virt-manager.enable = true;

  virtualisation = {
    docker = {
      enable = true;
    };
    libvirtd = {
      enable = true;
      qemu = {
        package = pkgs.qemu_kvm;
        runAsRoot = true;
        swtpm.enable = true;
        ovmf = {
          enable = true;
          packages = [
            (pkgs.OVMF.override {
              secureBoot = true;
              tpmSupport = true;
            }).fd
          ];
        };
      };
    };
  };

  users.users.urio = {
    extraGroups = [ "libvirtd" ];
  };

}
