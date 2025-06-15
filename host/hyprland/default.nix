{
  inputs,
  config,
  pkgs,
  chaotic,
  ...
}:
{
  programs = {
    hyprland = {
      enable = true;
      xwayland.enable = true;
      withUWSM = true;
    };
    uwsm = {
      enable = true;
    };
    thunar = {
      enable = true;
    };
  };
  services = {
    flatpak.enable = true;
    greetd = {
      enable = true;
      settings = {
        default_session = {
          command = "${pkgs.greetd.tuigreet}/bin/tuigreet";
          user = "greeter";
        };
      };
    };
  };

  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk
    ];
  };

  environment.systemPackages = with pkgs; [
    qbittorrent
    kitty
    cava
    playerctl
  ];
}
