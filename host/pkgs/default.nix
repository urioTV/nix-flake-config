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
    # Include the results of the hardware scan.
    ./development.nix
    ./entertainment.nix
    ./utilities.nix
    ./fonts.nix
  ];

  environment.systemPackages = with pkgs; [

    # Communication
    (vesktop.overrideAttrs (oldAttrs: {
      postFixup =
        oldAttrs.postFixup or ""
        + ''
          wrapProgram $out/bin/vesktop \
            --add-flags --ozone-platform=x11
        '';
    }))
    (teams-for-linux.overrideAttrs (oldAttrs: {
      postFixup =
        oldAttrs.postFixup or ""
        + ''
          wrapProgram $out/bin/teams-for-linux \
            --add-flags --ozone-platform=x11
        '';
    }))

    # Fun and Miscellaneous
    lolcat
    cmatrix
    fastfetch
    wine
    localsend
    nmap
    ffmpeg-full
    # handbrake
    obsidian
    # spacedrive

    # Nice
    bleachbit
    libreoffice-qt
    hunspell
    hunspellDicts.en_US
    hunspellDicts.pl_PL
    hyphen
    hyphenDicts.en_US

    # Remote Desktop
    # krdc

    # Storage and File Systems
    # syncthingtray
  ];

}
