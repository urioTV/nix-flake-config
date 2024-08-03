{ config, lib, pkgs, chaotic, inputs, ... }: {

  imports = [

  ];

  environment.systemPackages = with pkgs; [
    #  vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    # Programming and Development
    git
    micro
    btop
    nixfmt
    nixpkgs-fmt
    dotnet-sdk_8
    # ollama
    jetbrains-toolbox
    desktop-file-utils
    ventoy-bin-full
    podman-compose
    mono
    
  ];

}
