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

  # Keep the browser CLI aligned with pi-agent-browser-native's exact
  # upstream target. llm-agents.nix provides the current cached build.
  agent-browser = inputs'.llm-agents.packages.agent-browser;

  # openldap has flaky tests on i686 (test008-concurrency, test017-syncreplication-refresh, etc.)
  # Disable checks for 32-bit only — steam/lutris depend on pkgsi686Linux.openldap
  # See: https://github.com/NixOS/nixpkgs/issues/513245
  openldap = prev.openldap.overrideAttrs {
    doCheck = !prev.stdenv.hostPlatform.isi686;
  };
}
