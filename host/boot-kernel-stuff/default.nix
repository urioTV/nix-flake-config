{
  config,
  lib,
  pkgs,
  chaotic,
  inputs,
  ...
}:
{

  # boot.kernelPackages = pkgs.linuxPackages_zen;
  # boot.kernelPackages = pkgs.linuxPackages_latest;
  # boot.kernelPackages = pkgs.linuxPackages_xanmod_stable;
  boot.kernelPackages = pkgs.cachyosKernels.linuxPackages-cachyos-latest-lto-x86_64-v4;

  # hardware.firmware = [
  #   (inputs.nixpkgs-old.legacyPackages."x86_64-linux".linux-firmware)
  # ];

  boot.initrd.kernelModules = [ "ntsync" ];

  boot.kernelParams = [
    "amdgpu.ppfeaturemask=0xffffffff"
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

  # zramSwap = {
  #   enable = true;
  #   memoryPercent = 50;
  # };

  boot.loader = {
    efi = {
      canTouchEfiVariables = true;
      # efiSysMountPoint = "/boot/efi"; # Must match hardware-configuration.nix
    };
    # grub = {
    #   enable = true;
    #   device = "nodev";
    #   efiSupport = true;
    #   configurationLimit = 10;
    #   theme = "${pkgs.cybergrub2077}/";
    # };
    limine = {
      enable = true;
      efiSupport = true;
      maxGenerations = 10;
    };
  };

}
