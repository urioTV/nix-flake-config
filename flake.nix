{
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    # nixpkgs.url = "github:NixOS/nixpkgs/7d27fd2b04ede95f27fdce6b8902745777ad4844";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

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

        opencomposite = prev.opencomposite.overrideAttrs (prevAttrs: {
          version = "git-2025-01-10";

          src = prev.fetchFromGitLab {
            owner = "znixian";
            repo = "OpenOVR";
            rev = "bdb830a4bcd04196ba13e8c08a07a4530363aa4b";
            fetchSubmodules = true;
            hash = "sha256-y8djMkjcWA0TSI+3Pc7pAqTGaE5MSGIJpq4/ee7LWQs=";
          };
        });

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
            {
              nixpkgs.overlays = [ customOverlay ];
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
            ./configuration.nix
            ./vars.nix
            ./nix-settings.nix
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
