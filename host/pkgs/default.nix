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
    podman-compose

    # Browsers
    firefox-wayland

    # Communication
    vesktop

    # Entertainment and Media
    vlc
    (heroic.override {
      extraPkgs = pkgs:
        [
          # List package dependencies here
          gamescope
        ];
    })
    prismlauncher
    #gamescope_git
    (lutris.override {
      extraPkgs = pkgs:
        [
          # List package dependencies here
          gamescope
        ];
    })

    # System Utilities and Tools
    wget
    pavucontrol
    ddcutil
    mesa-demos
    vulkan-tools
    # gnome.gnome-tweaks
    # gnome-extension-manager
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
    handlr-regex
    resources

    # Fun and Miscellaneous
    lolcat
    cmatrix
    fastfetch
    tenacity
    wine
    localsend
    nh
    nmap
    ffmpeg

    # Storage and File Systems
    # syncthingtray
  ];

}
