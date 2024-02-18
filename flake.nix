{
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    stylix.url = "github:danth/stylix";
    chaotic.url = "github:chaotic-cx/nyx/nyxpkgs-unstable";
  };


  outputs = { self, nixpkgs, home-manager, stylix, chaotic, ... }@inputs:
    let
      lib = nixpkgs.lib;
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in
    {
      nixosConfigurations = {
        konrad-m18 = lib.nixosSystem {
          specialArgs = { inherit inputs; };
          inherit system;
          modules = [ ./configuration.nix stylix.nixosModules.stylix chaotic.nixosModules.default ];
        };
      };
      homeConfigurations = {
        urio = home-manager.lib.homeManagerConfiguration {
          extraSpecialArgs = { inherit inputs; };
          inherit pkgs;
          modules = [ ./home.nix stylix.homeManagerModules.stylix chaotic.homeManagerModules.default ];
        };
      };
    };

}
