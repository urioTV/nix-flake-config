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
    noto-fonts-extra
    noto-fonts-cjk-sans
    noto-fonts-cjk-serif
    noto-fonts-emoji
    jetbrains-mono
    font-awesome
    ubuntu_font_family
    baekmuk-ttf
    nerd-font-patcher
    corefonts
    open-sans
    nerd-fonts.hack
    nerd-fonts.noto
    nerd-fonts.ubuntu
    nerd-fonts.ubuntu-mono
    nerd-fonts.open-dyslexic
    nerd-fonts.agave
  ];

  fonts.fontDir.enable = true;

}
