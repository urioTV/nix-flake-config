{
  config,
  pkgs,
  ...
}:
{
  environment.systemPackages = with pkgs; [
    openvpn
  ];

  services.netbird = {
    # The compatibility client runs like the upstream service and exposes its
    # daemon socket to the desktop GUI without a dedicated system group.
    enable = true;
    ui.enable = true;

    clients.default.login = {
      enable = true;
      setupKeyFile = config.sops.secrets.netbird_authkey.path;
    };
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
