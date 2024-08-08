{lib, ...}:
with lib;
{
  options.vars = {
    wallpaper = mkOption {
      type = types.str;
      default = "${./kosciejo.png}";
      description = "My wallpaper path";
    };
    base16Scheme = mkOption {
      type = types.str;
      default = "${./base16Schemes/mocha.yaml}";
      description = "My base16 scheme path";
    };
  };
}