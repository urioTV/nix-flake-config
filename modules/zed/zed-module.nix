{ ... }:
{
  flake.homeModules.zed =
    { config, pkgs, ... }:
    {
      home.packages = with pkgs; [
        zed-editor
      ];

      home.file = {
        ".config/zed" = {
          source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nix-flake-config/dotfiles/zed";
        };
      };
    };
}
