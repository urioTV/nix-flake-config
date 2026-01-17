{ inputs, system }:
final: prev: {
  # gamescope = inputs.chaotic.packages.${system}.gamescope_git;

  zen-browser = inputs.zen-browser.packages.${system}.default;

  # zed-editor = inputs.zed.packages.${system}.default;

  openmw-dev = inputs.openmw-nix.packages.${system}.openmw-dev.overrideAttrs (oldAttrs: {
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

  wowup-cf = prev.symlinkJoin {
    name = "wowup-cf-no-gpu";
    paths = [ prev.wowup-cf ];
    nativeBuildInputs = [ final.makeWrapper ];
    postBuild = ''
      # Usuwamy domyślny symlink do oryginalnej binarki
      rm $out/bin/wowup-cf

      # Tworzymy nowy wrapper, który wywołuje oryginał z flagą wyłączającą GPU
      makeWrapper ${prev.wowup-cf}/bin/wowup-cf $out/bin/wowup-cf \
        --add-flags "--disable-gpu"
    '';
  };
}
