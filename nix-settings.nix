{
  pkgs,
  config,
  lib,
  inputs,
  ...
}:

{
  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];

    substituters = [
      "https://nix-gaming.cachix.org"
      "https://nix-community.cachix.org"
    ];
    trusted-public-keys = [
      "nix-gaming.cachix.org-1:nbjlureqMbRAxR1gJ/f3hxemL9svXaZF/Ees8vCUUs4="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];

    auto-optimise-store = true;

    trusted-users = [
      "root"
      "urio"
    ];
  };
  nix.nixPath = [ "nixpkgs=${inputs.nixpkgs}" ];

  nix.gc = {
    automatic = true;
    dates = "daily";
    options = "--delete-older-than 2d";
  };

  programs.nh = {
    enable = true;
    # clean.enable = true;
    # clean.extraArgs = "--keep-since 2d --keep 2";
    flake = "/home/urio/nix-flake-config";
  };
}
