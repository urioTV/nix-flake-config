{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
{
  imports = [
    ./nix-ld.nix
    ./gaming.nix
  ];
  programs = {
    zsh = {
      enable = true;
    };
    corectrl = {
      enable = true;
      gpuOverclock.enable = true;
      # gpuOverclock.ppfeaturemask = "0xffffffff";
    };
    java = {
      enable = true;
      package = pkgs.corretto21;
    };
    appimage = {
      enable = true;
      binfmt = true;
    };
  };

}
