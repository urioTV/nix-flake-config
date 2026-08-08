# Profil agregujący — ładuje wszystkie klocki z profili narzędziowych.
# Destrukturyzuj klocki z argumentów perSystem (oddawane przez _module.args
# w poszczególnych modułach <tool>.nix).

{ ... }:
{
  perSystem =
    {
      toolADev,
      toolBDev,
      toolsDev,
      ...
    }:
    let
      motd = profile: ''
        {202}<PROJECT> devshell{reset}
        Profil: ${profile}
        Project root: $PRJ_ROOT

        $(type -p menu &>/dev/null && menu)
      '';
    in
    {
      devshells.default = {
        devshell.name = "<project>";
        devshell.motd = motd "default = toolA + toolB + tools";

        # Składaj addytywnie. env to lista — łącz `++`.
        env = toolADev.toolAEnv ++ toolBDev.toolBEnv;
        packages =
          toolADev.toolAPackages
          ++ toolBDev.toolBPackages
          ++ toolsDev.toolsPackages;
        commands =
          toolADev.toolACommands
          ++ toolBDev.toolBCommands
          ++ toolsDev.toolsCommands;

        # Każdy startup-hook z osobnym id (klucz devshell.startup.<id>).
        devshell.startup.load-toolA-env.text = toolADev.toolAStartup;
        devshell.startup.load-toolB-env.text = toolBDev.toolBStartup;
        devshell.startup.load-tools-env.text = toolsDev.toolsStartup;
      };
    };
}
