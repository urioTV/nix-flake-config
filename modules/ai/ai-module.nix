{ inputs, ... }:
{
  flake.homeModules.ai =
    {
      config,
      pkgs,
      inputs',
      lib,
      self,
      ...
    }:
    {
      imports = [
        ./_ai.nix
        ./_claude-code.nix
        ./_forge.nix
        self.homeModules.ai-opencode
      ];
    };
}
