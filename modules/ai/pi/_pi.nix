{
  config,
  pkgs,
  lib,
  ...
}:
let
  engram = pkgs.stdenv.mkDerivation rec {
    pname = "engram";
    version = "1.16.3";

    src = pkgs.fetchurl {
      url = "https://github.com/Gentleman-Programming/engram/releases/download/v${version}/engram_${version}_linux_amd64.tar.gz";
      hash = "sha256-AWt+dfeI7vqyAmbL/kcthsiwjnKPr6ojecnKqzQpWuk=";
    };

    nativeBuildInputs = [ pkgs.autoPatchelfHook ];

    # CGO binary dynamically linked against glibc (SQLite via mattn/go-sqlite3)
    buildInputs = [ pkgs.stdenv.cc.libc ];

    unpackPhase = ''
      tar xzf $src
    '';

    installPhase = ''
      mkdir -p $out/bin
      cp engram $out/bin/
    '';

    meta = {
      description = "Persistent memory for AI coding agents — local SQLite + MCP";
      homepage = "https://github.com/Gentleman-Programming/engram";
      license = lib.licenses.mit;
      mainProgram = "engram";
      platforms = [ "x86_64-linux" ];
    };
  };
in
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
    ENGRAM_BIN = "${engram}/bin/engram";
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
