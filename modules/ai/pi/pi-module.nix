{ inputs, ... }:
{
  flake.homeModules.ai-pi =
    {
      config,
      pkgs,
      inputs',
      lib,
      self,
      ...
    }:
    {
      imports = [ ./_pi.nix ];
    };
}