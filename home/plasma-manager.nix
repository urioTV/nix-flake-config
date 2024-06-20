{ config, lib, pkgs, ... }: {

  home.packages = with pkgs; [
    catppuccin-qt5ct
  ];

  programs.plasma = {
    enable = true;

    workspace = {
      colorScheme = "CatppuccinMocha";
      cursor.theme = "Bibata-Modern-Classic";
      iconTheme = "Papirus";
      wallpaper = "${../tech-driad.png}";
    };
    fonts = {
      general = {
        family = "Hack Nerd Font";
        pointSize = 12;
      };
      fixedWidth = {
        family = "Hack Nerd Font";
        pointSize = 12;
      };
      small = {
        family = "Hack Nerd Font";
        pointSize = 10;
      };
      toolbar = {
        family = "Hack Nerd Font";
        pointSize = 10;
      };
      menu = {
        family = "Hack Nerd Font";
        pointSize = 10;
      };
      windowTitle = {
        family = "Hack Nerd Font";
        pointSize = 10;
      };
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
      "kwin"."Window Close" = [ "Meta+Q" "Alt+F4" ];
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
      "services/org.kde.konsole.desktop"."_launch" = [ "Meta+E" "Ctrl+Alt+T" ];
      "services/org.kde.spectacle.desktop"."ActiveWindowScreenShot" = [ ];
      "services/org.kde.spectacle.desktop"."FullScreenScreenShot" =
        "Meta+Shift+S";
      "services/org.kde.spectacle.desktop"."RectangularRegionScreenShot" =
        "Meta+S";
      "services/org.kde.spectacle.desktop"."WindowUnderCursorScreenShot" =
        "Meta+Alt+S";
      "services/org.kde.spectacle.desktop"."_launch" = "Print";
    };
    configFile = {
      "kwinrc"."Plugins"."blurEnabled" = false;
      "kwinrc"."Plugins"."forceblurEnabled" = true;
      "kwinrc"."TabBox"."DesktopMode" = 0;
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
      "kwinrulesrc"."2953631e-40b3-43e6-9b40-5733a200e59a"."Description" =
        "Spotify Blur";
      "kwinrulesrc"."2953631e-40b3-43e6-9b40-5733a200e59a"."opacityactive" = 95;
      "kwinrulesrc"."2953631e-40b3-43e6-9b40-5733a200e59a"."opacityactiverule" =
        2;
      "kwinrulesrc"."2953631e-40b3-43e6-9b40-5733a200e59a"."wmclass" =
        "Spotify";
      "kwinrulesrc"."2953631e-40b3-43e6-9b40-5733a200e59a"."wmclassmatch" = 2;
      "kwinrulesrc"."3"."Description" = "Code Blur";
      "kwinrulesrc"."3"."opacityactive" = 97;
      "kwinrulesrc"."3"."opacityactiverule" = 2;
      "kwinrulesrc"."3"."wmclass" = "code-url-handler";
      "kwinrulesrc"."3"."wmclassmatch" = 1;
      "kwinrulesrc"."3fd545be-e262-456e-b6dd-90e0fcbf71c3"."Description" =
        "Dolphin Blur";
      "kwinrulesrc"."3fd545be-e262-456e-b6dd-90e0fcbf71c3"."opacityactive" = 90;
      "kwinrulesrc"."3fd545be-e262-456e-b6dd-90e0fcbf71c3"."opacityactiverule" =
        2;
      "kwinrulesrc"."3fd545be-e262-456e-b6dd-90e0fcbf71c3"."wmclass" =
        "org.kde.dolphin";
      "kwinrulesrc"."3fd545be-e262-456e-b6dd-90e0fcbf71c3"."wmclassmatch" = 1;
      "kwinrulesrc"."4"."Description" = "Vesktop Blur";
      "kwinrulesrc"."4"."opacityactive" = 97;
      "kwinrulesrc"."4"."opacityactiverule" = 2;
      "kwinrulesrc"."4"."wmclass" = "vesktop";
      "kwinrulesrc"."4"."wmclassmatch" = 2;
      "kwinrulesrc"."5"."Description" = "Spotify Blur";
      "kwinrulesrc"."5"."opacityactive" = 95;
      "kwinrulesrc"."5"."opacityactiverule" = 2;
      "kwinrulesrc"."5"."wmclass" = "Spotify";
      "kwinrulesrc"."5"."wmclassmatch" = 2;
      "kwinrulesrc"."9ef289a6-6fc5-42f3-8258-21b32fcb15be"."Description" =
        "Code Blur";
      "kwinrulesrc"."9ef289a6-6fc5-42f3-8258-21b32fcb15be"."opacityactive" = 97;
      "kwinrulesrc"."9ef289a6-6fc5-42f3-8258-21b32fcb15be"."opacityactiverule" =
        2;
      "kwinrulesrc"."9ef289a6-6fc5-42f3-8258-21b32fcb15be"."wmclass" =
        "code-url-handler";
      "kwinrulesrc"."9ef289a6-6fc5-42f3-8258-21b32fcb15be"."wmclassmatch" = 1;
      "kwinrulesrc"."General"."count" = 5;
      "kwinrulesrc"."General"."rules" = "1,2,3,4,5";
      "kwinrulesrc"."e068d076-63ff-4714-851b-ed9f95c1f2d4"."Description" =
        "Konsole Blur";
      "kwinrulesrc"."e068d076-63ff-4714-851b-ed9f95c1f2d4"."opacityactive" = 90;
      "kwinrulesrc"."e068d076-63ff-4714-851b-ed9f95c1f2d4"."opacityactiverule" =
        2;
      "kwinrulesrc"."e068d076-63ff-4714-851b-ed9f95c1f2d4"."wmclass" =
        "org.kde.konsole";
      "kwinrulesrc"."e068d076-63ff-4714-851b-ed9f95c1f2d4"."wmclassmatch" = 1;
      "kwinrulesrc"."e95ec1aa-5f55-42db-9408-1be622a641b6"."Description" =
        "Vesktop Blur";
      "kwinrulesrc"."e95ec1aa-5f55-42db-9408-1be622a641b6"."opacityactive" = 97;
      "kwinrulesrc"."e95ec1aa-5f55-42db-9408-1be622a641b6"."opacityactiverule" =
        2;
      "kwinrulesrc"."e95ec1aa-5f55-42db-9408-1be622a641b6"."wmclass" =
        "vesktop";
      "kwinrulesrc"."e95ec1aa-5f55-42db-9408-1be622a641b6"."wmclassmatch" = 2;
      "plasma-localerc"."Formats"."LANG" = "pl_PL.UTF-8";
    };
  };
}
