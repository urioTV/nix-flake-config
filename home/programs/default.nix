{
  inputs,
  config,
  pkgs,
  chaotic,
  lib,
  ...
}:
{
  programs = {
    git = {
      enable = true;
      userEmail = "uriootv@protonmail.com";
      userName = "urioTV";
    };
    nushell = {
      enable = true;
      extraConfig = ''$env.config.show_banner = false'';
    };
    zsh = {
      enable = true;
      antidote = {
        enable = false;
        plugins = [
          "zsh-users/zsh-autosuggestions"
          "zsh-users/zsh-completions"
        ];
      };
      prezto = {
        enable = true;
        pmodules = [
          "environment"
          "terminal"
          "editor"
          "history"
          "directory"
          "spectrum"
          "utility"
          "completion"
          "prompt"
          "autosuggestions"
          "git"
        ];
      };
      shellAliases = {
        nix = "noglob nix";
        nixos-rebuild = "noglob nixos-rebuild";
      };

    };
    carapace = {
      enable = true;
      enableZshIntegration = true;
      enableNushellIntegration = true;
    };
    bat = {
      enable = true;
    };
    starship = {
      enable = true;
      enableZshIntegration = true;
      enableNushellIntegration = true;
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
      plugins = with pkgs; [
        # obs-studio-plugins.obs-vaapi
        # obs-studio-plugins.obs-vkcapture
      ];
    };
  };

  programs.mangohud = {
    enable = true;
    package = pkgs.mangohud_git;
    settings = {
      # horizontal = true;
      cpu_stats = true;
      gpu_stats = true;
      ram = true;
      vram = true;
      fps = true;
      frametime = 0;
      frame_timing = 1;
      hud_no_margin = true;
      gpu_power = true;
      cpu_power = true;

      background_alpha = lib.mkForce 0.3;
      alpha = 1.0;

      font_size = lib.mkForce 24;
      font_scale = lib.mkForce 1.0;
      font_size_text = lib.mkForce 24;
      font_scale_media_player = lib.mkForce 0.55;
      # no_small_font = true;
    };
  };
}
