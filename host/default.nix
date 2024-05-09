{ inputs, config, pkgs, chaotic, ... }: {
  imports = [
    ./btrfsOptions.nix
    ./stylix.nix
    ./hardware-stuff
    ./programs
    ./boot-kernel-stuff
    ./pkgs
    ./hyprland
  ];
}