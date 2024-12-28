{ lib, ... }:
with lib;
{
  options.vars = {
    wallpaper = mkOption {
      type = types.str;
      default = "${./media/kosciejo.png}";
      description = "My wallpaper path";
    };
    base16Scheme = mkOption {
      type = types.str;
      default = "${./media/base16Schemes/mocha.yaml}";
      description = "My base16 scheme path";
    };
  };
}
