{ inputs, system }:
final: prev: {
  gamescope = inputs.chaotic.packages.${system}.gamescope_git;

  opencomposite = prev.opencomposite.overrideAttrs (prevAttrs: {
    version = "git-2025-01-11";

    src = prev.fetchFromGitLab {
      owner = "znixian";
      repo = "OpenOVR";
      rev = "5c1439711084a1dfb5b9c5c2d87271685e84be0d";
      fetchSubmodules = true;
      hash = "sha256-WxSPmLAi8mdfj3NZDQK0MNUP861Y/D/T+NvAJe+LNYU=";
    };
  });

}
