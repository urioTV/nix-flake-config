{
  inputs,
  config,
  pkgs,
  chaotic,
  ...
}:
{
  imports = [
    ./hardware
    ./programs
    ./audio
  ];
}
