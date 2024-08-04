{ config, lib, pkgs, chaotic, inputs, ... }: {

  imports = [
    # Include the results of the hardware scan.
      
  ];

  environment.systemPackages = with pkgs; [
    # Entertainment and Media
    vlc
    heroic
    prismlauncher
    lutris
    bottles
    # inputs.nix-citizen.packages.${system}.star-citizen
    # star-citizen
    (inputs.nix-citizen.packages.${system}.star-citizen.override (prev: {
          # Recommended to keep the previous overrides
          preCommands = "export radv_zero_vram=true";
          useUmu = true;
        }))
  ];

}
