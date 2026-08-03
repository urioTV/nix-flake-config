{
  inputs = {
    # Temporary pin: includes the LACT libdisplay-info_0_3 fix from nixpkgs#546155.
    nixpkgs.url = "github:NixOS/nixpkgs/bcca8dd3bba0686b330fba113dc545b5988f4235";
    import-tree.url = "github:vic/import-tree";
    flake-parts.url = "github:hercules-ci/flake-parts";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # `release` only advances after Hydra uploads every kernel output to the cache.
    nix-cachyos-kernel.url = "git+https://github.com/xddxdd/nix-cachyos-kernel.git?ref=release";

    urio-nur = {
      url = "github:urioTV/urio-nur";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    determinate.url = "https://flakehub.com/f/DeterminateSystems/determinate/*";

    stylix = {
      url = "github:nix-community/stylix";
    };
    nur = {
      url = "github:nix-community/NUR";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-alien.url = "github:thiagokokada/nix-alien";

    kwin-effects-better-blur-dx = {
      url = "github:xarblu/kwin-effects-better-blur-dx";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    plasma-manager = {
      url = "github:pjones/plasma-manager";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };

    llm-agents = {
      url = "github:numtide/llm-agents.nix";
    };

    # Apps
    zen-browser = {
      url = "github:youwen5/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Gaming
    nix-gaming.url = "github:fufexan/nix-gaming";

    # Valve VRAM Fix (dmemcg-booster + foreground-booster + kf5cgroups library)
    dmemcg-booster = {
      url = "git+https://gitlab.steamos.cloud/holo/dmemcg-booster.git";
      flake = false;
    };
    # KF5CGroups library (dmemcg branch) — required by foreground-booster
    kcgroups-lib = {
      url = "github:pixelcluster/kcgroups/dmemcg";
      flake = false;
    };
    # foreground-booster executable (booster-dmemcg-experimental tag)
    kcgroups-dmemcg = {
      url = "github:pixelcluster/kcgroups/booster-dmemcg-experimental";
      flake = false;
    };
    openmw-nix = {
      url = "git+https://codeberg.org/PopeRigby/openmw-nix.git";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    hytale-launcher.url = "github:JPyke3/hytale-launcher-nix";

    # Secrets Management
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-flatpak.url = "github:gmodena/nix-flatpak/?ref=latest";

  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      home-manager,
      urio-nur,
      stylix,
      nur,
      nix-alien,
      plasma-manager,
      determinate,
      sops-nix,
      flake-parts,
      import-tree,
      nix-flatpak,
      llm-agents,
      ...
    }:
    flake-parts.lib.mkFlake { inherit inputs; } (
      { withSystem, lib, ... }:
      {
        imports = [
          home-manager.flakeModules.home-manager
          (import-tree ./modules)
          ./home.nix
        ];

        systems = [ "x86_64-linux" ];

        flake =
          let
            mkNixosConfiguration =
              hostName: hardwareModule:
              withSystem "x86_64-linux" (
                { system, inputs', ... }:
                nixpkgs.lib.nixosSystem {
                  specialArgs = {
                    inherit inputs;
                    inherit import-tree;
                    inherit inputs';
                  };
                  inherit system;
                  modules = [
                    ./configuration.nix
                    hardwareModule
                    { networking.hostName = hostName; }
                    self.nixosModules.nix-config
                    self.nixosModules.stylix-config
                    self.nixosModules.sops-config
                    self.nixosModules.vars
                    self.nixosModules.llama-cpp
                    self.nixosModules.home-urio
                    self.nixosModules.plasma-module

                    # NUR
                    nur.modules.nixos.default
                    urio-nur.nixosModules.default
                    determinate.nixosModules.default
                    nix-flatpak.nixosModules.nix-flatpak
                  ];
                }
              );
            mkInstallerConfiguration = withSystem "x86_64-linux" (
              { system, ... }:
              nixpkgs.lib.nixosSystem {
                inherit system;
                modules = [ ./hosts/konrad-desktop/installer.nix ];
              }
            );
          in
          {
            nixosConfigurations = {
              konrad-m18 = mkNixosConfiguration "konrad-m18" ./hardware-configuration.nix;
              konrad-desktop = mkNixosConfiguration "konrad-desktop" ./hosts/konrad-desktop/hardware-configuration.nix;
              konrad-desktop-installer = mkInstallerConfiguration;
            };
          };
      }
    );
}
