{ inputs, config, pkgs, chaotic, ... }: {
  imports = [
    # Include the results of the hardware scan.
    ./hyprland
    ./stylixHome.nix
  ];
}