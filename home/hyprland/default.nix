{ inputs, config, pkgs, ... }: {
  home.packages = with pkgs; [ playerctl cava ];

  wayland.windowManager.hyprland = {
    enable = true;
    xwayland.enable = true;
    settings = {
      source =
        "${config.home.homeDirectory}/nix-flake-config/dotfiles/hypr/hyprland.conf";
    };
    # plugins = [
    #   inputs.Hyprspace.packages.${pkgs.system}.Hyprspace
    # ];
  };

  home.file = {
    # ".config/hypr" = {
    #   source = config.lib.file.mkOutOfStoreSymlink
    #     "${config.home.homeDirectory}/nix-flake-config/dotfiles/hypr";
    # };
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
