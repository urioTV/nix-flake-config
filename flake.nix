{
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    home-manager = {
      # url = "github:nix-community/home-manager/75268f62525920c4936404a056f37b91e299c97e";
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    lix-module = {
      # url = "git+https://git.lix.systems/lix-project/nixos-module?ref=release-2.93";
      url = "https://git.lix.systems/lix-project/nixos-module/archive/2.93.0.tar.gz";
      inputs = {
        # flake-utils.follows = "flake-utils";
        nixpkgs.follows = "nixpkgs";
      };
    };

    stylix = {
      # url = "github:danth/stylix/fe3feecf23f8c71067c47a2cfaca5e86c8723450";
      url = "github:danth/stylix";
      # url = "https://flakehub.com/f/danth/stylix/0.1.*.tar.gz";
    };

    chaotic = {
      url = "github:chaotic-cx/nyx/nyxpkgs-unstable";
      # url = "https://flakehub.com/f/chaotic-cx/nyx/*.tar.gz";
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

    # Apps
    zen-browser = {
      url = "github:youwen5/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Gaming
    nix-gaming.url = "github:fufexan/nix-gaming";
    scopebuddy = {
      url = "github:HikariKnight/ScopeBuddy";
      flake = false;
    };
    openmw-nix = {
      url = "git+https://codeberg.org/PopeRigby/openmw-nix.git";
      inputs.nixpkgs.follows = "nixpkgs";
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
      lix-module,
      ...
    }@inputs:
    let
      lib = nixpkgs.lib;
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      myOverlay = import ./overlay.nix {
        inherit inputs system;
      };
      commonNixpkgsConfig = {
        nixpkgs.overlays = [ myOverlay ];
        nixpkgs.config.allowUnfree = true;
      };
    in
    {
      nixosConfigurations = {
        konrad-m18 = lib.nixosSystem {
          specialArgs = {
            inherit inputs;
          };
          inherit system;
          modules = [
            ./configuration.nix
            ./vars.nix
            ./nix-settings.nix
            commonNixpkgsConfig
            stylix.nixosModules.stylix
            chaotic.nixosModules.default
            lix-module.nixosModules.default
            home-manager.nixosModules.home-manager

            # Home Manager Configuration
            {
              # home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.backupFileExtension = "bkpnix";
              home-manager.extraSpecialArgs = {
                inherit inputs;
              };
              home-manager.sharedModules = [
                ./vars.nix
                chaotic.homeManagerModules.default
                plasma-manager.homeManagerModules.plasma-manager
                commonNixpkgsConfig
              ];
              home-manager.users.urio = {
                imports = [ ./home.nix ];
              };
            }
          ];
        };
      };
    };

}
