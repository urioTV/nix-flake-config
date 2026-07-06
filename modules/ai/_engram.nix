# Shared Engram derivation used by AI home modules.
#
# Extracted from modules/ai/pi/_pi.nix so other agents can install the
# same pinned binary without duplicating the derivation. The package is
# exposed as pkgs.engram through the overlay in modules/nix/_overlay.nix.
{ pkgs, lib }:

pkgs.stdenv.mkDerivation rec {
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
}
