{
 inputs = {
 	nixpkgs.url = "nixpkgs/nixos-unstable";
 	home-manager = {
 	      url = "github:nix-community/home-manager";
 	      inputs.nixpkgs.follows = "nixpkgs";
 	    };
 	stylix.url = "github:danth/stylix";
 };


 outputs = { self, nixpkgs, home-manager, stylix, ...}@inputs:
 	let
 		lib = nixpkgs.lib;
 		system = "x86_64-linux";
 		pkgs = nixpkgs.legacyPackages.${system};
 	in {
 		nixosConfigurations = {
 			asus-ultra = lib.nixosSystem {
 			    specialArgs = { inherit inputs; };
 				inherit system;
 				modules = [ ./configuration.nix stylix.nixosModules.stylix ];
 			};
 		};
 		homeConfigurations = { 
 			urio = home-manager.lib.homeManagerConfiguration {
 			    extraSpecialArgs = { inherit inputs; }; 
 		        inherit pkgs;
 		        modules = [ ./home.nix stylix.homeManagerModules.stylix];
 		      };
 		 };
 	};
	
}
