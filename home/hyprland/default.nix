{ inputs, config, pkgs, ... }: {
  home.packages = with pkgs; [ playerctl cava ];

  home.file = {
    ".config/hypr" = {
      source = config.lib.file.mkOutOfStoreSymlink
        "${config.home.homeDirectory}/nix-flake-config/dotfiles/hypr";
    };
    ".config/waybar" = {
      source = config.lib.file.mkOutOfStoreSymlink
        "${config.home.homeDirectory}/nix-flake-config/dotfiles/waybar";
    };
    ".config/wofi" = {
      source = config.lib.file.mkOutOfStoreSymlink
        "${config.home.homeDirectory}/nix-flake-config/dotfiles/wofi";
    };
    ".config/kitty" = {
      source = config.lib.file.mkOutOfStoreSymlink
        "${config.home.homeDirectory}/nix-flake-config/dotfiles/kitty";
    };
  };

  services = {
    udiskie = {
      enable = true;

    };
    playerctld = { enable = true; };
  };

  programs = {
    wofi = {
      enable = true;

    };
  };

}
