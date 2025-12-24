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
  boot.kernelParams = [
    "amd_pstate=active"
  ];
  services.power-profiles-daemon.enable = false;
  services.auto-cpufreq.enable = false;

  services.tlp = {
    enable = true;
    settings = {
      CPU_SCALING_GOVERNOR_ON_AC = "powersave";
      CPU_SCALING_GOVERNOR_ON_BAT = "powersave";

      CPU_ENERGY_PERF_POLICY_ON_AC = "balance_performance";
      CPU_ENERGY_PERF_POLICY_ON_BAT = "balance_power";

      PLATFORM_PROFILE_ON_AC = "balanced-performance";
      PLATFORM_PROFILE_ON_BAT = "balanced";

      CPU_BOOST_ON_AC = 1;
      CPU_BOOST_ON_BAT = 0;
    };
  };
}
