{
  config,
  pkgs,
  inputs,
  ...
}:

{
  imports = [ ./home ];

  home.username = "urio";
  home.homeDirectory = "/home/urio";

  home.stateVersion = "23.11"; # Please read the comment before changing.

  xdg.systemDirs.data = [
    "/var/lib/flatpak/exports/share"
    "${config.home.homeDirectory}/.local/share/flatpak/exports/share"
  ];

  home.file = {
    ".config/zed" = {
      source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nix-flake-config/dotfiles/zed";
    };
  };

  home.sessionVariables = {
    # EDITOR = "emacs";
  };

  # Let Home Manager install and manage itself.
  # programs.home-manager.enable = true;
}
