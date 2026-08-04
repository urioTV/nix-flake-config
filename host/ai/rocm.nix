{ pkgs, ... }:
let
  # Radeon RX 9070 XT (Navi 48 / RDNA 4) is exposed by ROCm as gfx1201.
  # ROCm 7.2 packages include native gfx1201 kernels; using the regular package
  # set keeps binary-cache compatibility and avoids rebuilding the whole stack.
  rocmPackages = pkgs.rocmPackages;

  rocmEnv = pkgs.symlinkJoin {
    name = "rocm-gfx1201";
    paths = with rocmPackages; [
      rocblas
      hipblas
      hipblaslt
      clr
      clr.icd
      rocm-runtime
      rocm-device-libs
      rocm-comgr
      rpp
    ];
  };
in
{
  # OpenCL/HIP ICD used by applications going through hardware.graphics.
  hardware.graphics.extraPackages = [ rocmPackages.clr.icd ];

  # Compatibility path for software expecting the conventional ROCm layout.
  systemd.tmpfiles.rules = [
    "L+ /opt/rocm - - - - ${rocmEnv}"
  ];

  environment.variables = {
    ROCM_PATH = "/opt/rocm";
    HIP_PATH = "/opt/rocm";

    # Build third-party HIP code specifically for Navi 48. ROCm 7.2 detects
    # gfx1201 natively, so HSA_OVERRIDE_GFX_VERSION must not be set.
    AMDGPU_TARGETS = "gfx1201";
    GPU_TARGETS = "gfx1201";
  };

  environment.systemPackages = [
    pkgs.clinfo
    rocmPackages.rocminfo
    pkgs.amdgpu_top
  ];

  nixpkgs.config.rocmSupport = true;
}
