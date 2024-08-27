{ config, lib, pkgs, ... }: {
  imports = [ ./nix-ld.nix ];
  programs = {
    steam = {
      enable = true;
      # protontricks.enable = true;
      # Gamescope Fix
      package = pkgs.steam.override {
        # extraEnv = { SDL_VIDEODRIVER = "x11"; };
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
      extraCompatPackages = with pkgs; [  ];
      remotePlay.openFirewall =
        true; # Open ports in the firewall for Steam Remote Play
      dedicatedServer.openFirewall =
        true; # Open ports in the firewall for Source Dedicated Server
    };
    zsh = { enable = true; };
    corectrl = {
      enable = true;
      gpuOverclock.enable = true;
      # gpuOverclock.ppfeaturemask = "0xffffffff";
    };
    gamescope = {
      enable = true;
      # capSysNice = true;
      # package = pkgs.gamescope_git;
      env = { SDL_VIDEODRIVER = "x11"; };
      args = [ "-h 1200" "-w 1920" "-H 1200" "-W 1920" "--adaptive-sync" ];
    };
    gamemode = {
      enable = true;
      enableRenice = true;
    };
    nix-ld.enable = true;
    java = {
      enable = true;
      package = pkgs.corretto21;
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

  virtualisation.libvirtd = {
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

  users.users.urio = { extraGroups = [ "libvirtd" ]; };

}
