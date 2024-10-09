{
  lib,
  stdenv,
  fetchFromGitHub,
  fetchpatch,
  alsa-lib,
  boost184,
  cmake,
  cryptopp,
  glslang,
  ffmpeg,
  fmt,
  jack2,
  libdecor,
  libpulseaudio,
  libunwind,
  libusb1,
  magic-enum,
  mesa,
  pkg-config,
  pugixml,
  qt6,
  renderdoc,
  sndio,
  toml11,
  vulkan-headers,
  vulkan-loader,
  vulkan-memory-allocator,
  xorg,
  xxHash,
  zlib-ng,
}:

stdenv.mkDerivation {
  pname = "shadps4";
  version = "0.3.1-unstable-2024-10-08";

  src = fetchFromGitHub {
    owner = "shadps4-emu";
    repo = "shadPS4";
    rev = "aba803bd04575c2016d15b8edeaef01856ad1724";
    hash = "sha256-2DrmBDbzmv01bupIHPhKcHvPq8GaFuYgU3eA+3LPCKE=";
    fetchSubmodules = true;
  };

  patches = [
    # https://github.com/shadps4-emu/shadPS4/issues/758
    ./bloodborne.patch
    # Fix controls without a numpad
    ./laptop-controls.patch
  ];

  buildInputs = [
    alsa-lib
    boost184
    cryptopp
    glslang
    ffmpeg
    fmt
    jack2
    libdecor
    libpulseaudio
    libunwind
    libusb1
    xorg.libX11
    xorg.libXext
    magic-enum
    mesa
    pugixml
    qt6.qtbase
    qt6.qtdeclarative
    qt6.qtmultimedia
    qt6.qttools
    qt6.qtwayland
    renderdoc
    sndio
    toml11
    vulkan-headers
    vulkan-loader
    vulkan-memory-allocator
    xxHash
    zlib-ng
  ];

  nativeBuildInputs = [
    cmake
    pkg-config
    qt6.wrapQtAppsHook
  ];

  postPatch = ''
    substituteInPlace src/common/path_util.cpp \
      --replace-fail 'const auto user_dir = std::filesystem::current_path() / PORTABLE_DIR;' \
      'const auto user_dir = std::filesystem::path(getenv("HOME")) / ".config" / "shadPS4";'
  '';

  cmakeFlags = [
    (lib.cmakeBool "ENABLE_QT_GUI" true)
  ];

  # Still in development, help with debugging
  cmakeBuildType = "RelWithDebugInfo";
  dontStrip = true;

  installPhase = ''
    runHook preInstall

    install -D -t $out/bin shadps4
    install -Dm644 -t $out/share/icons/hicolor/512x512/apps $src/.github/shadps4.png
    install -Dm644 -t $out/share/applications $src/.github/shadps4.desktop

    runHook postInstall
  '';

  fixupPhase = ''
    patchelf --add-rpath ${
      lib.makeLibraryPath [
        vulkan-loader
        xorg.libXi
      ]
    } \
      $out/bin/shadps4
  '';

  meta = {
    description = "Early in development PS4 emulator";
    homepage = "https://github.com/shadps4-emu/shadPS4";
    license = lib.licenses.gpl2Only;
    maintainers = with lib.maintainers; [ ryand56 ];
    mainProgram = "shadps4";
    platforms = lib.intersectLists lib.platforms.linux lib.platforms.x86_64;
  };
}