{
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    stylix.url =
      "git+https://github.com/danth/stylix?rev=29148118cc33f08b71058e1cda7ca017f5300b51";
    chaotic.url = "github:chaotic-cx/nyx/nyxpkgs-unstable";
    nix-alien.url = "github:thiagokokada/nix-alien";
    suyu = {
      url = "git+https://git.suyu.dev/suyu/nix-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    kwin-effects-forceblur = {
      url = "github:taj-ny/kwin-effects-forceblur";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    plasma-manager = {
      url = "github:pjones/plasma-manager";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };

    nix-citizen.url = "github:LovingMelody/nix-citizen";

    # Optional - updates underlying without waiting for nix-citizen to update
    nix-gaming.url = "github:fufexan/nix-gaming";
    nix-citizen.inputs.nix-gaming.follows = "nix-gaming";

  };

  outputs = { self, nixpkgs, home-manager, stylix, chaotic, nix-alien
    , plasma-manager, ... }@inputs:
    let
      lib = nixpkgs.lib;
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      customOverlay = final: prev: {
        gamescope = chaotic.packages.${system}.gamescope_git;
        nix = pkgs.lix;

        # star-citizen = inputs.nix-citizen.packages.${system}.star-citizen.override (prev: {
        #   # Recommended to keep the previous overrides
        #   preCommands = "export radv_zero_vram=true";
          
        # });

      };
    in {
      nixosConfigurations = {
        konrad-m18 = lib.nixosSystem {
          specialArgs = { inherit inputs; };
          inherit system;
          modules = [
            { nixpkgs.overlays = [ customOverlay ]; }
            ./configuration.nix
            stylix.nixosModules.stylix
            chaotic.nixosModules.default
          ];
        };
      };
      homeConfigurations = {
        urio = home-manager.lib.homeManagerConfiguration {
          extraSpecialArgs = { inherit inputs; };
          inherit pkgs;
          modules = [
            { nixpkgs.overlays = [ customOverlay ]; }
            ./home.nix
            stylix.homeManagerModules.stylix
            chaotic.homeManagerModules.default
            plasma-manager.homeManagerModules.plasma-manager
          ];
        };
      };
    };

}
