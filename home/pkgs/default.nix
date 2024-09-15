{ inputs, config, pkgs, chaotic, ... }: {
  home.packages = with pkgs; [
    # # Adds the 'hello' command to your environment. It prints a friendly
    # # "Hello, world!" when run.
    protonup-qt
    # spotify-unwrapped
    tidal-hifi
    moonlight-qt
    # teams-for-linux
    # upscayl
    vcmi
    # skypeforlinux
    # rpcs3
    protonvpn-gui
    #vscode
    (vscode.overrideAttrs (oldAttrs: {
      postFixup = oldAttrs.postFixup or "" + ''
        wrapProgram $out/bin/code \
           --add-flags --ozone-platform=x11
      '';
    }))
    openmw
    ani-cli
    distrobox

  ];
}
