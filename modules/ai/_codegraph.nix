# CodeGraph (colbymchenry/codegraph) — semantic code-intelligence graph for AI
# coding agents. Pre-built self-contained bundle from GitHub Releases: a vendored
# Node runtime (`node`), a Rust native kernel (`lib/kernel/codegraph-kernel.node`),
# and the JS app under `lib/`. `bin/codegraph` is a sh launcher that resolves its
# own symlink to the bundle dir and execs `node … lib/dist/bin/codegraph.js`.
#
# We fetch the tarball, patchelf the two ELF artifacts against nixpkgs glibc /
# libgcc / libstdc++, keep the bundle layout under $out/opt/codegraph, and
# symlink the launcher into $out/bin. The launcher's self-relative resolution
# means the symlink works from anywhere on PATH.
#
# 100% local: SQLite index in `.codegraph/` per project, no API keys. Agent
# integration is an MCP server (`codegraph serve --mcp`); wire it up in
# modules/ai/_ai.nix. CodeGraph does not ship a `pi` platform target in its
# `codegraph install` wizard, so we register the MCP server manually.
{ pkgs, lib }:

pkgs.stdenv.mkDerivation rec {
  pname = "codegraph";
  version = "1.5.0";

  src = pkgs.fetchurl {
    url = "https://github.com/colbymchenry/codegraph/releases/download/v${version}/codegraph-linux-x64.tar.gz";
    hash = "sha256-K6Zeh6EhC3BrseZ9Xki1/EoZNeQ9uz+18xxVl4QNLlg=";
  };

  nativeBuildInputs = [ pkgs.autoPatchelfHook ];

  # The vendored node + Rust kernel are dynamically linked against glibc,
  # libgcc_s and libstdc++.
  buildInputs = [
    pkgs.stdenv.cc.libc
    pkgs.gcc-unwrapped
  ];

  # Don't try to build; just relocate the prebuilt bundle.
  dontConfigure = true;
  dontBuild = true;

  # autoPatchelfHook scans standard dirs; the bundle is under $out/opt, so list
  # the ELF files explicitly. (node_modules is pure JS + wasm; nothing else to patch.)
  autoPatchelfFiles = [
    "$out/opt/codegraph/node"
    "$out/opt/codegraph/lib/kernel/codegraph-kernel.node"
  ];

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/opt/codegraph" "$out/bin"

    # The tarball unpacks to a single top-level `codegraph-linux-x64/` dir;
    # stdenv sets that as sourceRoot, so we're already inside it during install.
    cp -r ./* "$out/opt/codegraph/"

    chmod +x "$out/opt/codegraph/node" "$out/opt/codegraph/bin/codegraph"

    # Launcher resolves its own symlink, so a plain symlink works on PATH.
    ln -s "$out/opt/codegraph/bin/codegraph" "$out/bin/codegraph"

    runHook postInstall
  '';

  meta = {
    description = "Semantic code-intelligence graph for AI coding agents — surgical context, fewer tool calls, 100% local (codegraph CLI + MCP server)";
    homepage = "https://github.com/colbymchenry/codegraph";
    license = lib.licenses.mit;
    mainProgram = "codegraph";
    platforms = [ "x86_64-linux" ];
  };
}
