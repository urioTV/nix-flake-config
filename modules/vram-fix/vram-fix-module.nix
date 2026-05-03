{ inputs, ... }:
let
  # Custom package: dmemcg-booster (Rust)
  # Enables DMEM cgroup controller on systemd cgroups for VRAM prioritization
  dmemcg-booster-pkg =
    { lib, rustPlatform, pkg-config, dbus }:
    rustPlatform.buildRustPackage rec {
      pname = "dmemcg-booster";
      version = "0.1.2";

      src = inputs.dmemcg-booster;

      cargoLock.lockFile = "${inputs.dmemcg-booster}/Cargo.lock";

      nativeBuildInputs = [ pkg-config ];
      buildInputs = [ dbus ];

      postInstall = ''
        mkdir -p $out/lib/systemd/system
        cat > $out/lib/systemd/system/dmemcg-booster-system.service << 'EOF'
        [Unit]
        Description=Service for enabling and controlling dmem cgroup limits for boosting foreground games, system-level

        [Service]
        ExecStart=$out/bin/dmemcg-booster --use-system-bus

        [Install]
        WantedBy=multi-user.target
        EOF

        cat > $out/lib/systemd/system/dmemcg-booster-user.service << 'EOF'
        [Unit]
        Description=Service for enabling and controlling dmem cgroup limits for boosting foreground games, user-level

        [Service]
        ExecStart=$out/bin/dmemcg-booster

        [Install]
        WantedBy=graphical-session-pre.target
        EOF
      '';

      meta = {
        description = "Enables DMEM cgroup controller on systemd cgroups for VRAM prioritization";
        license = lib.licenses.mit;
        platforms = lib.platforms.linux;
      };
    };

# Custom package: KF5CGroups library (Qt6/KF6)
  # From kcgroups dmemcg branch — provides the CGroups library that foreground-booster depends on
  # Despite the KF5 naming, this builds with Qt6 via -DQT_MAJOR_VERSION=6
  kf5cgroups-pkg =
    { lib, stdenv, cmake, extra-cmake-modules, qtbase, wrapQtAppsHook }:
    stdenv.mkDerivation rec {
      pname = "kf5cgroups";
      version = "0-unstable-2025-04-08";

      src = inputs.kcgroups-lib;

      nativeBuildInputs = [
        cmake
        extra-cmake-modules
        wrapQtAppsHook
      ];

      buildInputs = [
        qtbase
      ];

      cmakeFlags = [
        "-DQT_MAJOR_VERSION=6"
      ];

      meta = {
        description = "KDE CGroups library with dmemcg VRAM prioritization support";
        license = lib.licenses.lgpl21Plus;
        platforms = lib.platforms.linux;
      };
    };

  # Custom package: foreground-booster (Qt6/KF6)
  # From kcgroups booster-dmemcg-experimental tag — tracks foreground window in KDE Plasma
  # and assigns it highest VRAM priority via dmem cgroups
  # Binary name is `foreground_booster` (not plasma-foreground-booster)
  # Depends on kf5cgroups (KF5CGroups library from the dmemcg branch)
  foreground-booster-pkg =
    { lib, stdenv, cmake, extra-cmake-modules, qtbase, qttools
    , ki18n, kcoreaddons, kdbusaddons, kconfig, kitemmodels
    , kwindowsystem, plasma-wayland-protocols, libplasma, plasma-workspace
    , wrapQtAppsHook, kf5cgroups
    }:
    stdenv.mkDerivation rec {
      pname = "foreground-booster";
      version = "0-unstable-2026-04-08";

      src = inputs.kcgroups-dmemcg;

      nativeBuildInputs = [
        cmake
        extra-cmake-modules
        wrapQtAppsHook
      ];

      buildInputs = [
        qtbase
        qttools
        ki18n
        kcoreaddons
        kdbusaddons
        kconfig
        kitemmodels
        kwindowsystem
        plasma-wayland-protocols
        libplasma
        plasma-workspace
        kf5cgroups
      ];

      cmakeFlags = [
        "-DQT_MAJOR_VERSION=6"
        "-DKDE_INSTALL_LIBEXECDIR=${placeholder "out"}/libexec"
      ];

      meta = {
        description = "KDE Plasma foreground booster with dmemcg VRAM prioritization support";
        license = lib.licenses.lgpl21Plus;
        platforms = lib.platforms.linux;
      };
    };

  # Overlay providing the custom packages
  vram-fix-overlay =
    final: prev: {
      kf5cgroups = final.kdePackages.callPackage kf5cgroups-pkg { };
      dmemcg-booster = final.kdePackages.callPackage dmemcg-booster-pkg { };
      foreground-booster = final.kdePackages.callPackage foreground-booster-pkg {
        kf5cgroups = final.kf5cgroups;
      };
    };

  # NixOS module: systemd services + kernel params
  vram-fix-nixos =
    { pkgs, ... }:
    {
      # dmemcg-booster system service — activates DMEM cgroup controller
      # and sets memory protection limits on systemd cgroups
      systemd.services.dmemcg-booster = {
        description = "Enable DMEM cgroup controller for VRAM prioritization";
        wantedBy = [ "multi-user.target" ];
        after = [ "systemd-cgroup-setup.service" ];
        serviceConfig = {
          Type = "simple";
          ExecStart = "${pkgs.dmemcg-booster}/bin/dmemcg-booster --use-system-bus";
          Restart = "on-failure";
          RestartSec = 5;
        };
      };

      # dmemcg-booster user service — handles user-level cgroups
      systemd.user.services.dmemcg-booster = {
        description = "Enable DMEM cgroup controller for VRAM prioritization (user-level)";
        wantedBy = [ "graphical-session-pre.target" ];
        after = [ "graphical-session-pre.target" ];
        serviceConfig = {
          Type = "simple";
          ExecStart = "${pkgs.dmemcg-booster}/bin/dmemcg-booster";
          Restart = "on-failure";
          RestartSec = 5;
        };
      };

      # Plasma foreground booster — tracks active window in KDE Plasma
      # and assigns it highest VRAM priority via dmem cgroups
      # Uses Restart=always because the process exits cleanly (code 0) when
      # PlasmaWindowManagement protocol isn't ready yet during early boot,
      # so on-failure restart wouldn't trigger. Always-restart ensures it
      # keeps retrying until Plasma is fully initialized.
      systemd.user.services.foreground-booster = {
        description = "Boost foreground app VRAM priority in KDE Plasma";
        wantedBy = [ "plasma-workspace.target" ];
        after = [ "plasma-workspace.target" ];
        serviceConfig = {
          Type = "simple";
          ExecStart = "${pkgs.foreground-booster}/bin/foreground_booster";
          Restart = "always";
          RestartSec = 5;
        };
      };

      # Ensure cgroup v2-only mode — NixOS defaults to unified cgroup hierarchy
      # via systemd.unified_cgroup_hierarchy=yes, but this param explicitly
      # disables all cgroup v1 controllers at the kernel level, which is
      # required for dmem cgroup controller to function correctly
      boot.kernelParams = [ "cgroup_no_v1=all" ];
    };
in
{
  flake.nixosModules.vram-fix = {
    pkgs,
    ...
  }:
  {
    imports = [ vram-fix-nixos ];
    nixpkgs.overlays = [ vram-fix-overlay ];
  };
}