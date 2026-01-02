{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
{
  environment.systemPackages = with pkgs; [
    # Gaming tools and utilities
    vkbasalt
    limo
    scopebuddy
    protonplus
    lsfg-vk
    lsfg-vk-ui
    mangohud
    goverlay

    # Custom tools
    gperftools

    (pkgs.writeShellScriptBin "tcmalloc-run" ''
      # Zabezpieczenie: Jeśli LD_PRELOAD jest puste, nie dodajemy dwukropka na końcu
      if [ -z "$LD_PRELOAD" ]; then
        export LD_PRELOAD="${pkgs.gperftools}/lib/libtcmalloc.so.4"
      else
        # Tutaj kluczowa zmiana: dopisujemy tcmalloc NA POCZĄTEK listy.
        # Dzięki temu tcmalloc ma pierwszeństwo w nadpisywaniu symboli malloc/free,
        # a biblioteki Steam Overlay (będące dalej w łańcuchu) nadal się załadują.
        export LD_PRELOAD="${pkgs.gperftools}/lib/libtcmalloc.so.4:$LD_PRELOAD"
      fi

      # Wymuszenie dedykowanej grafiki (RX 7900M)
      export DRI_PRIME=1

      # Uruchomienie gry (ananicy automatycznie wykryje ten proces po exec)
      exec "$@"
    '')
  ];
}
