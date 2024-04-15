{ inputs, config, pkgs, ... }: {

  home.packages = with pkgs;
    [

    ];

  services.udiskie = {
    enable = true;

  };

}
