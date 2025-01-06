{
  config,
  lib,
  pkgs,
  chaotic,
  ...
}:
{
  networking.hostName = "konrad-m18"; # Define your hostname.

  # Enable networking
  networking.networkmanager.enable = true;

  # Open ports in the firewall.
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [
      53317
      8000
      9757
    ];
    allowedUDPPorts = [
      53317
      21116
      9757
    ];
    allowedTCPPortRanges = [
      {
        from = 21115;
        to = 21119;
      }
    ];
  };
}
