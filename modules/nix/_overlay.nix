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

  # openldap has flaky tests on i686 (test008-concurrency, test017-syncreplication-refresh, etc.)
  # Disable checks for 32-bit only — steam/lutris depend on pkgsi686Linux.openldap
  # See: https://github.com/NixOS/nixpkgs/issues/513245
  openldap = prev.openldap.overrideAttrs {
    doCheck = !prev.stdenv.hostPlatform.isi686;
  };
}
