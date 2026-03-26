{ inputs, ... }:
{
  flake.nixosModules.home-urio =
    {
      config,
      pkgs,
      inputs,
      inputs',
      import-tree,
      ...
    }:
    {
      imports = [ inputs.home-manager.nixosModules.home-manager ];

      home-manager.useUserPackages = true;
      home-manager.backupFileExtension = "bkpnix";
      home-manager.extraSpecialArgs = {
        inherit inputs inputs' import-tree;
        self = inputs.self;
      };
      home-manager.sharedModules = with inputs; [
        nur.modules.homeManager.default
        self.homeModules.vars
        self.homeModules.nix-config
        self.homeModules.stylix-config
        self.homeModules.sops-config
        self.homeModules.ai
        self.homeModules.plasma-module
      ];
      home-manager.users.urio = {
        imports = [ inputs.self.homeModules.home-urio ];
      };
    };

  flake.homeModules.home-urio =
    {
      config,
      import-tree,
      ...
    }:
    {
      imports = (import-tree ./home).imports;

      home.username = "urio";
      home.homeDirectory = "/home/urio";

      home.stateVersion = "23.11";

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
        EDITOR = "micro";
      };
    };
}
