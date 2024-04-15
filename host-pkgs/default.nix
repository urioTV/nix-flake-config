{ config, lib, pkgs, chaotic, inputs, ... }: {

  imports = [
    # Include the results of the hardware scan.

  ];

  environment.systemPackages = with pkgs; [
    #  vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    # Programming and Development
    git
    micro
    btop
    nixfmt
    nixpkgs-fmt
    dotnet-sdk_8
    ollama
    jetbrains-toolbox
    desktop-file-utils
    ventoy-bin-full
    docker-compose

    # Browsers
    firefox-wayland

    # Communication
    discord-krisp

    # Entertainment and Media
    vlc
    heroic
    prismlauncher
    gamemode
    #gamescope_git

    # System Utilities and Tools
    wget
    pavucontrol
    ddcutil
    mesa-demos
    vulkan-tools
    gnome.gnome-tweaks
    gnome-extension-manager
    ntfs3g
    udisks
    gparted
    kdiskmark
    logitech-udev-rules
    transmission-gtk
    libnotify
    libstrangle
    speedtest-go
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

    # Fun and Miscellaneous
    lolcat
    cmatrix
    neofetch
    tenacity
    wine
    localsend
    nh
    nmap
    (lutris.override {
      extraPkgs = pkgs:
        [
          # List package dependencies here
          gamescope_git
        ];
    })
    ffmpeg

    # Storage and File Systems
    # syncthingtray
  ];

}
