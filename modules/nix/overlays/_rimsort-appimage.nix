{
  final,
  prev,
  inputs',
}:
let
  version = "1.1.2";

  src = final.fetchurl {
    url = "https://github.com/RimSort/RimSort/releases/download/v${version}/RimSort-v${version}-x86_64.AppImage";
    hash = "sha256-+S6lzmJ9Elck84fIrANOva66XPXz1p9hGP0nEcbS/mU=";
  };

  appimageContents = prev.appimageTools.extractType2 {
    pname = "rimsort";
    inherit version src;
  };
in
{
  rimsort = prev.appimageTools.wrapType2 {
    pname = "rimsort";
    inherit version src;

    extraPkgs =
      pkgs: with pkgs; [
        zstd
        glib
        icu
        fontconfig
        freetype
        libglvnd
        libxkbcommon
        xorg.libX11
        xorg.libXext
        xorg.libXrandr
        xorg.libXfixes
        xorg.libXcomposite
        xorg.libXdamage
        xorg.libXtst
        xorg.libxcb
        xorg.xcbutilcursor
        xorg.xcbutilimage
        xorg.xcbutilkeysyms
        xorg.xcbutilrenderutil
        xorg.xcbutilwm
        alsa-lib
        dbus
        brotli
        libkrb5
        nspr
        nss
        systemd
        wayland
        mesa
        libxkbfile
        libdrm
        expat
      ];

    extraInstallCommands = ''
      install -Dm 444 ${appimageContents}/io.github.rimsort.RimSort.desktop -t $out/share/applications
      # wrapType2 creates the binary as lowercase pname, but desktop file uses 'RimSort'
      substituteInPlace $out/share/applications/io.github.rimsort.RimSort.desktop \
        --replace-fail 'Exec=RimSort' 'Exec=rimsort'
      cp -r ${appimageContents}/usr/share/icons $out/share
    '';

    meta = with final.lib; {
      description = "Open source mod manager for the video game RimWorld";
      homepage = "https://github.com/RimSort/RimSort";
      license = licenses.gpl3Only;
      mainProgram = "rimsort";
      platforms = [ "x86_64-linux" ];
      maintainers = with maintainers; [ ];
    };
  };
}
