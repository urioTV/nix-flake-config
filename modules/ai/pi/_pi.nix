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
    codegraph
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
    # Respect the user's local-first stance: no anonymous usage telemetry.
    CODEGRAPH_TELEMETRY = "0";
    # Absolute path to the codegraph CLI for the prompt-hook extension
    # (dotfiles/pi/extensions/codegraph.ts). Falls back to PATH lookup.
    CODEGRAPH_BIN = "${pkgs.codegraph}/bin/codegraph";
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
