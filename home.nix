{ inputs, ... }:
{
  flake.nixosModules.home =
    {
      config,
      pkgs,
      inputs,
      import-tree,
      ...
    }:
    {
      # home-manager.useGlobalPkgs = true;
      home-manager.useUserPackages = true;
      home-manager.backupFileExtension = "bkpnix";
      home-manager.extraSpecialArgs = {
        inherit inputs;
        inherit import-tree;
      };
      home-manager.sharedModules = with inputs; [
        ./vars.nix
        nur.modules.homeManager.default
        plasma-manager.homeModules.plasma-manager
        self.homeModules.nix-settings
        self.homeModules.stylix-config
      ];
      home-manager.users.urio =
        { config, ... }:
        {
          imports = (import-tree ./home).imports;

          home.username = "urio";
          home.homeDirectory = "/home/urio";

          home.stateVersion = "23.11"; # Please read the comment before changing.

          xdg.systemDirs.data = [
            "/var/lib/flatpak/exports/share"
            "${config.home.homeDirectory}/.local/share/flatpak/exports/share"
          ];

          home.file = {
            ".config/zed" = {
              source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nix-flake-config/dotfiles/zed";
            };
            ".config/Antigravity/User/settings.json" = {
              source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nix-flake-config/dotfiles/antigravity/settings.json";
            };
          };

          home.sessionVariables = {
            # EDITOR = "emacs";
          };

          # Let Home Manager install and manage itself.
          # programs.home-manager.enable = true;
        };
    };
}
