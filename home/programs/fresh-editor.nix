{
  config,
  pkgs,
  lib,
  ...
}:
let
  themeFile = ./fresh-editor-catppuccin-mocha.json;

  lspPackages = with pkgs; [
    nixd
    pyright
    typescript-language-server
    typescript
    rust-analyzer
    gopls
    marksman
    texlab
    yaml-language-server
    tofu-ls
  ];
in
{
  programs.fresh-editor = {
    enable = true;
    defaultEditor = false;
    extraPackages = lspPackages;

    settings = {
      version = 1;
      theme = "catppuccin-mocha.json";
      editor = {
        tab_size = 4;
        line_numbers = true;
      };

      file_explorer.show_hidden = true;
      file_explorer.show_gitignored = true;

      lsp_enabled = true;

      lsp = {
        nix = {
          command = "nixd";
          args = [ ];
          enabled = true;
        };

        python = {
          command = "pyright-langserver";
          args = [ "--stdio" ];
          enabled = true;
        };

        typescript = {
          command = "typescript-language-server";
          args = [ "--stdio" ];
          enabled = true;
          language_id_overrides = {
            typescriptreact = "typescriptreact";
            javascriptreact = "javascriptreact";
          };
        };

        rust = {
          command = "rust-analyzer";
          args = [ ];
          enabled = true;
        };

        go = {
          command = "gopls";
          args = [ ];
          enabled = true;
        };

        markdown = {
          command = "marksman";
          args = [ "server" ];
          enabled = true;
        };

        latex = {
          command = "texlab";
          args = [ ];
          enabled = true;
        };

        yaml = {
          command = "yaml-language-server";
          args = [ "--stdio" ];
          enabled = true;
        };

        terraform = {
          command = "tofu-ls";
          args = [ "serve" ];
          enabled = true;
        };
      };
    };
  };

  xdg.configFile."fresh/themes/catppuccin-mocha.json".source = themeFile;
}
