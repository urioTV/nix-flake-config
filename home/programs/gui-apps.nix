{
  inputs,
  config,
  pkgs,
  lib,
  ...
}:
{
  programs = {
    ghostty = {
      enable = true;
      enableZshIntegration = true;
      settings = {
        font-size = 12;
        image-storage-limit = 320000000;
      };
    };
  };
}
