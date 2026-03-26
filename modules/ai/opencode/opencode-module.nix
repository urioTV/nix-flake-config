{ inputs, ... }:
{
  flake.homeModules.ai-opencode =
    {
      config,
      pkgs,
      inputs',
      lib,
      self,
      ...
    }:
    {
      imports = [ ./_opencode.nix ];
    };
}
