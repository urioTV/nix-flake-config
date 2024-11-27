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
    ./hardware-configuration.nix
    ./host
  ];

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

  # Configure keymap in X11
  services.xserver = {
    layout = "pl";
    xkbVariant = "";
  };

  # Configure console keymap
  console.keyMap = "pl2";

  # Enable sound with pipewire.
  # sound.enable = true;
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

  users.users.urio = {
    isNormalUser = true;
    description = "Konrad Lemański";
    extraGroups = [
      "networkmanager"
      "wheel"
      "audio"
      "video"
      "gamemode"
      "docker"
    ];
    packages = with pkgs; [
      #  firefox
      #  thunderbird
    ];
  };

  users.users.root.openssh.authorizedKeys.keys = [
    # This is my public key
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDRfYCXQz7XXM9pupEpNw949Yh2fuMvfJouJZi6+HOIH urio@konrad-m18"
  ];

  users.users.urio.shell = pkgs.zsh;

  environment.sessionVariables = {
    ELECTRON_OZONE_PLATFORM_HINT = "wayland";
    container_additional_volumes = "/nix/store:/nix/store:ro /etc/profiles/per-user:/etc/profiles/per-user:ro";
  };

  # Open ports in the firewall.
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [
      53317
      8000
    ];
    allowedUDPPorts = [
      53317
      21116
    ];
    allowedTCPPortRanges = [
      {
        from = 21115;
        to = 21119;
      }
    ];
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
    noto-fonts-cjk-sans
    noto-fonts-cjk-serif
    noto-fonts-emoji
    nerdfonts
    jetbrains-mono
    font-awesome
    ubuntu_font_family
    baekmuk-ttf
    nerd-font-patcher
    corefonts
    open-sans
  ];

  fonts.fontDir.enable = true;

  system.stateVersion = "23.11"; # Did you read the comment?

}
