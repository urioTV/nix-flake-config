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
  imports = [
    ./cpu-power.nix
  ];

  # boot.kernelPackages = pkgs.linuxPackages_zen;
  boot.kernelPackages = pkgs.linuxPackages_latest;
  # boot.kernelPackages = pkgs.linuxPackages_6_17;
  # boot.kernelPackages = pkgs.linuxPackages_testing;
  # boot.kernelPackages = inputs.nixpkgs-old.legacyPackages."x86_64-linux".linuxPackages_latest;

  # hardware.firmware = [
  #   (inputs.nixpkgs-old.legacyPackages."x86_64-linux".linux-firmware)
  # ];

  boot.initrd.kernelModules = [ "ntsync" ];

  boot.blacklistedKernelModules = [ "efi_pstore" ];

  boot.kernelParams = [
    "amdgpu.dcdebugmask=0x10"
    "pstore.backend=null"
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
      # efiSysMountPoint = "/boot/efi"; # ← use the same mount point here.
    };
    grub = {
      enable = true;
      device = "nodev";
      efiSupport = true;
      configurationLimit = 10;
      theme = "${pkgs.cybergrub2077}/";
    };
  };

}
