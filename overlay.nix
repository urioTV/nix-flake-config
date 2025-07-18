{ inputs, system }:
final: prev: {
  gamescope = inputs.chaotic.packages.${system}.gamescope_git;

  zen-browser = inputs.zen-browser.packages.${system}.default;

  openmw-dev = inputs.openmw-nix.packages.${system}.openmw-dev.overrideAttrs (oldAttrs: {
    nativeBuildInputs = (oldAttrs.nativeBuildInputs or [ ]) ++ [ final.makeWrapper ];

    postFixup =
      (oldAttrs.postFixup or "")
      + ''
        echo "Applying mesa_glthread=true to all executables"
        for bin in $out/bin/*; do
          if [ -f "$bin" ] && [ -x "$bin" ]; then
            wrapProgram "$bin" \
              --set mesa_glthread true
          fi
        done
      '';
  });

  # opencomposite = prev.opencomposite.overrideAttrs (prevAttrs: {
  #   version = "git-2025-01-11";

  #   src = prev.fetchFromGitLab {
  #     owner = "znixian";
  #     repo = "OpenOVR";
  #     rev = "5c1439711084a1dfb5b9c5c2d87271685e84be0d";
  #     fetchSubmodules = true;
  #     hash = "sha256-WxSPmLAi8mdfj3NZDQK0MNUP861Y/D/T+NvAJe+LNYU=";
  #   };
  # });

  # xrizer = prev.xrizer.overrideAttrs (prevAttrs: {
  #   version = "git-2025-01-11";

  #   src = prev.fetchFromGitHub {
  #     owner = "Supreeeme";
  #     repo = "xrizer";
  #     rev = "1babbac76a275749ee4c93a57f64431bd5d71e6f";
  #     hash = "sha256-KDRih95IcYDDOd6QMxqZI33TaCWI3/xOfzczlS1SyVI=";
  #   };
  # });

  # alvr = inputs.nixpkgs-alvr.legacyPackages.${system}.alvr;
}
