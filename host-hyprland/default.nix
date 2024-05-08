{ inputs, config, pkgs, ... }: {

  programs.hyprland = {
    enable = true;
    package = inputs.hyprland.packages.${pkgs.system}.hyprland;
    xwayland.enable = true;
  };

  systemd = {
  user.services.polkit-gnome-authentication-agent-1 = {
    description = "polkit-gnome-authentication-agent-1";
    wantedBy = [ "default.target" ];
    wants = [ "default.target" ];
    after = [ "default.target" ];
    serviceConfig = {
        Type = "simple";
        ExecStart = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
        Restart = "on-failure";
        RestartSec = 1;
        TimeoutStopSec = 10;
      };
  };
};

  services.udev.packages = [ pkgs.swayosd ];
  
  # programs = {
  #   thunar = {
  #     enable = true;
  #     plugins = [ ];
  #   };
  # };

  environment.systemPackages = with pkgs; [
    # QT Packages
    kdePackages.qt6ct
    libsForQt5.qt5ct

    # dunst
    xorg.xhost
    gnome.nautilus
    # gnome.gnome-tweaks
    #lxqt.lxqt-policykit
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
  ];
}
