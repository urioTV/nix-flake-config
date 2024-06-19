{ inputs, config, pkgs, chaotic, ... }: {
  imports = [
    ./btrfsOptions.nix
    ./stylix.nix
    ./hardware-stuff
    ./programs
    ./boot-kernel-stuff
    ./pkgs
    ./services
    ./plasma6
  ];


  # Specialization for gnome and hyprland if needed

  # specialization = {
  #   hyprland.configuration = {
  #     imports = [
  #       ./hyprland
  #     ];
  #   };
  #   gnome.configuration = {
  #     imports = [
  #       ./gnome
  #     ];
  #   };
  # };
}
