{
  inputs,
  config,
  pkgs,
  chaotic,
  ...
}:
{
  imports = [
    # Include the results of the hardware scan.
    ./stylixHome.nix
    ./plasma-manager.nix
    ./pkgs
    ./programs
    ./services
    ./vr-config.nix
  ];
}
