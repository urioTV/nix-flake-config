{
  config,
  lib,
  pkgs,
  chaotic,
  ...
}:
{
  networking.hostName = "konrad-m18"; # Define your hostname.

  environment.systemPackages = with pkgs; [
    openvpn
    tailscale
  ];

  services.tailscale = {
    enable = true;
  };

  # Enable networking
  networking.networkmanager = {
    enable = true;
    plugins = with pkgs; [
      networkmanager-openvpn
    ];
  };

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
