{
  config,
  pkgs,
  lib,
  ...
}:
let
  pi-update = pkgs.writeShellApplication {
    name = "pi-update";
    runtimeInputs = [ pkgs.coreutils ];
    text = builtins.readFile ./pi-update.sh;
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
