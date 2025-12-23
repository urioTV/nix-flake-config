{
  inputs,
  config,
  pkgs,
  chaotic,
  ...
}:
{
  imports = [
    ./stylix.nix
    ./ai # AI/LLM modules
    ./hardware-stuff
    ./programs
    ./boot-kernel-stuff
    ./pkgs
    ./services
    ./plasma6
    # ./cosmic-de
    ./filesystems
    ./networking
    ./virtualisation
    ./gaming # Gaming modules
  ];
}
