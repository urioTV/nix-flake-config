{ config, pkgs, ... }:

{
  imports = [ ./home ];

  nix.package = pkgs.nix;
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
  home.stateVersion = "23.11"; # Please read the comment before changing.

  # The home.packages option allows you to install Nix packages into your
  # environment.
  home.packages = with pkgs; [
    # # Adds the 'hello' command to your environment. It prints a friendly
    # # "Hello, world!" when run.
    protonup-qt
    spotify-unwrapped
    moonlight-qt
    # teams-for-linux
    # upscayl
    vcmi
    # skypeforlinux
    # rpcs3
    onlyoffice-bin_latest
    mangohud_git
    protonvpn-gui
    vscode
    openmw
    ani-cli

  ];

  programs = {
    git = {
      enable = true;
      userEmail = "uriootv@protonmail.com";
      userName = "urioTV";
    };
    zsh = {
      enable = true;
      zplug = {
        enable = true;
        plugins = [
          { name = "zsh-users/zsh-autosuggestions"; }
          { name = "zsh-users/zsh-completions"; }
        ];
      };
    };
    eza = { enable = true; };
    bat = { enable = true; };
    starship = {
      enable = true;
      enableZshIntegration = true;
      settings = {
        nix_shell = {
          disabled = false;
          impure_msg = "";
          symbol = "";
          format = "[$symbol$state]($style) ";
        };
        shlvl = {
          disabled = false;
          symbol = "λ ";
        };
        haskell.symbol = " ";
      };
    };
    obs-studio = {
      enable = true;
      plugins = with pkgs; [ obs-studio-plugins.obs-vaapi ];
    };
  };

  # programs.mangohud = {
  #     	enable = true;
  #       package = pkgs.mangohud_git;
  #     	settings = {
  #     		# horizontal = true;
  #     		cpu_stats = true;
  #     		gpu_stats = true;
  #     		ram = true;
  #     		vram = true;
  #     		fps = true;
  #     		frametime=0;
  #     		frame_timing=1;
  #     		hud_no_margin = true;
  #     		gpu_power = true;
  #     		cpu_power = true;
  #     	};
  #     };

  xdg.systemDirs.data = [
    "/var/lib/flatpak/exports/share"
    "/home/urio/.local/share/flatpak/exports/share"
  ];

  # Home Manager is pretty good at managing dotfiles. The primary way to manage
  # plain files is through 'home.file'.
  
  # if you don't want to manage your shell through Home Manager.
  home.sessionVariables = {
    # EDITOR = "emacs";
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
