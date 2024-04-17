{ inputs, config, pkgs, ... }: {

  home.packages = with pkgs; [ playerctl ];

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
