{ inputs, system }:
final: prev: {
  # gamescope = inputs.chaotic.packages.${system}.gamescope_git;

  zen-browser = inputs.zen-browser.packages.${system}.default;

  vintagestory = prev.callPackage ./custom-pkgs/vintagestory { };

  scopebuddy = prev.stdenv.mkDerivation {
    pname = "scopebuddy";
    version = "1.1.1";

    src = inputs.scopebuddy;

    nativeBuildInputs = with prev; [ makeWrapper ];

    buildInputs = with prev; [
      bash
      gamescope
      perl
      jq
    ];

    installPhase = ''
      mkdir -p $out/bin
      cp bin/scopebuddy $out/bin/scopebuddy
      chmod +x $out/bin/scopebuddy
      ln -s $out/bin/scopebuddy $out/bin/scb
      wrapProgram $out/bin/scopebuddy \
        --prefix PATH : ${
          prev.lib.makeBinPath [
            prev.bash
            prev.gamescope
            prev.perl
            prev.jq
          ]
        } \
        --set SCB_AUTO_RES "1" \
        --set SCB_AUTO_HDR "1" \
        --set SCB_AUTO_VRR "1"
    '';

    meta = {
      description = "A manager script to make gamescope easier to use on desktop";
      homepage = "https://github.com/HikariKnight/ScopeBuddy";
      license = prev.lib.licenses.asl20;
    };
  };

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
