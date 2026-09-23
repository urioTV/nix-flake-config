# Shared Engram derivation used by AI home modules.
#
# Extracted from modules/ai/pi/_pi.nix so other agents can install the
# same pinned binary without duplicating the derivation. The package is
# exposed as pkgs.engram through the overlay in modules/nix/_overlay.nix.
{ pkgs, lib }:

pkgs.stdenv.mkDerivation rec {
  pname = "engram";
  # 2.0.0 is required by gentle-engram >= 0.1.13: the Pi plugin resolves the
  # local server identity with `engram instance-id`, which does not exist
  # before 2.0.0. Without it the plugin reports "Engram could not resolve its
  # local server identity" and every mem_* tool stays offline.
  version = "2.0.0";

  src = pkgs.fetchurl {
    url = "https://github.com/Gentleman-Programming/engram/releases/download/v${version}/engram_${version}_linux_amd64.tar.gz";
    hash = "sha256-I74cLOlznEVQl/+GRzYhNxe5JbPoghqYjfxhloWlq9U=";
  };

  nativeBuildInputs = [ pkgs.autoPatchelfHook ];

  # 2.0.0 ships a statically linked binary (no glibc dependency), so
  # autoPatchelfHook is a no-op there; buildInputs is kept for older pins.
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
