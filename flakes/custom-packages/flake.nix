{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";

    # External inputs needed for packages
    scopebuddy = {
      url = "github:HikariKnight/ScopeBuddy";
      flake = false;
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      scopebuddy,
      ...
    }@inputs:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config = {
            allowUnfree = true;
            permittedInsecurePackages = [
              "dotnet-runtime-7.0.20"
              "dotnet-runtime-wrapped-7.0.20"
            ];
          };
        };

        # Package definitions
        packages = {
          scopebuddy = pkgs.callPackage ./scopebuddy {
            inputs = inputs // {
              inherit scopebuddy;
            };
          };

          vintagestory = pkgs.callPackage ./vintagestory { };
        };

        # Overlay definition
        overlay = final: prev: packages;

      in
      {
        inherit packages;

        # Export the overlay
        overlays.default = overlay;

        # Default package
        defaultPackage = packages.scopebuddy;
      }
    )
    // {
      # Export overlay for all systems
      overlays.default = final: prev: {
        scopebuddy = prev.callPackage ./scopebuddy {
          inputs = inputs // {
            scopebuddy = inputs.scopebuddy;
          };
        };

        vintagestory = prev.callPackage ./vintagestory { };
      };
    };
}
