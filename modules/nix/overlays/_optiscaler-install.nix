{
  final,
  prev,
  inputs',
}:
{
  # Downloads OptiScaler nightly build and runs official setup script
  optiscaler-install = final.writeShellScriptBin "optiscaler-install" ''
    set -e
    TMP=$(mktemp -d)
    trap "rm -rf $TMP" EXIT

    echo "Fetching latest OptiScaler nightly build..."
    # Get the latest master-* nightly release (bleeding edge builds)
    JSON=$(${final.curl}/bin/curl -sL "https://api.github.com/repos/xXJSONDeruloXx/OptiScaler-Bleeding-Edge/releases?per_page=50")

    # Find the most recent master-* release with OptiScaler asset
    LATEST=$(${final.jq}/bin/jq -r '[.[] | select(.tag_name | startswith("master-"))] | sort_by(.published_at) | reverse | .[0]' <<< "$JSON")

    if [ -z "$LATEST" ] || [ "$LATEST" = "null" ]; then
      echo "No nightly build found. Falling back to stable release..."
      JSON=$(${final.curl}/bin/curl -sL "https://api.github.com/repos/xXJSONDeruloXx/OptiScaler-Bleeding-Edge/releases/latest")
      TAG=$(echo "$JSON" | ${final.jq}/bin/jq -r '.tag_name')
      DATE=$(echo "$JSON" | ${final.jq}/bin/jq -r '.published_at')
      echo "Found: $TAG (published: $DATE)"
      OPTI_URL=$(echo "$JSON" | ${final.jq}/bin/jq -r '.assets[] | select(.name | test("OptiScaler.*\\.7z$"; "i")) | .browser_download_url' | head -1)
    else
      TAG=$(echo "$LATEST" | ${final.jq}/bin/jq -r '.tag_name')
      DATE=$(echo "$LATEST" | ${final.jq}/bin/jq -r '.published_at')
      echo "Found: $TAG (published: $DATE)"
      OPTI_URL=$(echo "$LATEST" | ${final.jq}/bin/jq -r '.assets[] | select(.name | test("OptiScaler.*\\.7z$"; "i")) | .browser_download_url' | head -1)
    fi

    if [ -z "$OPTI_URL" ]; then
      echo "Error: Could not find OptiScaler download URL"
      exit 1
    fi

    echo "Downloading OptiScaler..."
    ${final.curl}/bin/curl -sL "$OPTI_URL" -o "$TMP/opti.7z"
    ${final.p7zip}/bin/7z x "$TMP/opti.7z" -o"$TMP" -y >/dev/null

    cp -r "$TMP/"* . 2>/dev/null || true
    chmod +x ./setup_linux.sh 2>/dev/null || true

    echo ""
    echo "Running official setup script..."
    exec ./setup_linux.sh "$@"
  '';
}
