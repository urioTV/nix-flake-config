{
  config,
  lib,
  pkgs,
  inputs,
  nixpkgs-alvr,
  ...
}:
{
  environment.systemPackages = with pkgs; [
    # sidequest
    # opencomposite
    # wlx-overlay-s
    # xrizer
  ];
  # programs = {
  #   alvr = {
  #     enable = true;
  #     openFirewall = true;
  #   };
  #   envision = {
  #     enable = true;
  #     openFirewall = true;
  #   };
  # };
  # services = {
  #   wivrn = {
  #     enable = false;
  #     openFirewall = true;
  #     # defaultRuntime = true;
  #   };
  # };

}
