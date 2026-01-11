{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
{
  programs.brave = {
    enable = true;
    commandLineArgs = [
      "--ozone-platform-hint=wayland"
      "--enable-features=UseOzonePlatform"
      "--gtk-version=4"
    ];
  };

  home.sessionVariables = {
    GTK_USE_PORTAL = "1";
  };
}
