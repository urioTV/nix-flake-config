{
  config,
  lib,
  pkgs,
  chaotic,
  inputs,
  ...
}:
{

  imports = [

  ];

  environment.systemPackages = with pkgs; [
    #  vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    # Programming and Development
    git
    micro
    btop
    nixfmt-rfc-style
    dotnet-sdk
    jetbrains-toolbox
    desktop-file-utils
    ventoy-full
    mono
    alacritty
    kubectl
    kubernetes-helm

    # LLM
    open-webui
  ];

}
