{ config, lib, pkgs, chaotic, inputs, ... }: {

  imports = [
    # Include the results of the hardware scan.
      
  ];

  environment.systemPackages = with pkgs; [
    # Entertainment and Media
    vlc
    (heroic.override {
      extraPkgs = pkgs:
        [
          # List package dependencies here
          gamescope_git
        ];
    })
    prismlauncher
    #gamescope_git
    (lutris.override {
      extraPkgs = pkgs:
        [
          # List package dependencies here
          gamescope_git
        ];
    })
  ];

}
