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
      vulkan-loader
      vulkan-validation-layers
      vulkan-extension-layer
      libva

      # ROCm packages
      rocmPackages.clr.icd
      rocmPackages.rocblas
      rocmPackages.hipblas
      rocmPackages.clr
      rocmPackages.rocm-runtime
      rocmPackages.rocm-device-libs
      rocmPackages.rocm-comgr
      rocmPackages.rpp
    ];
  };
  # Symlink for applications requiring /opt/rocm
  systemd.tmpfiles.rules =
    let
      rocmEnv = pkgs.symlinkJoin {
        name = "rocm-combined";
        paths = with pkgs.rocmPackages; [
          rocblas
          hipblas
          clr
          clr.icd
          rocm-runtime
          rocm-device-libs
          rocm-comgr
          rpp
        ];
      };
    in
    [
      "L+ /opt/rocm - - - - ${rocmEnv}"
    ];

  # Environment variables
  environment.variables = {
    ROCM_PATH = "/opt/rocm";
    LD_LIBRARY_PATH = "/opt/rocm/lib";
    HSA_OVERRIDE_GFX_VERSION = "11.0.0"; # For RX 7000 series cards (RDNA 3)
  };

  environment.systemPackages = with pkgs; [
    clinfo
    rocmPackages.rocminfo
    amdgpu_top
  ];

  hardware.amdgpu.opencl.enable = true;
  nixpkgs.config.rocmSupport = true;

  hardware.steam-hardware.enable = true;
  hardware.xpadneo.enable = true;

  # Enable the X11 windowing system.
  services.xserver.enable = true;
  services.xserver.videoDrivers = [ "amdgpu" ];
  boot.initrd.kernelModules = [ "amdgpu" ];

  # Mesa-git
  # chaotic.mesa-git.enable = true;

  # Disable suspension on lid close
  # services.logind.lidSwitch = "lock";

  # Enables support for Bluetooth
  hardware.bluetooth.enable = true;
  # Powers on Bluetooth on boot
  hardware.bluetooth.powerOnBoot = true;
}
