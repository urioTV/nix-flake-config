{ config, lib, pkgs, ... }:
{
  # ROCm Graphics Support for AI/LLM workloads
  hardware.graphics = {
    extraPackages = with pkgs; [
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

  # Environment variables for ROCm
  environment.variables = {
    ROCM_PATH = "/opt/rocm";
    LD_LIBRARY_PATH = "/opt/rocm/lib";
    HSA_OVERRIDE_GFX_VERSION = "11.0.0"; # For RX 7000 series cards (RDNA 3)
  };

  # ROCm utility packages
  environment.systemPackages = with pkgs; [
    clinfo
    rocmPackages.rocminfo
    amdgpu_top
  ];

  # Enable ROCm support in nixpkgs
  nixpkgs.config.rocmSupport = true;
}
