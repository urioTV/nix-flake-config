# Wzorzec pojedynczego profilu narzędziowego.
# Kopiuj jako nix/devshells/<tool>.nix i podmień:
#   - "toolA" -> realna nazwa (ansible, pulumi, node, rust, terraform, ...)
#   - toolAPackages -> pakiety z `with pkgs;`
#   - toolACommands -> komendy { name, category, help, command }
#   - toolAStartup -> skrypt basha (idempotentny!), ładowany jako devshell.startup
#   - toolAEnv -> [{ name, value } | { name, eval }]
#
# Moduł wystawia Dwie rzeczy:
#   1. _module.args.toolADev — klocki do reuse'u przez default.nix / ci.nix
#   2. devshells.toolA     — kompletny profil do `nix develop .#toolA`

{ ... }:
{
  perSystem =
    { pkgs, loadSecrets, ... }:
    let
      toolAPackages = with pkgs; [
        # Narzędzia runtime profilu. Linux-only chroń przez
        # pkgs.lib.optionals pkgs.stdenv.hostPlatform.isLinux [ ... ]
        git
        jq
        yq-go
        curl
        # <tool-cli>
      ];

      # Pakiet niestandardowy (własny wrapper / patched CLI) definiuj tu,
      # w `let`, jak pulumiCli w pulumi.nix:
      #   toolCli = pkgs.stdenv.mkDerivation { ... };
      # i wystaw przez toolADev.toolCli, jeśli ci.nix musi go użyć.

      toolAStartup = ''
        ${loadSecrets}

        if [ -z "''${TOOLA_DEVSHELL_INITIALIZED:-}" ]; then
          TOOLA_DEVSHELL_INITIALIZED=1

          # Idempotentna inicjalizacja profilu:
          # - materiaizacja sekretów w runtime (klucze, tokeny) do $XDG_RUNTIME_DIR
          #   z fallbackiem /tmp, chmod 700/600
          # - fail-closed: brak sekretu => ostrzeżenie + fałszywa wartość,
          #   nigdy ciche dziedziczenie ~/.ssh czy ssh-agent
          # - hooki plikowe: if [ -f "$PRJ_ROOT/<path>" ]; then ...
          :
        fi
      '';

      toolACommands = [
        {
          name = "toolA-<akcja>";
          category = "toolA";
          help = "Run toolA <akcja> from <dir>/";
          command = "cd <dir> && toolA <akcja>";
        }
        # Komenda przyjmująca argumenty użytkownika:
        # {
        #   name = "toolA-check";
        #   category = "toolA";
        #   help = "Run toolA check with arguments";
        #   command = "toolA check \"$@\"";
        # }
      ];

      toolAEnv = [
        {
          name = "TOOL_A_PAGER";
          value = "";
        }
        # Ścieżka zależna od runtime -> eval:
        # {
        #   name = "TOOL_A_CONFIG";
        #   eval = "$PRJ_ROOT/config/toolA.toml";
        # }
      ];

      motd = profile: ''
        {202}<PROJECT> devshell{reset}
        Profil: ${profile}
        Project root: $PRJ_ROOT

        $(type -p menu &>/dev/null && menu)
      '';

      toolADev = {
        inherit
          toolAPackages
          toolACommands
          toolAStartup
          toolAEnv
          ;
      };
    in
    {
      _module.args = { inherit toolADev; };

      devshells.toolA = {
        devshell.name = "<project>-toolA";
        devshell.motd = motd "toolA";
        env = toolAEnv;
        packages = toolAPackages;
        commands = toolACommands;
        devshell.startup.load-toolA-env.text = toolAStartup;
      };
    };
}
