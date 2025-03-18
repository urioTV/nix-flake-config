{
  config,
  lib,
  pkgs,
  ...
}:
{
  services = {
    printing.enable = true;
    avahi = {
      enable = true;
      nssmdns4 = true;
      # nssmdns6 = true;
      openFirewall = true;
    };

    fwupd.enable = true;

    openssh = {
      enable = true;
      settings.PermitRootLogin = "yes";
    };

    ollama = {
      enable = false;
      # acceleration = "rocm";
      # rocmOverrideGfx = "11.0.0";
    };
    ananicy = {
      enable = true;
      rulesProvider = pkgs.ananicy-rules-cachyos_git;
    };
  };
  # security.auditd.enable = true;

  programs.system-config-printer.enable = true;
}
