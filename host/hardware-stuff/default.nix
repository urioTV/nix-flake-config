{
  config,
  lib,
  pkgs,
  chaotic,
  ...
}:
{
  hardware.enableAllFirmware = true;

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    # driSupport = true;
    # driSupport32Bit = true;
    extraPackages = with pkgs; [
      rocmPackages.clr.icd
      vulkan-loader
      vulkan-validation-layers
      vulkan-extension-layer
      libva
    ];
  };

  hardware.steam-hardware.enable = true;
  hardware.xpadneo.enable = true;

  # Enable the X11 windowing system.
  services.xserver.enable = true;
  services.xserver.videoDrivers = [ "amdgpu" ];
  # boot.initrd.kernelModules = [ "amdgpu" ];

  # Mesa-git
  # chaotic.mesa-git.enable = true;

  # Disable suspention on lid close
  # services.logind.lidSwitch = "lock";

  # Enables support for Bluetooth
  hardware.bluetooth.enable = true;
  # Powers on Bluetooth on boot
  hardware.bluetooth.powerOnBoot = true;
}
