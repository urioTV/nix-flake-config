{ config, lib, pkgs, ... }: {
  services = {
    # Enable CUPS to print documents.
    printing.enable = true;
    avahi = {
      enable = true;
      nssmdns = true;
      openFirewall = true;
    };

    fwupd.enable = true;
  };
  programs.system-config-printer.enable = true;
}
