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

  # Load amdgpu in the initrd so KMS takes over before the root filesystem mounts.
  boot.initrd.kernelModules = [
    "ntsync"
    # "amdgpu"
  ];

  boot.kernelParams = [
    "amdgpu.ppfeaturemask=0xffffffff"
    # Use the primary monitor's native mode for the early framebuffer and TTYs.
    "video=DP-1:2560x1440"
  ];
  # TEMPORARILY DISABLED: scx_lavd 1.1.3 has a BPF stall regression
  # (nixpkgs#555996 / sched-ext/scx#3750) causing games to freeze after ~1 min
  # (journal: "runnable task stall (winedevice.exe failed to run for 38.688s)").
  # Kernel falls back to CachyOS's default BORE scheduler without this.
  # Re-enable once scx > 1.1.3 (or with a pinned 1.1.2) is verified stable.
  # services.scx = {
  #   enable = true;
  #   scheduler = "scx_lavd";
  # };

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
