{ pkgs }:

pkgs.writeShellScriptBin "gamesteam" ''
  #!/bin/sh

  export SDL_VIDEODRIVER = "x11"

  exec ${pkgs.gamescope_git}/bin/gamescope -h 1200 -w 1920 -H 1200 -W 1920 -ef -- "$@"''