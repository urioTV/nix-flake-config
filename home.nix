{ config, pkgs, ... }:

{
  imports = [ ];

  nixpkgs.config.allowUnfree = true;
  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  home.username = "urio";
  home.homeDirectory = "/home/urio";

  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  #
  # You should not change this value, even if you update Home Manager. If you do
  # want to update the value, then make sure to first check the Home Manager
  # release notes.
  home.stateVersion = "23.05"; # Please read the comment before changing.

  # The home.packages option allows you to install Nix packages into your
  # environment.
  home.packages = with pkgs; [
    # # Adds the 'hello' command to your environment. It prints a friendly
    # # "Hello, world!" when run.
     firefox-wayland
     rofi-wayland
     rnix-lsp
  ];
  
  # programs.eww = {
  #	 enable = true;
  #	 package = pkgs.eww-wayland;
  #	 configDir = ./eww-config-dir;
  # };
  programs.waybar = {
    enable = true;
  };

  programs.rofi = {
    enable = true;
    package = pkgs.rofi-wayland;
  };

  programs.vscode.enable = true;
  
  services.dunst.enable = true;

  # Home Manager is pretty good at managing dotfiles. The primary way to manage
  # plain files is through 'home.file'.
  home.file = {
    # # Building this configuration will create a copy of 'dotfiles/screenrc' in
    # # the Nix store. Activating the configuration will then make '~/.screenrc' a
    # # symlink to the Nix store copy.
    # ".screenrc".source = dotfiles/screenrc;
	".config/waybar" = {
	source = ./configs/waybar;
	target = ".config/waybar";
	};
  ".config/rofi" = {
    source = ./configs/rofi;
    target = ".config/rofi";
    };
  ".config/dunst" = {
    source = ./configs/dunst;
    target = ".config/dunst";
    };
    ".config/hypr" = {
      source = ./configs/hypr;
      target = ".config/hypr";
    };
    ".config/kitty" = {
      source = ./configs/kitty;
      target = ".config/kitty";
    };

	
    # # You can also set the file content immediately.
    # ".gradle/gradle.properties".text = ''
    #   org.gradle.console=verbose
    #   org.gradle.daemon.idletimeout=3600000
    # '';
  };

  # You can also manage environment variables but you will have to manually
  # source
  #
  #  ~/.nix-profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  /etc/profiles/per-user/nixos/etc/profile.d/hm-session-vars.sh
  #
  # if you don't want to manage your shell through Home Manager.
  home.sessionVariables = {
    # EDITOR = "emacs";
  };
  #programs.zsh = {
  #  zplug = {
  #    enable = true;
  #    plugins = [
  #      { name = "git"; } 
  #      { name = "npm";  }
  #      { name = "igoradamenko/npm.plugin.zsh";  }
  #      { name = "heroku";  }
  #      { name = "command-not-found";  }
  #      { name = "zsh-users/zsh-autosuggestions";  }
  #      { name = "zsh-users/zsh-completions";  }
  #    ];
  #  };
  #};

  
  #stylix.autoEnable = true;
  #  stylix.image = pkgs.fetchurl {
  #      url = "https://images.hdqwalls.com/wallpapers/heights-are-not-scary-5k-7s.jpg";
  #      sha256 = "rgJkrd7S/uWugPyBVTicbn6HtC8ru5HtEHP426CRSCE=";
  #    };
  #  stylix.base16Scheme = ./dracula/dracula.yaml;
  #  stylix.targets.gnome.enable = true;
  #  stylix.polarity = "dark";
 
  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
