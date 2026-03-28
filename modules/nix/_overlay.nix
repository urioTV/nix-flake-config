{ inputs' }:
final: prev: {

  zen-browser = inputs'.zen-browser.packages.default;

  gamescope = prev.gamescope.overrideAttrs (_: {
    NIX_CFLAGS_COMPILE = [ "-fno-fast-math" ];
  });

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

  # Downloads OptiScaler + FSR4 and runs official setup script
  optiscaler-install = final.writeShellScriptBin "optiscaler-install" ''
    set -e
    TMP=$(mktemp -d)
    trap "rm -rf $TMP" EXIT

    echo "Fetching latest OptiScaler release..."
    JSON=$(${final.curl}/bin/curl -sL "https://api.github.com/repos/xXJSONDeruloXx/OptiScaler-Bleeding-Edge/releases/latest")

    OPTI_URL=$(echo "$JSON" | ${final.jq}/bin/jq -r '.assets[] | select(.name | test("Optiscaler.*\\.7z$")) | .browser_download_url' | head -1)
    FSR4_URL=$(echo "$JSON" | ${final.jq}/bin/jq -r '.assets[] | select(.name | test("FSR4.*\\.7z$")) | .browser_download_url' | head -1)

    echo "Downloading OptiScaler..."
    ${final.curl}/bin/curl -sL "$OPTI_URL" -o "$TMP/opti.7z"
    ${final.p7zip}/bin/7z x "$TMP/opti.7z" -o"$TMP" -y >/dev/null

    [ -n "$FSR4_URL" ] && { echo "Downloading FSR4 INT8..."; ${final.curl}/bin/curl -sL "$FSR4_URL" -o "$TMP/fsr4.7z"; ${final.p7zip}/bin/7z x "$TMP/fsr4.7z" -o"$TMP" -y >/dev/null; }

    cp -r "$TMP/"* . 2>/dev/null || true
    chmod +x ./setup_linux.sh 2>/dev/null || true

    echo ""
    echo "Running official setup script..."
    exec ./setup_linux.sh "$@"
  '';

  # Downloads OptiPatcher ASI plugin
  optipatcher-install = final.writeShellScriptBin "optipatcher-install" ''
    set -e

    echo "Downloading latest OptiPatcher..."
    URL=$(${final.curl}/bin/curl -sL "https://api.github.com/repos/optiscaler/OptiPatcher/releases/latest" | ${final.jq}/bin/jq -r '.assets[0].browser_download_url')

    mkdir -p plugins
    ${final.curl}/bin/curl -sL "$URL" -o plugins/OptiPatcher.asi

    # Enable ASI plugins in OptiScaler.ini if exists
    if [ -f "OptiScaler.ini" ]; then
      sed -i 's/LoadAsiPlugins=false/LoadAsiPlugins=true/' OptiScaler.ini 2>/dev/null || true
      sed -i 's/LoadAsiPlugins=auto/LoadAsiPlugins=true/' OptiScaler.ini 2>/dev/null || true
      grep -q "LoadAsiPlugins" OptiScaler.ini || echo -e "\n[Plugins]\nLoadAsiPlugins=true" >> OptiScaler.ini
    fi

    echo ""
    echo "Done! OptiPatcher.asi installed to plugins/"
    echo "Supported games: https://github.com/optiscaler/OptiPatcher/blob/main/GameSupport.md"
  '';
}
