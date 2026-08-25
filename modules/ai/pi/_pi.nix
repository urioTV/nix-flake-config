{
  config,
  pkgs,
  lib,
  ...
}:
let
  pi-update = pkgs.writeShellApplication {
    name = "pi-update";
    runtimeInputs = [
      pkgs.llm-agents.pi
      pkgs.nodejs
    ];
    text = ''
      pi update --extensions "$@"

      npm_dir="''${PI_CODING_AGENT_DIR:-$HOME/.pi/agent}/npm"
      if [[ -f "$npm_dir/package.json" ]]; then
        npm --prefix "$npm_dir" install --legacy-peer-deps
        npm --prefix "$npm_dir" prune --legacy-peer-deps
      fi

      npm cache clean --force
    '';
  };
in
{
  home.packages = with pkgs; [
    llm-agents.pi
    pi-update
    engram

    # Keep the browser CLI aligned with pi-agent-browser-native's exact
    # upstream target. llm-agents.nix provides the current cached build.
    agent-browser
    chromium
    ffmpeg
  ];

  # npm on NixOS can't write to /nix/store, so global installs fail.
  # Redirect prefix to a writable location.
  programs.npm = {
    enable = true;
    settings = {
      prefix = "${config.home.homeDirectory}/.local/share/npm";
    };
  };

  home.sessionVariables = {
    ENGRAM_BIN = "${pkgs.engram}/bin/engram";

    # Never use agent-browser's imperative Chrome download on NixOS. Point it
    # at the Chromium build managed by the system generation instead.
    AGENT_BROWSER_EXECUTABLE_PATH = lib.getExe pkgs.chromium;
  };

  home.sessionPath = [
    "${config.home.homeDirectory}/.local/share/npm/bin"
    "${config.home.homeDirectory}/nix-flake-config/dotfiles/pi/npm/node_modules/.bin"
  ];

  home.file = {
    ".pi/agent" = {
      source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nix-flake-config/dotfiles/pi";
    };
  };
}
