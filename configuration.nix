{ inputs, config, pkgs, chaotic, ... }: {
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
    ./stylix.nix
  ];

  # boot.kernelPackages = pkgs.linuxPackages_zen;
  boot.kernelPackages = pkgs.linuxPackages_cachyos;
  # boot.kernelPackages = pkgs.linuxPackages_xanmod_latest;
  hardware.opengl = {
    enable = true;
    driSupport = true;
    driSupport32Bit = true;
    extraPackages = with pkgs; [ rocmPackages.clr.icd ];
  };

  # Flakes
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  boot.supportedFilesystems = [ "ntfs" "exfat" ];

  # Bootloader
  # boot.loader.systemd-boot.enable = true;

  boot.loader = {
    efi = {
      canTouchEfiVariables = true;
      # efiSysMountPoint = "/boot/efi"; # ← use the same mount point here.
    };
    #grub = {
    #  enable = true;
    #  efiSupport = true;
    #  #efiInstallAsRemovable = true; # in case canTouchEfiVariables doesn't work for your system
    #  device = "nodev";
    #};
    systemd-boot.enable = true;
  };

  networking.hostName = "konrad-m18"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "Europe/Warsaw";

  # Select internationalisation properties.
  i18n.defaultLocale = "pl_PL.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "pl_PL.UTF-8";
    LC_IDENTIFICATION = "pl_PL.UTF-8";
    LC_MEASUREMENT = "pl_PL.UTF-8";
    LC_MONETARY = "pl_PL.UTF-8";
    LC_NAME = "pl_PL.UTF-8";
    LC_NUMERIC = "pl_PL.UTF-8";
    LC_PAPER = "pl_PL.UTF-8";
    LC_TELEPHONE = "pl_PL.UTF-8";
    LC_TIME = "pl_PL.UTF-8";
  };

  # Enable the X11 windowing system.
  services.xserver.enable = true;
  services.xserver.videoDrivers = [ "amdgpu" ];
  boot.initrd.kernelModules = [ "amdgpu" ];

  chaotic.mesa-git.enable = true;

  services.logind.lidSwitch = "lock";

  # Configure keymap in X11
  services.xserver = {
    layout = "pl";
    xkbVariant = "";
  };

  # Configure console keymap
  console.keyMap = "pl2";

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound with pipewire.
  sound.enable = true;
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };
  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [ xdg-desktop-portal-gnome ];
  };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.urio = {
    isNormalUser = true;
    description = "Konrad Lemański";
    extraGroups = [ "networkmanager" "wheel" "audio" "video" ];
    packages = with pkgs;
      [
        #  firefox
        #  thunderbird
      ];
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # nixpkgs.overlays = [
  #   (final: prev: {
  #     pkg = optimizeForThisHost prev.pkg;
  #   })
  # ];

  environment.systemPackages = with pkgs; [
    #  vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    # Programming and Development
    git
    micro
    btop
    nixfmt
    nixpkgs-fmt
    jdk11
    jdk17
    dotnet-sdk_8
    bun
    nodejs_21
    ollama
    jetbrains-toolbox
    desktop-file-utils
    ventoy-bin-full

    # Browsers
    firefox-wayland

    # Communication
    discord

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

    # Fun and Miscellaneous
    lolcat
    cmatrix
    neofetch
    tenacity
    wine
    localsend
    nh

    # Storage and File Systems
    # syncthingtray
  ];
  users.users.urio.shell = pkgs.zsh;

  # Enable the GNOME Desktop Environment.
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.desktopManager.gnome.enable = true;

  # GameScope fix
  nixpkgs.config.packageOverrides = pkgs: {
    steam = pkgs.steam.override {
      extraPkgs = pkgs:
        with pkgs; [
          xorg.libXcursor
          xorg.libXi
          xorg.libXinerama
          xorg.libXScrnSaver
          libpng
          libpulseaudio
          libvorbis
          stdenv.cc.cc.lib
          libkrb5
          keyutils
        ];
    };
  };

  programs = {
    steam = {
      enable = true;
      remotePlay.openFirewall =
        true; # Open ports in the firewall for Steam Remote Play
      dedicatedServer.openFirewall =
        true; # Open ports in the firewall for Source Dedicated Server
    };
    zsh.enable = true;
    corectrl = {
      enable = true;
      gpuOverclock.enable = true;
      # gpuOverclock.ppfeaturemask = "0xffffffff";
    };
    noisetorch.enable = true;
    gamescope = {
      enable = true;
      # capSysNice = true;
      package = pkgs.gamescope_git;
      env = { SDL_VIDEODRIVER = "x11"; };
      args = [ "-h 1200" "-w 1920" "-H 1200" "-W 1920" ];
    };
  };
  services = { flatpak.enable = true; };
  virtualisation.podman = {
    enable = true;
    dockerCompat = true;
  };
  environment.sessionVariables = { FLAKE = "/home/urio/nix-flake-config"; };

  hardware.bluetooth.enable = true; # enables support for Bluetooth
  hardware.bluetooth.powerOnBoot =
    true; # powers up the default Bluetooth controller on boot
  # services.blueman.enable = true;

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 53317 8000 ];
    allowedUDPPorts = [ 53317 21116 ];
    allowedTCPPortRanges = [{
      from = 21115;
      to = 21119;
    }];
  };

  security.polkit = {
    enable = true;
    extraConfig = ''
      polkit.addRule(function(action, subject) {
          if ((action.id == "org.corectrl.helper.init" ||
               action.id == "org.corectrl.helperkiller.init") &&
              subject.local == true &&
              subject.active == true &&
              subject.isInGroup("wheel")) {
                  return polkit.Result.YES;
          }
      });
    '';
  };
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  fonts.packages = with pkgs; [
    noto-fonts
    noto-fonts-extra
    noto-fonts-cjk
    noto-fonts-cjk-sans
    noto-fonts-cjk-serif
    noto-fonts-emoji
    liberation_ttf
    fira-code
    fira-code-symbols
    mplus-outline-fonts.githubRelease
    dina-font
    proggyfonts
    nerdfonts
    jetbrains-mono
    font-awesome
    cascadia-code
    ubuntu_font_family
    babelstone-han
    baekmuk-ttf
  ];

  system.stateVersion = "23.11"; # Did you read the comment?

}
