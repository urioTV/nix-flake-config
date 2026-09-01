{ inputs, ... }:
let
  sharedConfig =
    { inputs' }:
    {
      nixpkgs.overlays = [
        (inputs.nur.overlays.default)
        (import ./_overlay.nix { inherit inputs'; })
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

      home-manager.sharedModules = [ (sharedConfig { inherit inputs'; }) ];

      sops.templates."nix-access-tokens.conf" = {
        content = ''
          access-tokens = github.com=${config.sops.placeholder.github_token}
        '';
        # Nix reads this file as the invoking user; keep it readable by the
        # `keys` group (urio is a member) instead of root-only 0400.
        group = "keys";
        mode = "0440";
      };

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
          "https://nix-on-droid.cachix.org"
          "https://attic.xuyh0120.win/lantian"
          "https://cache.numtide.com"
        ];
        trusted-public-keys = [
          "nix-gaming.cachix.org-1:nbjlureqMbRAxR1gJ/f3hxemL9svXaZF/Ees8vCUUs4="
          "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
          "nix-on-droid.cachix.org-1:56snoMJTXmDRC1Ei24CmKoUqvHJ9XCp+nidK7qkMQrU="
          "lantian:EeAUQ+W+6r7EtwnmYjeVwx5kOGEBpjlBfPlzGlTNvHc="
          "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
        ];
        auto-optimise-store = false;
        trusted-users = [
          "root"
          "urio"
        ];
        eval-cores = 0;
        # Substitution throughput; defaults are 16 / 25 / 1 MiB, and that small
        # buffer is what causes "download buffer is full" stalls.
        max-substitution-jobs = 32;
        http-connections = 50;
        download-buffer-size = 134217728; # 128 MiB
      };

      nix.nixPath = [ "nixpkgs=${inputs.nixpkgs}" ];

      nix.gc = {
        automatic = true;
        dates = "daily";
        options = "--delete-older-than 2d";
      };

      # Deduplicate on a timer rather than inline on every store write (inline
      # costs a scan + hard link per file).
      nix.optimise = {
        automatic = true;
        dates = [ "03:45" ];
      };

      programs.nh = {
        enable = true;
        flake = "/home/urio/nix-flake-config";
      };

    };

}
