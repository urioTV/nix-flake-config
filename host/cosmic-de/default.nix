{
  inputs,
  config,
  pkgs,
  chaotic,
  ...
}:
{
  services.displayManager.cosmic-greeter = {
    enable = true;
  };

  services.desktopManager.cosmic = {
    enable = true;
    xwayland.enable = true;
  };

  services = {
    flatpak.enable = true;
    system76-scheduler.enable = true;
  };

  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk
    ];
  };

  environment.systemPackages = with pkgs; [
  ];

  environment.sessionVariables = {

  };
}
