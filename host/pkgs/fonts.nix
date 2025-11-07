{
  config,
  lib,
  pkgs,
  chaotic,
  inputs,
  ...
}:
{

  fonts.packages = with pkgs; [
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-cjk-serif
    noto-fonts-color-emoji
    font-awesome
    ubuntu-classic
    baekmuk-ttf
    nerd-font-patcher
    corefonts
    open-sans
    nerd-fonts.hack
    nerd-fonts.noto
    nerd-fonts.open-dyslexic
    inputs.apple-fonts.packages.${pkgs.system}.sf-pro-nerd
    inputs.apple-fonts.packages.${pkgs.system}.sf-compact-nerd
    inputs.apple-fonts.packages.${pkgs.system}.sf-mono-nerd
    inputs.apple-fonts.packages.${pkgs.system}.sf-arabic-nerd
    inputs.apple-fonts.packages.${pkgs.system}.sf-armenian-nerd
    inputs.apple-fonts.packages.${pkgs.system}.sf-georgian-nerd
    inputs.apple-fonts.packages.${pkgs.system}.sf-hebrew-nerd
    inputs.apple-fonts.packages.${pkgs.system}.ny-nerd
  ];

  fonts.fontDir.enable = true;

}
