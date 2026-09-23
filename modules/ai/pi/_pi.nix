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
    # Point at the mutable Home Manager profile, not an absolute store path.
    # Absolute paths (e.g. "${pkgs.engram}/bin/engram") get frozen into the
    # session environment at login; after `nh os switch` every process that
    # inherited the old value keeps spawning the OLD binary until re-login
    # (gentle-engram then fails with "could not resolve its local server
    # identity" after an Engram major bump). The profile directory resolves
    # through the current generation on every spawn, so a `switch` is enough.
    ENGRAM_BIN = "${config.home.profileDirectory}/bin/engram";

    # Never use agent-browser's imperative Chrome download on NixOS. Point it
    # at the Chromium build managed by the system generation instead — via the
    # mutable profile for the same reason as ENGRAM_BIN above.
    AGENT_BROWSER_EXECUTABLE_PATH = "${config.home.profileDirectory}/bin/chromium";
  };

  home.sessionPath = [
    "${config.home.homeDirectory}/.local/share/npm/bin"
  ];

  home.file = {
    # ~/.pi mirrors dotfiles/pi; agent config lives in dotfiles/pi/agent.
    ".pi" = {
      source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nix-flake-config/dotfiles/pi";
    };
  };
}
