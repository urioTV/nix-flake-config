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

  # services.journald = {
  #   storage = "persistent";
  #   extraConfig = ''
  #     SystemMaxUse=2G
  #     MaxRetentionSec=7day
  #     ForwardToConsole=yes
  #     MaxLevelConsole=debug
  #     # Zapisuj wszystkie poziomy logowania
  #     MaxLevelStore=debug
  #     MaxLevelSyslog=debug
  #   '';
  # };

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
    xkb.layout = "pl";
    xkb.variant = "";
  };

  # Configure console keymap
  console.keyMap = "pl2";

  # Enable sound with pipewire.
  # sound.enable = true;
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    extraConfig = {
      pipewire = {
        "10-custom-config" = {
          "context.properties" = {
            "default.clock.rate" = 48000;
            "default.clock.allowed-rates" = [
              44100
              48000
              96000
            ];
            "default.clock.quantum" = 1024;
            "default.clock.min-quantum" = 256;
            "default.clock.max-quantum" = 2048;
          };
        };
      };
      "pipewire-pulse" = {
        "99-custom-quantum" = {
          "pulse.properties" = {
            "pulse.min.req" = "256/48000";
            "pulse.min.frag" = "256/48000";
            "pulse.min.quantum" = "256/48000";
            "pulse.max.quantum" = "2048/48000";
            "pulse.default.quantum" = "1024/48000";
          };
        };
        "10-warframe-rules" = {
          "pulse.rules" = [
            {
              matches = [
                { "application.process.binary" = "Warframe.x64.exe"; }
                { "application.process.binary" = "Warframe.exe"; }
                { "application.name" = "~.*[Ww]arframe.*"; }
              ];
              actions = {
                update-props = {
                  "pulse.min.req" = "1024/48000";
                  "pulse.min.frag" = "1024/48000";
                  "pulse.min.quantum" = "1024/48000";
                };
              };
            }
          ];
        };
      };
    };
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
    shell = pkgs.zsh;
    # shell = pkgs.nushell;
  };

  users.users.root.openssh.authorizedKeys.keys = [
    # This is my public key
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDRfYCXQz7XXM9pupEpNw949Yh2fuMvfJouJZi6+HOIH urio@konrad-m18"
  ];

  environment.sessionVariables = {
    ELECTRON_OZONE_PLATFORM_HINT = "wayland";
    # container_additional_volumes = "/nix/store:/nix/store:ro /etc/profiles/per-user:/etc/profiles/per-user:ro";
  };

  security.polkit = {
    enable = true;
    # extraConfig = ''
    #   polkit.addRule(function(action, subject) {
    #       if ((action.id == "org.corectrl.helper.init" ||
    #            action.id == "org.corectrl.helperkiller.init") &&
    #           subject.local == true &&
    #           subject.active == true &&
    #           subject.isInGroup("wheel")) {
    #               return polkit.Result.YES;
    #       }
    #   });
    # '';
  };

  system.stateVersion = "23.11"; # Did you read the comment?

}
