{
  lib,
  stdenv,
  fetchzip,
}:

stdenv.mkDerivation {
  pname = "lsfg-vk";
  version = "latest";

  src = fetchzip {
    url = "https://pancake.gay/lsfg-vk/lsfg-vk.zip";
    hash = "sha256-IQMfkrwBN/qLazm43BHnPOo7kk8bG/TP1rWLi7x22Y0=";
    stripRoot = false;
  };

  installPhase = ''
    mkdir -p $out/lib $out/share/vulkan/implicit_layer.d
    cp $src/lib/liblsfg-vk.so $out/lib/
    cp $src/share/vulkan/implicit_layer.d/VkLayer_LS_frame_generation.json $out/share/vulkan/implicit_layer.d/
  '';

  meta = with lib; {
    description = "A Vulkan layer for frame generation";
    homepage = "https://github.com/pancake-org/lsfg-vk";
    license = licenses.mit;
    platforms = platforms.linux;
    sourceProvenance = with sourceTypes; [ binaryNativeCode ];
  };
}
