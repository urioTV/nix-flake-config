{ inputs, config, pkgs, ... }: {

  programs.hyprland = {
    enable = true;
    package = inputs.hyprland.packages.${pkgs.system}.hyprland;
    xwayland.enable = true;
  };

  services.udev.packages = [ pkgs.swayosd ];
  
  # programs = {
  #   thunar = {
  #     enable = true;
  #     plugins = [ ];
  #   };
  # };

  environment.systemPackages = with pkgs; [
    # dunst
    gnome.nautilus
    gnome.gnome-tweaks
    lxqt.lxqt-policykit
    swww
    wofi
    wl-clipboard
    cliphist
    # kitty
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
