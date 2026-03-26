{ self, ... }:
let
  sharedVars =
    { lib, ... }:
    with lib;
    {
      options.vars = {
        wallpaper = mkOption {
          type = types.str;
          default = "${self}/media/kosciejo.png";
          description = "My wallpaper path";
        };
        base16Scheme = mkOption {
          type = types.str;
          default = "${self}/media/base16Schemes/mocha.yaml";
          description = "My base16 scheme path";
        };
      };
    };
in
{
  flake.nixosModules.vars = sharedVars;
  flake.homeModules.vars = sharedVars;
}
