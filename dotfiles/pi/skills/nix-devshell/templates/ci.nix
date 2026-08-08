# Minimalny podzbiór dla CI/CD.
# Zasada: świadomie mniejszy zestaw pakietów niż `default`, ale TEN SAM env
# i TE SAME startup-hooki, których CI faktycznie potrzebuje. Komentarz w
# module tłumaczy, czego celowo brakuje vs `default` (lintery, generatory,
# pakiety desktopowe typu libreoffice/dejavu_fonts, docker-client itp.).

{ ... }:
{
  perSystem =
    {
      pkgs,
      toolADev,
      toolBDev,
      ...
    }:
    let
      # Minimalny zestaw dla CI — tylko to, czego faktycznie potrzebują joby.
      # Bez linterów, generatorów i narzędzi desktopowych.
      ciPackages = with pkgs; [
        git
        jq
        yq-go
        curl
        # <tool-cli> — często wystarczy sam runtime, bez -lint / -fmt
      ];

      motd = profile: ''
        {202}<PROJECT> devshell{reset}
        Profil: ${profile}
        Project root: $PRJ_ROOT

        $(type -p menu &>/dev/null && menu)
      '';
    in
    {
      devshells.ci = {
        devshell.name = "<project>-ci";
        devshell.motd = motd "ci (toolA + toolB, minimal)";
        env = toolADev.toolAEnv ++ toolBDev.toolBEnv;
        packages = ciPackages;
        # Komendy tylko te, które CI wywołuje (np. toolB preview/up).
        commands = toolBDev.toolBCommands;
        # Startup-hooki: tylko te wymagane w CI. Zazwyczaj te same co default,
        # bo materiaizują sekrety/klucze z CI variables.
        devshell.startup.load-toolA-env.text = toolADev.toolAStartup;
        devshell.startup.load-toolB-env.text = toolBDev.toolBStartup;
      };
    };
}
