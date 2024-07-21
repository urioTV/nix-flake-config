{ inputs, config, pkgs, chaotic, ... }: {
  home.packages = with pkgs; [
    # # Adds the 'hello' command to your environment. It prints a friendly
    # # "Hello, world!" when run.
    protonup-qt
    spotify-unwrapped
    moonlight-qt
    # teams-for-linux
    # upscayl
    vcmi
    # skypeforlinux
    # rpcs3
    onlyoffice-bin_latest
    protonvpn-gui
    vscode
    openmw
    ani-cli
    inputs.suyu.packages.${system}.suyu
    distrobox
  ];
}
