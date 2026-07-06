{ config, pkgs, ... }:
{
  home.packages = with pkgs; [
    llm-agents.pi
    engram
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
