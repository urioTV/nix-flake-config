# home/programs/ai/skills/skills-import.nix
#
# Każdy podfolder w tym katalogu trafia do ~/.config/opencode/skills/<name>/SKILL.md
# i jest dostępny jako skill w opencode.
#
# Aby dodać nowy skill: stwórz folder <nazwa>/SKILL.md obok tego pliku.
# Nic więcej nie trzeba zmieniać.
{ lib, ... }:
let
  skillsDir = ./.;

  # Zbiera wszystkie podfoldery (każdy jest osobnym skillem)
  skillDirs = lib.filterAttrs
    (name: type: type == "directory")
    (builtins.readDir skillsDir);

  # name: "autocommit"  →  key: "opencode/skills/autocommit/SKILL.md"
  toConfigFile = name: _: {
    "opencode/skills/${name}/SKILL.md".source = skillsDir + "/${name}/SKILL.md";
  };

  skillConfigs = lib.mapAttrs toConfigFile skillDirs;
in
{
  xdg.configFile = lib.mkMerge (lib.attrValues skillConfigs);
}
