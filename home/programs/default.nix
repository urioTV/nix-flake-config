{
  inputs,
  config,
  pkgs,
  chaotic,
  lib,
  ...
}:
{

  programs = {
    git = {
      enable = true;
      settings = {
        user = {
          email = "uriootv@protonmail.com";
          name = "urioTV";
        };
      };
    };
    bat = {
      enable = true;
    };
    obs-studio = {
      enable = true;
      plugins = with pkgs; [
        # obs-studio-plugins.obs-vaapi
        # obs-studio-plugins.obs-vkcapture
      ];
    };
    rclone = {
      enable = true;
    };
  };
  home.packages = with pkgs; [
    rclone-browser
  ];
}
