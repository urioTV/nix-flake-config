{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
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

    kwin-effects-forceblur = {
      url = "github:taj-ny/kwin-effects-forceblur";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    plasma-manager = {
      url = "github:pjones/plasma-manager";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };

    apple-fonts = {
      url = "github:Lyndeno/apple-fonts.nix";
      # inputs.nixpkgs.follows = "nixpkgs";
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
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      home-manager,
      urio-nur,
      stylix,
      apple-fonts,
      nur,
      nix-alien,
      plasma-manager,
      determinate,
      sops-nix,
      flake-parts,
      import-tree,
      ...
    }:
    flake-parts.lib.mkFlake { inherit inputs; } (
      { withSystem, lib, ... }:
      {
        imports = [
          home-manager.flakeModules.home-manager
          ./home.nix
          ./nix-settings.nix
          ./stylix-config.nix
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
                  self.nixosModules.nix-settings
                  # Stylix Configuration
                  self.nixosModules.stylix-config
                  # Home Manager Module
                  home-manager.nixosModules.home-manager
                  self.nixosModules.home

                  # Other Modules
                  urio-nur.nixosModules.default
                  determinate.nixosModules.default
                  stylix.nixosModules.stylix
                  nur.modules.nixos.default
                  sops-nix.nixosModules.sops
                ];
              }
            );
          };
        };
      }
    );
}
