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
        self.homeModules.ai-pi
      ];
    };
}
