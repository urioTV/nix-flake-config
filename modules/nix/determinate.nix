# Determinate Nix — https://docs.determinate.systems/guides/advanced-installation/#nixos
{
  flake.nixosModules.determinate =
    { inputs, lib, ... }:
    {
      imports = [ inputs.determinate.nixosModules.default ];

      determinate.enable = true;

      # Without this the registry would point at FlakeHub's nixpkgs-weekly, so
      # `nix shell nixpkgs#foo` would use a different nixpkgs than the system.
      nix.registry.nixpkgs.flake = inputs.nixpkgs;

      nix.settings = {
        # Determinate's own cache; the first switch needs these as --option flags.
        extra-substituters = [ "https://install.determinate.systems" ];
        extra-trusted-public-keys = [
          "cache.flakehub.com-3:hJuILl5sVK4iKm86JzgdXW12Y2Hwd5G07qKtHTOcDCM="
        ];

        # Parallel eval, off in the shipped binary; helps `nix search` (1.9x here),
        # not `nixos-rebuild`.
        eval-cores = 0;

        # Copy flake inputs to the store only when a derivation needs them.
        lazy-trees = true;
      };

      # determinate-nixd garbage-collects on disk pressure but never expires
      # generations, so `nix.gc` in ./nix-config.nix stays enabled.
    };
}
