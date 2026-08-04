{
  config,
  lib,
  pkgs,
  chaotic,
  inputs,
  ...
}:
{
  boot.kernelParams = [
    "amd_pstate=active"
  ];
  powerManagement.cpuFreqGovernor = "performance";
}
