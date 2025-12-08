{
  stdenv,
  lib,
  makeWrapper,
  bash,
  gamescope,
  perl,
  jq,
  inputs,
}:

stdenv.mkDerivation {
  pname = "scopebuddy";
  version = "unstable-${inputs.scopebuddy.shortRev or "dirty"}";

  src = inputs.scopebuddy;

  nativeBuildInputs = [ makeWrapper ];

  buildInputs = [
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
        lib.makeBinPath [
          bash
          gamescope
          perl
          jq
        ]
      } \
      --set SCB_AUTO_RES "1" \
      --set SCB_AUTO_HDR "1" \
      --set SCB_AUTO_VRR "1" \
      --add-flags "--force-composition"
  '';

  meta = {
    description = "A manager script to make gamescope easier to use on desktop";
    homepage = "https://github.com/HikariKnight/ScopeBuddy";
    license = lib.licenses.asl20;
  };
}
