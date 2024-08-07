{ config, lib, pkgs, chaotic, inputs, ... }: {

  imports = [
    # Include the results of the hardware scan.
    ./development.nix
    ./entertainment.nix
    ./utilities.nix
  ];

  environment.systemPackages = with pkgs; [
    # Browsers
    firefox_nightly
    brave

    # Communication
    (vesktop.overrideAttrs (oldAttrs: {
      postFixup = oldAttrs.postFixup or "" + ''
        wrapProgram $out/bin/vesktop \
          --add-flags --ozone-platform=x11
      '';
    }))

    # Fun and Miscellaneous
    lolcat
    cmatrix
    fastfetch
    tenacity
    wine
    localsend
    nh
    nmap
    ffmpeg

    # Remote Desktop
    # krdc

    # Storage and File Systems
    # syncthingtray
  ];

}
