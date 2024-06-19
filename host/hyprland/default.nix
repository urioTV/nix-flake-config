{ inputs, config, pkgs, ... }: {

  imports = [ ./greetd.nix ];

  programs.hyprland = {
    enable = true;
    package = inputs.hyprland.packages.${pkgs.system}.hyprland;
    xwayland.enable = true;
  };

  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [ xdg-desktop-portal-gtk ];
  };

  services = {
    flatpak.enable = true;
    udisks2.enable = true;
    gvfs.enable = true;
  };

  programs.dconf.enable = true;

  systemd = {
    user.services.polkit-gnome-authentication-agent-1 = {
      description = "polkit-gnome-authentication-agent-1";
      wantedBy = [ "graphical-session.target" ];
      wants = [ "graphical-session.target" ];
      after = [ "graphical-session.target" ];
      serviceConfig = {
        Type = "simple";
        ExecStart =
          "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
        Restart = "on-failure";
        RestartSec = 1;
        TimeoutStopSec = 10;
      };
    };
  };

  services.udev.packages = [ pkgs.swayosd ];

  programs = {
    file-roller = {
      enable = true;
    };
  };

  environment.systemPackages = with pkgs; [
    # # QT Packages
    # kdePackages.qt6ct
    # libsForQt5.qt5ct

    # dunst
    xorg.xhost
    gnome.nautilus
    loupe
    polkit_gnome
    swww
    wofi
    wl-clipboard
    cliphist
    kitty
    swaynotificationcenter
    waybar
    blueman
    bluetuith
    slurp
    grim
    hyprshot
    brightnessctl
    pamixer
    pw-volume
    swayosd
    transmission-gtk
  ];

  environment.sessionVariables = {
    HYPRSHOT_DIR = "/home/urio/Obrazy/Screenshots";
  };
}
