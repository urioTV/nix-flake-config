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
  # boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.kernelPackages = pkgs.linuxPackages_xanmod_latest;

  # hardware.firmware = [
  #   (inputs.nixpkgs-old.legacyPackages."x86_64-linux".linux-firmware)
  # ];

  boot.initrd.kernelModules = [ "ntsync" ];

  boot.blacklistedKernelModules = [
    "ucsi_acpi" # WINOWAJCA: Interface ACPI do USB-C (to on sypie błędami ze zdjęcia)
    "typec_ucsi" # Podsystem powiązany z powyższym
    "sp5100_tco" # Watchdog, który może resetować/zamrażać system przy starcie
    "i2c_piix4" # Częsty konflikt na płytach AMD, warto wyłączyć profilaktycznie
  ];

  boot.kernelParams = [
    "amdgpu.dcdebugmask=0x10"
    "amdgpu.ppfeaturemask=0xffffffff"

    "pcie_aspm=off"
    "acpi_osi=!"
    "acpi_osi=\"Windows 2020\""
    "iommu=soft"
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
