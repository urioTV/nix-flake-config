{
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # lix-module = {
    #   url =
    #     "git+https://git.lix.systems/lix-project/nixos-module?ref=release-2.91";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };

    stylix = {
      url = "github:danth/stylix";
      inputs.base16.follows = "base16";
    };
    base16.url = "github:Noodlez1232/base16.nix/slugify-fix";

    chaotic.url = "github:chaotic-cx/nyx/nyxpkgs-unstable";
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

    # Gaming
    nix-gaming.url = "github:fufexan/nix-gaming";
    nix-citizen = {
      url = "github:LovingMelody/nix-citizen";
      inputs.nix-gaming.follows = "nix-gaming";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      stylix,
      chaotic,
      nix-alien,
      plasma-manager,
      ...
    }@inputs:
    let
      lib = nixpkgs.lib;
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      customOverlay = final: prev: {
        gamescope = chaotic.packages.${system}.gamescope_git;

      };
    in
    # home-manager = let
    #   src = nixpkgs.legacyPackages.${system}.applyPatches {
    #     name = "home-manager";
    #     src = inputs.home-manager;
    #     patches = nixpkgs.legacyPackages.${system}.fetchpatch {
    #       url =
    #         "https://patch-diff.githubusercontent.com/raw/nix-community/home-manager/pull/2548.patch";
    #       sha256 = "sha256-weI2sTxjEtQbdA76f3fahC9thiQbGSzOYQ7hwHvqt8s=";
    #     };
    #   };
    # in nixpkgs.lib.fix
    # (self: (import "${src}/flake.nix").outputs { inherit self nixpkgs; });
    {
      nixosConfigurations = {
        konrad-m18 = lib.nixosSystem {
          specialArgs = {
            inherit inputs;
          };
          inherit system;
          modules = [
            {
              nixpkgs.overlays = [ customOverlay ];
              nixpkgs.config.allowUnfree = true;
            }
            ./configuration.nix
            ./vars.nix
            ./nix-settings.nix
            {
              # home-manager.useUserService = true; # Added by patch above ^
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.backupFileExtension = "backupnix3";
              home-manager.extraSpecialArgs = {
                inherit inputs;
              };
              home-manager.sharedModules = [
                ./vars.nix
                chaotic.homeManagerModules.default
                plasma-manager.homeManagerModules.plasma-manager
              ];
              home-manager.users.urio = {
                imports = [ ./home.nix ];
              };
            }
            home-manager.nixosModules.home-manager
            stylix.nixosModules.stylix
            chaotic.nixosModules.default
            # lix-module.nixosModules.default
          ];
        };
      };
      # homeConfigurations = {
      #   urio = home-manager.lib.homeManagerConfiguration {
      #     extraSpecialArgs = { inherit inputs; };
      #     inherit pkgs;
      #     modules = [
      #       { nixpkgs.overlays = [ customOverlay ]; }
      #       ./home.nix
      #       stylix.homeManagerModules.stylix
      #       chaotic.homeManagerModules.default
      #       plasma-manager.homeManagerModules.plasma-manager
      #     ];
      #   };
      # };
    };

}
