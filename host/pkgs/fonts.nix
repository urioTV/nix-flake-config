{
  config,
  pkgs,
  inputs,
  inputs',
  ...
}:

{
  # Enable bindfs
  system.fsPackages = [ pkgs.bindfs ];

  # Create aggregated environments for fonts and icons
  fileSystems =
    let
      # Helper function to create read-only bind mounts
      mkRoSymBind = path: {
        device = path;
        fsType = "fuse.bindfs";
        options = [
          "ro"
          "resolve-symlinks"
          "x-gvfs-hide"
        ];
      };

      # Build aggregated environment for fonts
      aggregatedFonts = pkgs.buildEnv {
        name = "system-fonts";
        paths = config.fonts.packages; # These are your configured fonts
        pathsToLink = [ "/share/fonts" ];
        ignoreCollisions = true;
      };

      # Build aggregated environment for icons
      aggregatedIcons = pkgs.buildEnv {
        name = "system-icons";
        paths = with pkgs; [
          gnome-themes-extra # For Adwaita theme
          # You can add other themes e.g. breeze, papirus, flat-remix etc.
        ];
        pathsToLink = [ "/share/icons" ];
      };

    in
    {
      # Mount aggregated fonts to /usr/share/fonts
      "/usr/share/fonts" = mkRoSymBind "${aggregatedFonts}/share/fonts";

      # Mount aggregated icons to /usr/share/icons
      "/usr/share/icons" = mkRoSymBind "${aggregatedIcons}/share/icons";
    };

  # Ensure fonts are installed
  fonts = {
    enableDefaultPackages = true; # Enable default fonts
    fontDir.enable = true; # Enable font directory
    packages = with pkgs; [
      noto-fonts # Basic fonts
      noto-fonts-cjk-sans
      noto-fonts-cjk-serif
      noto-fonts-color-emoji
      font-awesome
      ubuntu-classic
      baekmuk-ttf
      nerd-font-patcher
      corefonts
      open-sans
      nerd-fonts.hack
      nerd-fonts.noto
      nerd-fonts.open-dyslexic
      nerd-fonts.jetbrains-mono
      inter-nerdfont
    ];
  };

  # Optional: Enable fontconfig configuration
  fonts.fontconfig = {
    antialias = true;
    hinting.enable = true;
    hinting.autohint = true;
    useEmbeddedBitmaps = true;
  };
}
