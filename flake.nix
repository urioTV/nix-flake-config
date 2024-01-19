{
 inputs = {
 	nixpkgs.url = "nixpkgs/nixos-unstable";
 	home-manager = {
 	      url = "github:nix-community/home-manager";
 	      inputs.nixpkgs.follows = "nixpkgs";
 	    };
 	stylix.url = "github:danth/stylix";
 	solaar = {
 	      url = "github:Svenum/Solaar-Flake/main";
 	      inputs.nixpkgs.follows = "nixpkgs";
 	    };
 };


 outputs = { self, nixpkgs, home-manager, stylix, solaar, ...}@inputs:
 	let
 		lib = nixpkgs.lib;
 		system = "x86_64-linux";
 		pkgs = nixpkgs.legacyPackages.${system};
 	in {
 		nixosConfigurations = {
 			asus-ultra = lib.nixosSystem {
 			    specialArgs = { inherit inputs; };
 				inherit system;
 				modules = [ ./configuration.nix stylix.nixosModules.stylix solaar.nixosModules.default ];
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
