{ inputs, config, pkgs, ... }: {

  home.packages = with pkgs; [ playerctl kitty ];

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
