{ inputs, config, pkgs, ... }: {

  programs.hyprland = {
    enable = true;
    package = inputs.hyprland.packages.${pkgs.system}.hyprland;
    xwayland.enable = true;
  };

  programs = {
    thunar = {
      enable = true;
      plugins = [ ];
    };
  };

  environment.systemPackages = with pkgs; [
    # dunst
    lxqt.lxqt-policykit
    swww
    waypaper
    rofi-wayland
    wl-clipboard
    cliphist
    kitty
    blueberry
    networkmanagerapplet
    swaynotificationcenter
    waybar
  ];
}
