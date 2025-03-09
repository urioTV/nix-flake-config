{
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    # nixpkgs.url = "github:NixOS/nixpkgs/a2b5108952b2647890a85de7d5e9d8178c7f2247";
    # nixpkgs-alvr.url = "github:NixOS/nixpkgs/7ba9030c138f08f0a544a0f78fdfefeedae5e284";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    lix-module = {
      url = "git+https://git.lix.systems/lix-project/nixos-module?ref=stable";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    stylix = {
      # url = "github:danth/stylix/d9df2b4200ba53a0944c3d2c6d242095e523d3d9";
      url = "github:danth/stylix";
    };

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

    # Apps
    zen-browser = {
      url = "https://flakehub.com/f/youwen5/zen-browser/*";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Gaming
    nix-gaming.url = "github:fufexan/nix-gaming";

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
            {
              nixpkgs.overlays = [
                (import ./overlay.nix {
                  inherit inputs;
                  inherit system;
                })
              ];
              nixpkgs.config.allowUnfree = true;
              chaotic.nyx.cache.enable = true;

              nixpkgs.config.permittedInsecurePackages = [
                "aspnetcore-runtime-6.0.36"
                "aspnetcore-runtime-wrapped-6.0.36"
                "dotnet-sdk-6.0.428"
                "dotnet-sdk-wrapped-6.0.428"
                "dotnet-runtime-6.0.36"
                "dotnet-runtime-wrapped-6.0.36"
              ];
            }
            {
              # home-manager.useUserService = true; # Added by patch above ^
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.backupFileExtension = "bkpnix";
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
            lix-module.nixosModules.default
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
