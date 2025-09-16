{
  config,
  lib,
  pkgs,
  chaotic,
  inputs,
  system,
  ...
}:
{
  # boot.kernelPackages = pkgs.linuxPackages_zen;
  # boot.kernelPackages = pkgs.linuxPackages_cachyos-lto;
  # boot.kernelPackages = pkgs.linuxPackages_cachyos;
  boot.kernelPackages = pkgs.linuxPackages_latest;
  # boot.kernelPackages = pkgs.linuxPackages_6_12;
  # boot.kernelPackages = inputs.nixpkgs-old.legacyPackages."x86_64-linux".linuxPackages_6_13;

  # Zastosuj patch do kernela
  # boot.kernelPatches = [
  #   {
  #     name = "issue4414_no_error_single_process";
  #     patch = ./issue4414_no_error_single_process.patch;
  #   }
  #   {
  #     name = "print_mes_fw_version";
  #     patch = ./print_mes_fw_version.patch;
  #   }
  # ];

  # NTSYNC patch
  # boot.kernelPatches = [
  #   {
  #     name = "ntsync";
  #     patch = pkgs.fetchurl {
  #       url = "https://raw.githubusercontent.com/CachyOS/kernel-patches/master/6.12/0005-ntsync.patch";
  #       sha256 = "sha256-KaSOBV81NYET0kXMNwuFvIuy1pf3R04lNuE3ZjA4oak=";
  #     };
  #     extraConfig = ''
  #       NTSYNC m
  #     '';
  #   }
  # ];

  boot.initrd.kernelModules = [ "ntsync" ];

  # users.groups.ntsync = { };

  # services.udev.extraRules = ''
  #   KERNEL=="ntsync", GROUP="ntsync", MODE="0664"
  # '';

  # users.users.urio = {
  #   extraGroups = [ "ntsync" ];
  # };

  boot.kernelParams = [
    "amdgpu.dcdebugmask=0x10"
  ];

  services.scx = {
    enable = true;
    scheduler = "scx_lavd";
  };

  boot.kernel.sysctl = {
    "vm.max_map_count" = 16777216;
    "fs.file-max" = 524288;
  };

  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

  zramSwap = {
    enable = true;
    memoryPercent = 50;
  };

  boot.loader = {
    efi = {
      canTouchEfiVariables = true;
      # efiSysMountPoint = "/boot/efi"; # ← use the same mount point here.
    };
    #grub = {
    #  enable = true;
    #  efiSupport = true;
    #  #efiInstallAsRemovable = true; # in case canTouchEfiVariables doesn't work for your system
    #  device = "nodev";
    #};
    systemd-boot.enable = true;
  };

}
