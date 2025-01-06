{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
{
  environment.systemPackages = with pkgs; [
    sidequest
    opencomposite
    wlx-overlay-s
  ];
  programs = {
    alvr = {
      enable = true;
      package = pkgs.alvr;
      openFirewall = true;
    };
  };
  services = {
    wivrn = {
      enable = true;
      openFirewall = true;
      defaultRuntime = true;
    };
  };

}
