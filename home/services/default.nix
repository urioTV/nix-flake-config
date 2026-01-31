{
  inputs,
  config,
  pkgs,
  chaotic,
  ...
}:
{
  services = {
    syncthing = {
      enable = true;
    };
    tailscale-systray = {
      enable = true;
    };
  };
}
