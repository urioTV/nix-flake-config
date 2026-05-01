{ inputs, self, ... }:
let
  sharedConfig =
    { config, pkgs, ... }:
    {
      stylix = {
        enable = true;
        autoEnable = true;
        image = config.vars.wallpaper;
        base16Scheme = config.vars.base16Scheme;
        polarity = "dark";

        targets = {
          gnome.enable = true;
          gtk.enable = true;
        };

        cursor = {
          package = pkgs.bibata-cursors;
          name = "Bibata-Modern-Classic";
          size = 20;
        };
      };
    };
in
{
  flake.nixosModules.stylix-config =
    {
      pkgs,
      lib,
      ...
    }:
    {
      imports = [
        inputs.stylix.nixosModules.stylix
        sharedConfig
      ];

      stylix.targets = {
        chromium.enable = false;
        grub.enable = false;
      };

      qt.platformTheme = lib.mkForce "kde";
    };

  flake.homeModules.stylix-config =
    {
      config,
      pkgs,
      inputs,
      ...
    }:
    {
      imports = [ sharedConfig ];

      stylix = {
        targets.vscode.enable = false;

        fonts = {
          serif = {
            package = pkgs.inter-nerdfont;
            name = "Inter Nerd Font";
          };

          sansSerif = {
            package = pkgs.inter-nerdfont;
            name = "Inter Nerd Font";
          };

          monospace = {
            package = pkgs.nerd-fonts.jetbrains-mono;
            name = "JetBrainsMono Nerd Font Mono";
          };

          emoji = {
            package = pkgs.noto-fonts-color-emoji;
            name = "Noto Color Emoji";
          };
        };
      };

      gtk = {
        cursorTheme = {
          package = pkgs.bibata-cursors;
          name = "Bibata-Modern-Classic";
          size = 20;
        };
        iconTheme = {
          package = pkgs.papirus-icon-theme;
          name = "Papirus";
        };
        gtk2 = {
          force = true;
        };
        enable = true;

        gtk3.extraConfig = {
          gtk-application-prefer-dark-theme = 1;
        };

        gtk4 = {
          theme = config.gtk.theme;
          extraConfig = {
            gtk-application-prefer-dark-theme = 1;
          };
        };
      };

      xdg = {
        systemDirs.data = [
          "${pkgs.gtk3}/share/gsettings-schemas/${pkgs.gtk3.name}"
          "${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/${pkgs.gsettings-desktop-schemas.name}"
        ];
      };
    };
}
