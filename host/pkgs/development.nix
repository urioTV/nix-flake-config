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
    # Programming and Development
    git
    micro
    btop
    nixfmt-rfc-style
    # nil
    nixd
    dotnet-sdk
    # jetbrains-toolbox
    desktop-file-utils
    # ventoy-full
    mono
    alacritty
    kubectl
    kubernetes-helm
    # zed-editor
    terraform
    terraform-ls
    antigravity
  ];

}
