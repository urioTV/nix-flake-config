{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
{

  programs = {
    zsh = {
      enable = true;
    };
    # corectrl = {
    #   enable = true;
    #   gpuOverclock.enable = true;
    #   # gpuOverclock.ppfeaturemask = "0xffffffff";
    # };
    java = {
      enable = true;
      # package = pkgs.corretto21;
    };
    appimage = {
      enable = true;
      binfmt = true;
    };

    direnv = {
      enable = true;
      package = pkgs.direnv;
      silent = false;
      loadInNixShell = true;
      direnvrcExtra = "";
      nix-direnv = {
        enable = true;
        package = pkgs.nix-direnv;
      };
    };
  };

}
