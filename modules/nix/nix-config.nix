{ inputs, ... }:
let
  sharedConfig =
    { inputs' }:
    {
      nixpkgs.overlays = [
        (import ./_overlay.nix { inherit inputs'; })
        (inputs.urio-nur.overlays.default)
        (inputs.nix-cachyos-kernel.overlays.default)
      ];
      nixpkgs.config.allowUnfree = true;
    };
in
{
  flake.nixosModules.nix-config =
    {
      pkgs,
      lib,
      inputs,
      inputs',
      ...
    }:
    {
      imports = [ (sharedConfig { inherit inputs'; }) ];

      nix.settings = {
        experimental-features = [
          "nix-command"
          "flakes"
        ];
        substituters = [
          "https://nix-gaming.cachix.org"
          "https://nix-community.cachix.org"
          "https://attic.xuyh0120.win/lantian"
          "https://cache.garnix.io"
        ];
        trusted-public-keys = [
          "nix-gaming.cachix.org-1:nbjlureqMbRAxR1gJ/f3hxemL9svXaZF/Ees8vCUUs4="
          "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
          "lantian:EeAUQ+W+6r7EtwnmYjeVwx5kOGEBpjlBfPlzGlTNvHc="
          "cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g="
        ];
        auto-optimise-store = true;
        trusted-users = [
          "root"
          "urio"
        ];
        eval-cores = 0;
      };

      nix.nixPath = [ "nixpkgs=${inputs.nixpkgs}" ];

      nix.gc = {
        automatic = true;
        dates = "daily";
        options = "--delete-older-than 2d";
      };

      programs.nh = {
        enable = true;
        flake = "/home/urio/nix-flake-config";
      };
    };

  flake.homeModules.nix-config =
    {
      pkgs,
      lib,
      inputs,
      inputs',
      ...
    }:
    {
      imports = [ (sharedConfig { inherit inputs'; }) ];
    };
}
