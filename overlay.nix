{ inputs' }:
final: prev: {
  # gamescope = inputs.chaotic.packages.${system}.gamescope_git;

  zen-browser = inputs'.zen-browser.packages.default;

  # zed-editor = inputs.zed.packages.${system}.default;

  openmw-dev = inputs'.openmw-nix.packages.openmw-dev.overrideAttrs (oldAttrs: {
    nativeBuildInputs = (oldAttrs.nativeBuildInputs or [ ]) ++ [ final.makeWrapper ];

    postFixup = (oldAttrs.postFixup or "") + ''
      echo "Applying mesa_glthread=true to all executables"
      for bin in $out/bin/*; do
        if [ -f "$bin" ] && [ -x "$bin" ]; then
          wrapProgram "$bin" \
            --set mesa_glthread true
        fi
      done
    '';
  });

  antigravity =
    let
      wrapped = final.symlinkJoin {
        name = "antigravity-gpu-wrapped";
        paths = [ prev.antigravity ];
        buildInputs = [ final.makeWrapper ];
        postBuild = ''
          wrapProgram $out/bin/antigravity \
            --set DRI_PRIME "1" \
            --add-flags "--use-gl=desktop" \
            --add-flags "--use-angle=vulkan" \
            --add-flags "--enable-features=Vulkan,DefaultANGLEVulkan,VaapiVideoDecodeLinuxGL"
        '';
      };
    in
    final.symlinkJoin {
      name = "antigravity";
      paths = [ wrapped ];
      postBuild = ''
        ln -s $out/bin/antigravity $out/bin/agy
      '';
    };

  opencode = inputs'.opencode-dev.packages.opencode;
}
