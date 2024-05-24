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
      url = "https://flakehub.com/f/hyprwm/Hyprland/0.40.*.tar.gz";
      # url = "git+https://github.com/hyprwm/Hyprland?submodules=1";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    suyu = {
      url = "git+https://git.suyu.dev/suyu/nix-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Hyprspace = {
    #   url = "github:KZDKM/Hyprspace";

    #   # Hyprspace uses latest Hyprland. We declare this to keep them in sync.
    #   inputs.hyprland.follows = "hyprland";
    # };

  };

  outputs = { self, nixpkgs, home-manager, stylix, chaotic, nix-alien, hyprland
    , ... }@inputs:
    let
      lib = nixpkgs.lib;
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      nixosConfigurations = {
        konrad-m18 = lib.nixosSystem {
          specialArgs = { inherit inputs; };
          inherit system;
          modules = [
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
            ./home.nix
            stylix.homeManagerModules.stylix
            chaotic.homeManagerModules.default
            hyprland.homeManagerModules.default
          ];
        };
      };
    };

}
