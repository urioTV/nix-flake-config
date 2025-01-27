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
    nushell = {
      enable = true;
      extraConfig = ''$env.config.show_banner = false'';
    };
    zsh = {
      enable = true;
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
  };
}
