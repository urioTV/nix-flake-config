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

    sunshine = {
      enable = false;
      openFirewall = true;
      capSysAdmin = true;
    };
  };
  programs.system-config-printer.enable = true;
}
