{config, lib, pkgs, ...}:
{
	stylix.autoEnable = true;
	  stylix.image = pkgs.fetchurl {
	      url = "https://images.hdqwalls.com/wallpapers/heights-are-not-scary-5k-7s.jpg";
	      sha256 = "rgJkrd7S/uWugPyBVTicbn6HtC8ru5HtEHP426CRSCE=";
	    };
	  stylix.base16Scheme = ./catppuccin/mocha.yaml;
	  stylix.targets.gnome.enable = true;
	  stylix.polarity = "dark";
	
}
