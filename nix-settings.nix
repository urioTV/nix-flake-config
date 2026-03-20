{ inputs, self, ... }:
let
  sharedConfig =
    { inputs, inputs' }:
    {
      nixpkgs.overlays = [
        (import ./overlay.nix { inherit inputs'; })
        (inputs.urio-nur.overlays.default)
      ];
      nixpkgs.config.allowUnfree = true;
    };
in
{
  flake.nixosModules.nix-settings =
    {
      pkgs,
      lib,
      inputs,
      inputs',
      ...
    }:
    {
      imports = [ (sharedConfig { inherit inputs inputs'; }) ];

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

  flake.homeModules.nix-settings =
    {
      pkgs,
      lib,
      inputs,
      inputs',
      ...
    }:
    {
      imports = [ (sharedConfig { inherit inputs inputs'; }) ];
    };
}
