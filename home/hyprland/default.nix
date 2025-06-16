{
  inputs,
  config,
  pkgs,
  ...
}:
{
  imports = [ inputs.hyprpanel.homeManagerModules.hyprpanel ];

  home.packages = with pkgs; [
    # playerctl
    # cava
  ];

  wayland.windowManager.hyprland = {
    enable = true;
    xwayland.enable = true;
    systemd.enable = false;
    settings = {
      source = "${config.home.homeDirectory}/nix-flake-config/dotfiles/hypr/hyprland.conf";
    };
    # plugins = [
    #   inputs.Hyprspace.packages.${pkgs.system}.Hyprspace
    # ];
  };

  home.file = {
    # ".config/hypr" = {
    #   source = config.lib.file.mkOutOfStoreSymlink "/home/urio/nix-flake-config/dotfiles/hypr";
    # };
  };

  

  services = {
    # udiskie = {
    #   enable = true;

    # };
    # playerctld = {
    #   enable = true;
    # };
    # hyprpolkitagent = {
    #   enable = true;
    # };
  };

  systemd.user.services.polkit-kde-agent = {
    Unit = {
      Description = "KDE Polkit Agent";
      Wants = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${pkgs.kdePackages.polkit-kde-agent-1}/libexec/polkit-kde-authentication-agent-1";
    };
    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };

  programs = {
    rofi = {
      enable = true;
      package = pkgs.rofi-wayland;
    };
  };
}
