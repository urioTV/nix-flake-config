{ inputs' }:
final: prev:
let
  load = path: import path { inherit final prev inputs'; };
in
load ./overlays/_openmw-dev.nix
// {

  zen-browser = (inputs'.zen-browser.packages.default);

  gamescope = prev.gamescope.overrideAttrs (_: {
    NIX_CFLAGS_COMPILE = [ "-fno-fast-math" ];
  });

  # Shared Engram derivation from modules/ai/_engram.nix.
  engram = (
    import ./../ai/_engram.nix {
      pkgs = final;
      lib = final.lib;
    }
  );

  # CodeGraph (colbymchenry/codegraph) — prebuilt bundle, patchelf'd. See
  # modules/ai/_codegraph.nix.
  codegraph = (
    import ./../ai/_codegraph.nix {
      pkgs = final;
      lib = final.lib;
    }
  );

  # openldap has flaky tests on i686 (test008-concurrency, test017-syncreplication-refresh, etc.)
  # Disable checks for 32-bit only — steam/lutris depend on pkgsi686Linux.openldap
  # See: https://github.com/NixOS/nixpkgs/issues/513245
  openldap = prev.openldap.overrideAttrs {
    doCheck = !prev.stdenv.hostPlatform.isi686;
  };
}
