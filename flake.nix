{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    # nixpkgs.url = "github:NixOS/nixpkgs/master";
    import-tree.url = "github:vic/import-tree";
    flake-parts.url = "github:hercules-ci/flake-parts";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    urio-nur = {
      url = "github:urioTV/urio-nur";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    determinate.url = "https://flakehub.com/f/DeterminateSystems/determinate/*";

    stylix = {
      url = "github:nix-community/stylix";
    };
    nur = {
      url = "github:nix-community/NUR";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-alien.url = "github:thiagokokada/nix-alien";

    kwin-effects-better-blur-dx = {
      url = "github:xarblu/kwin-effects-better-blur-dx";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    plasma-manager = {
      url = "github:pjones/plasma-manager";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };

    # Apps
    zen-browser = {
      url = "github:youwen5/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Gaming
    nix-gaming.url = "github:fufexan/nix-gaming";
    openmw-nix = {
      url = "git+https://codeberg.org/PopeRigby/openmw-nix.git";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    hytale-launcher.url = "github:JPyke3/hytale-launcher-nix";

    # Secrets Management
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-flatpak.url = "github:gmodena/nix-flatpak/?ref=latest";

  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      home-manager,
      urio-nur,
      stylix,
      nur,
      nix-alien,
      plasma-manager,
      determinate,
      sops-nix,
      flake-parts,
      import-tree,
      nix-flatpak,
      ...
    }:
    flake-parts.lib.mkFlake { inherit inputs; } (
      { withSystem, lib, ... }:
      {
        imports = [
          home-manager.flakeModules.home-manager
          (import-tree ./modules)
          ./home.nix
        ];

        systems = [ "x86_64-linux" ];

        flake = {
          nixosConfigurations = {
            konrad-m18 = withSystem "x86_64-linux" (
              { system, inputs', ... }:
              let
                lib = nixpkgs.lib;
              in
              lib.nixosSystem {
                specialArgs = {
                  inherit inputs;
                  inherit import-tree;
                  inherit inputs';
                };
                inherit system;
                modules = [
                  ./configuration.nix
                  self.nixosModules.nix-config
                  self.nixosModules.stylix-config
                  self.nixosModules.sops-config
                  self.nixosModules.vars
                  self.nixosModules.home-urio
                  self.nixosModules.plasma-module

                  # NUR
                  nur.modules.nixos.default
                  urio-nur.nixosModules.default
                  determinate.nixosModules.default
                  nix-flatpak.nixosModules.nix-flatpak
                ];
              }
            );
          };
        };
      }
    );
}
