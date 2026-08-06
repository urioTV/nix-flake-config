{ inputs, ... }:
let
  sharedConfig =
    { inputs' }:
    {
      nixpkgs.overlays = [
        (inputs.nur.overlays.default)
        (import ./_overlay.nix { inherit inputs'; })
        (inputs.urio-nur.overlays.default)
        (inputs.llm-agents.overlays.shared-nixpkgs)
        (inputs.nix-cachyos-kernel.overlays.pinned)
      ];
      nixpkgs.config.allowUnfree = true;
    };
in
{
  flake.nixosModules.nix-config =
    {
      config,
      pkgs,
      lib,
      inputs,
      inputs',
      ...
    }:
    {
      imports = [ (sharedConfig { inherit inputs'; }) ];

      sops.templates."nix-access-tokens.conf".content = ''
        access-tokens = github.com=${config.sops.placeholder.github_token}
      '';

      nix.extraOptions = ''
        !include ${config.sops.templates."nix-access-tokens.conf".path}
      '';

      nix.settings = {
        experimental-features = [
          "nix-command"
          "flakes"
          "parallel-eval"
        ];
        substituters = [
          "https://nix-gaming.cachix.org"
          "https://nix-community.cachix.org"
          "https://attic.xuyh0120.win/lantian"
          "https://cache.numtide.com"
        ];
        trusted-public-keys = [
          "nix-gaming.cachix.org-1:nbjlureqMbRAxR1gJ/f3hxemL9svXaZF/Ees8vCUUs4="
          "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
          "lantian:EeAUQ+W+6r7EtwnmYjeVwx5kOGEBpjlBfPlzGlTNvHc="
          "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
        ];
        auto-optimise-store = true;
        trusted-users = [
          "root"
          "urio"
        ];
        eval-cores = 0;
        extra-sandbox-paths = [ "/var/cache/ccache" ];
      };

      nix.nixPath = [ "nixpkgs=${inputs.nixpkgs}" ];

      programs.ccache = {
        enable = true;
        packageNames = [ "llama-cpp" ];
      };

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
