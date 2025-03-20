{
  config,
  lib,
  pkgs,
  chaotic,
  ...
}:
{

  # boot.initrd.kernelModules = [ "ntsync" ];

  boot.kernelPackages = pkgs.linuxPackages_zen;
  # boot.kernelPackages = pkgs.linuxPackages_cachyos-lto;
  # boot.kernelPackages = pkgs.linuxPackages_cachyos;
  # boot.kernelPackages = pkgs.linuxPackages_latest;
  # boot.kernelPackages = pkgs.linuxPackages_xanmod_latest;

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
