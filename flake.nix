{
 inputs = {
 	nixpkgs.url = "nixpkgs/nixos-unstable";
 	home-manager = {
 	      url = "github:nix-community/home-manager";
 	      inputs.nixpkgs.follows = "nixpkgs";
 	    };
 	hyprland.url = "github:hyprwm/Hyprland";
 	# stylix.url = "github:danth/stylix";
 };


 outputs = { self, nixpkgs, home-manager, ...}@inputs:
 	let
 		lib = nixpkgs.lib;
 		system = "x86_64-linux";
 		pkgs = nixpkgs.legacyPackages.${system};
 	in {
 		nixosConfigurations = {
 			blade14 = lib.nixosSystem {
 			    specialArgs = { inherit inputs; };
 				inherit system;
 				modules = [ ./configuration.nix ];
 			};
 		};
 		homeConfigurations = { 
 			urio = home-manager.lib.homeManagerConfiguration {
 			    extraSpecialArgs = { inherit inputs; }; 
 		        inherit pkgs;
 		        modules = [ ./home.nix ];
 		      };
 		 };
 	};
	
}
