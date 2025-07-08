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
    let
      # Package definitions function - used by both packages and overlay
      makePackages = pkgs: {
        scopebuddy = pkgs.callPackage ./scopebuddy {
          inputs = inputs // {
            inherit scopebuddy;
          };
        };

        vintagestory = pkgs.callPackage ./vintagestory { };
      };
    in
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
        packages = makePackages pkgs;

      in
      {
        inherit packages;

        # Default package
        defaultPackage = packages.scopebuddy;
      }
    )
    // {
      # Export overlay for all systems
      overlays.default = final: prev: makePackages prev;
    };
}
