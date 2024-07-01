{ inputs, config, pkgs, chaotic, ... }: {
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
      plugins = with pkgs;
        [
          # obs-studio-plugins.obs-vaapi
          obs-studio-plugins.obs-vkcapture
        ];
    };
    yazi = {
      enable = true;
      enableZshIntegration = true;
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
}
