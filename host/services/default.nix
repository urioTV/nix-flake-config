{
  config,
  lib,
  pkgs,
  ...
}:
{
  services = {
    # Enable CUPS to print documents.
    printing.enable = true;
    avahi = {
      enable = true;
      nssmdns = true;
      openFirewall = true;
    };

    fwupd.enable = true;

    openssh = {
      enable = true;
      settings.PermitRootLogin = "yes";
    };

    ollama = {
      enable = false;
      acceleration = "rocm";
      rocmOverrideGfx = "11.0.0";
    };

    open-webui = {
      enable = false;
      port = 2137;
    };

    syncthing = {
      enable = true;
    };
  };
  programs.system-config-printer.enable = true;
}
