{
  final,
  prev,
  inputs',
}:
{
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
