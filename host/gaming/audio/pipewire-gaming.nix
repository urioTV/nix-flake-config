{
  config,
  lib,
  pkgs,
  ...
}:
{
  # Gaming-specific PipeWire configuration (moved from configuration.nix)
  services.pipewire.extraConfig = {
    "pipewire-pulse" = {
      "10-warframe-rules" = {
        "pulse.rules" = [
          {
            matches = [
              { "application.process.binary" = "Warframe.x64.exe"; }
              { "application.process.binary" = "Warframe.exe"; }
              { "application.name" = "~.*[Ww]arframe.*"; }
            ];
            actions = {
              update-props = {
                "pulse.min.req" = "1024/48000";
                "pulse.min.frag" = "1024/48000";
                "pulse.min.quantum" = "1024/48000";
              };
            };
          }
        ];
      };
    };
  };
}
