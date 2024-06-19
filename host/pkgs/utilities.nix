{ config, lib, pkgs, chaotic, inputs, ... }: {

  imports = [
    # Include the results of the hardware scan.
      
  ];

  environment.systemPackages = with pkgs; [
    # System Utilities and Tools
    wget
    pavucontrol
    ddcutil
    mesa-demos
    vulkan-tools
    ntfs3g
    udisks
    gparted
    kdiskmark
    logitech-udev-rules
    libnotify
    libstrangle
    appimage-run
    gpu-viewer
    pciutils
    lm_sensors
    libva-utils
    helvum
    du-dust
    tldr
    gping
    rm-improved
    fzf
    inputs.nix-alien.packages.${system}.nix-alien
    headsetcontrol
    alsaUtils
    smartmontools
    btrfs-progs
    gptfdisk
    psmisc
    handlr-regex
    resources
    glib
  ];

}
