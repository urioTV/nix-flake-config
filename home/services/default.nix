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
  };
}
