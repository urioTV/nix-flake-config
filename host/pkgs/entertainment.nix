{ config, lib, pkgs, chaotic, inputs, ... }: {

  imports = [
    # Include the results of the hardware scan.
      
  ];

  environment.systemPackages = with pkgs; [
    # Entertainment and Media
    vlc
    heroic
    prismlauncher
    #gamescope_git
    lutris
    # inputs.nix-citizen.packages.${system}.star-citizen
    star-citizen
  ];

}
