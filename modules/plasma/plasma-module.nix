{ inputs, self, ... }:
{
  flake.nixosModules.plasma-module =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    {
      services.displayManager.sddm = {
        enable = true;
        autoNumlock = true;
        wayland.enable = true;
      };

      services.desktopManager.plasma6.enable = true;

      xdg.portal = {
        enable = true;
        extraPortals = with pkgs; [
          xdg-desktop-portal-gtk
        ];
      };

      environment.systemPackages = with pkgs; [
        (pkgs.writeTextDir "share/sddm/themes/breeze/theme.conf.user" ''
          [General]
          background=${config.vars.wallpaper}
        '')
        inputs.kwin-effects-better-blur-dx.packages.${pkgs.system}.default
        kdePackages.filelight
        kdePackages.kalk
        kdePackages.accounts-qt
        kdePackages.kaccounts-providers
        kdePackages.kaccounts-integration
        kdePackages.kmail-account-wizard
        adwaita-icon-theme
      ];

      environment.sessionVariables = {
        KWIN_USE_OVERLAYS = "1";
      };

    };

  flake.homeModules.plasma-module =
    {
      pkgs,
      inputs,
      config,
      ...
    }:
    {
      imports = [
        inputs.plasma-manager.homeModules.plasma-manager
      ];

      home.packages = with pkgs; [ catppuccin-qt5ct ];

      stylix.targets.qt.enable = false;

      programs.plasma = {
        enable = true;

        workspace = {
          colorScheme = "CatppuccinMocha";
          cursor.theme = "Bibata-Modern-Classic";
          iconTheme = "Papirus";
          wallpaper = config.vars.wallpaper;
        };
        fonts = {
          # general = {
          #   family = "SFProText Nerd Font";
          #   pointSize = 13;
          # };
          # fixedWidth = {
          #   family = "SFProText Nerd Font";
          #   pointSize = 13;
          # };
          # small = {
          #   family = "SFProText Nerd Font";
          #   pointSize = 11;
          # };
          # toolbar = {
          #   family = "SFProText Nerd Font";
          #   pointSize = 11;
          # };
          # menu = {
          #   family = "SFProText Nerd Font";
          #   pointSize = 11;
          # };
          windowTitle = {
            family = "Inter Nerd Font";
            pointSize = 12;
          };
        };
        powerdevil = {
          AC = {
            autoSuspend = {
              action = "nothing";
            };
            dimDisplay = {
              enable = true;
              idleTimeout = 600;
            };
            turnOffDisplay = {
              idleTimeout = 14400;
              idleTimeoutWhenLocked = 14400;
            };
            # powerProfile = "balanced";
            whenLaptopLidClosed = "sleep";
            whenSleepingEnter = "standbyThenHibernate";
            powerButtonAction = "showLogoutScreen";
          };
          battery = {
            whenLaptopLidClosed = "sleep";
            whenSleepingEnter = "standbyThenHibernate";
            powerButtonAction = "showLogoutScreen";
          };
          lowBattery = {
            whenLaptopLidClosed = "sleep";
            whenSleepingEnter = "standbyThenHibernate";
            powerButtonAction = "showLogoutScreen";
          };
        };

        kscreenlocker = {
          autoLock = true;
          timeout = 120;
        };

        shortcuts = {
          "kwin"."Overview" = "Meta+Tab";
          "kwin"."Show Desktop" = "Meta+D";
          "kwin"."Switch to Desktop 1" = "Meta+1";
          "kwin"."Switch to Desktop 10" = "Meta+0";
          "kwin"."Switch to Desktop 2" = "Meta+2";
          "kwin"."Switch to Desktop 3" = "Meta+3";
          "kwin"."Switch to Desktop 4" = "Meta+4";
          "kwin"."Switch to Desktop 5" = "Meta+5";
          "kwin"."Switch to Desktop 6" = "Meta+6";
          "kwin"."Switch to Desktop 7" = "Meta+7";
          "kwin"."Switch to Desktop 8" = "Meta+8";
          "kwin"."Switch to Desktop 9" = "Meta+9";
          "kwin"."Window Close" = [
            "Meta+Q"
            "Alt+F4"
          ];
          "kwin"."Window Fullscreen" = [ ];
          "kwin"."Window Shrink Horizontal" = [ ];
          "kwin"."Window Shrink Vertical" = [ ];
          "kwin"."Window to Desktop 1" = "Meta+!";
          "kwin"."Window to Desktop 10" = "Meta+)";
          "kwin"."Window to Desktop 2" = "Meta+@";
          "kwin"."Window to Desktop 3" = "Meta+#";
          "kwin"."Window to Desktop 4" = "Meta+$";
          "kwin"."Window to Desktop 5" = "Meta+%";
          "kwin"."Window to Desktop 6" = "Meta+^";
          "kwin"."Window to Desktop 7" = "Meta+&";
          "kwin"."Window to Desktop 8" = "Meta+*";
          "kwin"."Window to Desktop 9" = "Meta+(";
          "plasmashell"."activate task manager entry 1" = [ ];
          "plasmashell"."activate task manager entry 10" = [ ];
          "plasmashell"."activate task manager entry 2" = [ ];
          "plasmashell"."activate task manager entry 3" = [ ];
          "plasmashell"."activate task manager entry 4" = [ ];
          "plasmashell"."activate task manager entry 5" = [ ];
          "plasmashell"."activate task manager entry 6" = [ ];
          "plasmashell"."activate task manager entry 7" = [ ];
          "plasmashell"."activate task manager entry 8" = [ ];
          "plasmashell"."activate task manager entry 9" = [ ];
          "services/org.kde.dolphin.desktop"."_launch" = "Meta+W";
          "services/org.kde.konsole.desktop"."_launch" = [
            "Meta+E"
            "Ctrl+Alt+T"
          ];
          "services/org.kde.spectacle.desktop"."ActiveWindowScreenShot" = [ ];
          "services/org.kde.spectacle.desktop"."FullScreenScreenShot" = "Meta+Shift+S";
          "services/org.kde.spectacle.desktop"."RectangularRegionScreenShot" = "Meta+S";
          "services/org.kde.spectacle.desktop"."WindowUnderCursorScreenShot" = "Meta+Alt+S";
          "services/org.kde.spectacle.desktop"."_launch" = "Print";
        };
        configFile = {
          "kwinrc"."Effect-better-blur-dx"."BlurDecorations" = true;
          "kwinrc"."Effect-better-blur-dx"."BlurDocks" = true;
          "kwinrc"."Effect-better-blur-dx"."BlurMatching" = false;
          "kwinrc"."Effect-better-blur-dx"."BlurMenus" = true;
          "kwinrc"."Effect-better-blur-dx"."BlurNonMatching" = true;
          "kwinrc"."Effect-better-blur-dx"."BlurStrength" = 3;
          "kwinrc"."Effect-blurplus"."BlurDecorations" = true;
          "kwinrc"."Effect-blurplus"."BlurMatching" = false;
          "kwinrc"."Effect-blurplus"."BlurNonMatching" = true;
          "kwinrc"."Effect-blurplus"."BlurStrength" = 4;
          "kwinrc"."Effect-blurplus"."BottomCornerRadius" = 25;
          "kwinrc"."Effect-blurplus"."DockCornerRadius" = 25;
          "kwinrc"."Effect-blurplus"."MenuCornerRadius" = 25;
          "kwinrc"."Effect-blurplus"."NoiseStrength" = 0;
          "kwinrc"."Effect-blurplus"."TopCornerRadius" = 25;
          "kwinrc"."Effect-blurplus"."WindowClasses" = "";
          "kwinrc"."Plugins"."better_blur_dxEnabled" = true;
          "kwinrc"."Plugins"."blurEnabled" = false;
          "kwinrc"."Plugins"."forceblurEnabled" = true;

          "kwinrc"."TabBox"."DesktopMode" = 0;
          "kwinrc"."Xwayland"."Scale" = 1;
          "kwinrulesrc"."1"."Description" = "Konsole Blur";
          "kwinrulesrc"."1"."opacityactive" = 90;
          "kwinrulesrc"."1"."opacityactiverule" = 2;
          "kwinrulesrc"."1"."wmclass" = "org.kde.konsole";
          "kwinrulesrc"."1"."wmclassmatch" = 1;
          "kwinrulesrc"."2"."Description" = "Dolphin Blur";
          "kwinrulesrc"."2"."opacityactive" = 90;
          "kwinrulesrc"."2"."opacityactiverule" = 2;
          "kwinrulesrc"."2"."wmclass" = "org.kde.dolphin";
          "kwinrulesrc"."2"."wmclassmatch" = 1;
          "kwinrulesrc"."2953631e-40b3-43e6-9b40-5733a200e59a"."Description" = "Spotify Blur";
          "kwinrulesrc"."2953631e-40b3-43e6-9b40-5733a200e59a"."opacityactive" = 95;
          "kwinrulesrc"."2953631e-40b3-43e6-9b40-5733a200e59a"."opacityactiverule" = 2;
          "kwinrulesrc"."2953631e-40b3-43e6-9b40-5733a200e59a"."wmclass" = "Spotify";
          "kwinrulesrc"."2953631e-40b3-43e6-9b40-5733a200e59a"."wmclassmatch" = 2;
          "kwinrulesrc"."abe17153-b183-4a13-aaad-316778b49290"."Description" = "Tidal Blur";
          "kwinrulesrc"."abe17153-b183-4a13-aaad-316778b49290"."opacityactive" = 95;
          "kwinrulesrc"."abe17153-b183-4a13-aaad-316778b49290"."opacityactiverule" = 2;
          "kwinrulesrc"."abe17153-b183-4a13-aaad-316778b49290"."wmclass" = "tidal-hifi";
          "kwinrulesrc"."abe17153-b183-4a13-aaad-316778b49290"."wmclassmatch" = 2;
          "kwinrulesrc"."3"."Description" = "Code Blur";
          "kwinrulesrc"."3"."opacityactive" = 97;
          "kwinrulesrc"."3"."opacityactiverule" = 2;
          "kwinrulesrc"."3"."wmclass" = "code-url-handler";
          "kwinrulesrc"."3"."wmclassmatch" = 1;
          "kwinrulesrc"."3fd545be-e262-456e-b6dd-90e0fcbf71c3"."Description" = "Dolphin Blur";
          "kwinrulesrc"."3fd545be-e262-456e-b6dd-90e0fcbf71c3"."opacityactive" = 90;
          "kwinrulesrc"."3fd545be-e262-456e-b6dd-90e0fcbf71c3"."opacityactiverule" = 2;
          "kwinrulesrc"."3fd545be-e262-456e-b6dd-90e0fcbf71c3"."wmclass" = "org.kde.dolphin";
          "kwinrulesrc"."3fd545be-e262-456e-b6dd-90e0fcbf71c3"."wmclassmatch" = 1;
          "kwinrulesrc"."4"."Description" = "Vesktop Blur";
          "kwinrulesrc"."4"."opacityactive" = 97;
          "kwinrulesrc"."4"."opacityactiverule" = 2;
          "kwinrulesrc"."4"."wmclass" = "vesktop";
          "kwinrulesrc"."4"."wmclassmatch" = 2;
          "kwinrulesrc"."4f56ab29-f70a-4efb-888a-06394744796f"."Description" = "Code x11 Blur";
          "kwinrulesrc"."4f56ab29-f70a-4efb-888a-06394744796f"."opacityactive" = 97;
          "kwinrulesrc"."4f56ab29-f70a-4efb-888a-06394744796f"."opacityactiverule" = 2;
          "kwinrulesrc"."4f56ab29-f70a-4efb-888a-06394744796f"."wmclass" = "Code";
          "kwinrulesrc"."4f56ab29-f70a-4efb-888a-06394744796f"."wmclassmatch" = 1;
          "kwinrulesrc"."5"."Description" = "Spotify Blur";
          "kwinrulesrc"."5"."opacityactive" = 95;
          "kwinrulesrc"."5"."opacityactiverule" = 2;
          "kwinrulesrc"."5"."wmclass" = "Spotify";
          "kwinrulesrc"."5"."wmclassmatch" = 2;
          "kwinrulesrc"."9392c64d-382a-4104-a987-eb168d855a24"."Description" = "Code x11 Blur";
          "kwinrulesrc"."9392c64d-382a-4104-a987-eb168d855a24"."opacityactive" = 97;
          "kwinrulesrc"."9392c64d-382a-4104-a987-eb168d855a24"."opacityactiverule" = 2;
          "kwinrulesrc"."9392c64d-382a-4104-a987-eb168d855a24"."wmclass" = "Code";
          "kwinrulesrc"."9392c64d-382a-4104-a987-eb168d855a24"."wmclassmatch" = 1;
          "kwinrulesrc"."9ef289a6-6fc5-42f3-8258-21b32fcb15be"."Description" = "Code Blur";
          "kwinrulesrc"."9ef289a6-6fc5-42f3-8258-21b32fcb15be"."opacityactive" = 97;
          "kwinrulesrc"."9ef289a6-6fc5-42f3-8258-21b32fcb15be"."opacityactiverule" = 2;
          "kwinrulesrc"."9ef289a6-6fc5-42f3-8258-21b32fcb15be"."wmclass" = "code-url-handler";
          "kwinrulesrc"."9ef289a6-6fc5-42f3-8258-21b32fcb15be"."wmclassmatch" = 1;
          "kwinrulesrc"."General"."count" = 6;
          "kwinrulesrc"."General"."rules" = "1,2,3,4f56ab29-f70a-4efb-888a-06394744796f,4,5";
          "kwinrulesrc"."be1f6b37-ae44-483c-ba4e-63082b9d79da"."Description" = "Code x11 Blur";
          "kwinrulesrc"."be1f6b37-ae44-483c-ba4e-63082b9d79da"."opacityactive" = 97;
          "kwinrulesrc"."be1f6b37-ae44-483c-ba4e-63082b9d79da"."opacityactiverule" = 2;
          "kwinrulesrc"."be1f6b37-ae44-483c-ba4e-63082b9d79da"."wmclass" = "Code";
          "kwinrulesrc"."be1f6b37-ae44-483c-ba4e-63082b9d79da"."wmclassmatch" = 1;
          "kwinrulesrc"."e068d076-63ff-4714-851b-ed9f95c1f2d4"."Description" = "Konsole Blur";
          "kwinrulesrc"."e068d076-63ff-4714-851b-ed9f95c1f2d4"."opacityactive" = 90;
          "kwinrulesrc"."e068d076-63ff-4714-851b-ed9f95c1f2d4"."opacityactiverule" = 2;
          "kwinrulesrc"."e068d076-63ff-4714-851b-ed9f95c1f2d4"."wmclass" = "org.kde.konsole";
          "kwinrulesrc"."e068d076-63ff-4714-851b-ed9f95c1f2d4"."wmclassmatch" = 1;
          "kwinrulesrc"."e95ec1aa-5f55-42db-9408-1be622a641b6"."Description" = "Vesktop Blur";
          "kwinrulesrc"."e95ec1aa-5f55-42db-9408-1be622a641b6"."opacityactive" = 97;
          "kwinrulesrc"."e95ec1aa-5f55-42db-9408-1be622a641b6"."opacityactiverule" = 2;
          "kwinrulesrc"."e95ec1aa-5f55-42db-9408-1be622a641b6"."wmclass" = "vesktop";
          "kwinrulesrc"."e95ec1aa-5f55-42db-9408-1be622a641b6"."wmclassmatch" = 2;
          "kwinrulesrc"."2c925338-d6f8-4e6a-916f-6fe5526b22ed"."Description" = "Antigravity Blur";
          "kwinrulesrc"."2c925338-d6f8-4e6a-916f-6fe5526b22ed"."opacityactive" = 97;
          "kwinrulesrc"."2c925338-d6f8-4e6a-916f-6fe5526b22ed"."opacityactiverule" = 2;
          "kwinrulesrc"."2c925338-d6f8-4e6a-916f-6fe5526b22ed"."wmclass" = "antigravity";
          "kwinrulesrc"."2c925338-d6f8-4e6a-916f-6fe5526b22ed"."wmclassmatch" = 1;

          "plasma-localerc"."Formats"."LANG" = "pl_PL.UTF-8";

          # Mouse and Touchpad
          "kcminputrc"."Keyboard"."NumLock" = 0;
          "kcminputrc"."Libinput/1133/16543/Logitech G502 X LS"."PointerAccelerationProfile" = 1;
          "kcminputrc"."Libinput/1133/16543/Logitech G502 X LS"."ScrollFactor" = 5;
          "kcminputrc"."Libinput/1133/16543/Logitech Wireless Mouse PID:409f Mouse"."PointerAccelerationProfile" =
            1;
          "kcminputrc"."Libinput/1133/49304/Logitech G502 X LIGHTSPEED"."PointerAccelerationProfile" = 1;
          "kcminputrc"."Libinput/1133/50503/Logitech USB Receiver"."PointerAccelerationProfile" = 1;
          "kcminputrc"."Libinput/1133/50504/Logitech USB Receiver Mouse"."PointerAccelerationProfile" = 1;
          "kcminputrc"."Libinput/1133/50504/Logitech USB Receiver Mouse"."ScrollFactor" = 3;
          "kcminputrc"."Libinput/1267/12938/DELL0C4C:00 04F3:328A Mouse"."NaturalScroll" = false;
          "kcminputrc"."Libinput/1267/12938/DELL0C4C:00 04F3:328A Touchpad"."ClickMethod" = 2;
          "kcminputrc"."Libinput/1267/12938/DELL0C4C:00 04F3:328A Touchpad"."Enabled" = true;
          "kcminputrc"."Libinput/1267/12938/DELL0C4C:00 04F3:328A Touchpad"."NaturalScroll" = true;
          "kcminputrc"."Libinput/5426/131/Razer Razer Basilisk X HyperSpeed"."PointerAcceleration" = 0.0;
          "kcminputrc"."Libinput/5426/131/Razer Razer Basilisk X HyperSpeed"."PointerAccelerationProfile" = 1;
          "kcminputrc"."Libinput/5426/180/Razer Razer Naga V2 HyperSpeed"."PointerAccelerationProfile" = 1;
          "kcminputrc"."Libinput/5426/185/Razer Razer Basilisk V3 X HyperSpeed"."PointerAccelerationProfile" =
            1;
          "kcminputrc"."Mouse"."cursorTheme" = "Bibata-Modern-Classic";

        };
      };
    };
}
