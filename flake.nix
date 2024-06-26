{
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    stylix.url = "github:danth/stylix";
    chaotic.url = "github:chaotic-cx/nyx/nyxpkgs-unstable";
    nix-alien.url = "github:thiagokokada/nix-alien";
    hyprland = {
      # url = "https://flakehub.com/f/hyprwm/Hyprland/0.39.*.tar.gz";
      url = "git+https://github.com/hyprwm/Hyprland?submodules=1&rev=fe7b748eb668136dd0558b7c8279bfcd7ab4d759";
      # url = "git+https://github.com/hyprwm/Hyprland?submodules=1";
      inputs.nixpkgs.follows = "nixpkgs";
    };
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

  };

  outputs = { self, nixpkgs, home-manager, stylix, chaotic, nix-alien, hyprland, plasma-manager
    , ... }@inputs:
    let
      lib = nixpkgs.lib;
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      customOverlay = final: prev: {
        gamescope = chaotic.packages.${system}.gamescope_git;
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
            hyprland.homeManagerModules.default
            plasma-manager.homeManagerModules.plasma-manager
          ];
        };
      };
    };

}
