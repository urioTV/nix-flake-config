#!/usr/bin/env bash
# Update the pinned Engram release in modules/ai/_engram.nix.
#
# Engram ships as a GitHub release tarball fetched via `pkgs.fetchurl`, so
# nix-update bumps `version` and rewrites the `sha256-` hash in one pass.
# The derivation is exposed as `pkgs.engram` through the overlay in
# modules/nix/_overlay.nix, hence we point nix-update at that attribute.
#
# Usage:
#   ./modules/ai/update-engram.sh           # bump to latest GitHub release
#   ./modules/ai/update-engram.sh 1.17.0    # pin a specific version
set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)

cd "$REPO_ROOT"

VERSION_ARG=()
if [[ $# -ge 1 ]]; then
  VERSION_ARG=(--version="$1")
fi

nix run github:Mic92/nix-update -- \
  --flake \
  "${VERSION_ARG[@]}" \
  --override-filename modules/ai/_engram.nix \
  nixosConfigurations.konrad-desktop.pkgs.engram
