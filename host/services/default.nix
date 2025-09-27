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
    # ollama = {
    #   enable = true;
    #   acceleration = "rocm";
    #   # rocmOverrideGfx = "11.0.0";
    # };
    ananicy = {
      enable = true;
      package = pkgs.ananicy-cpp;
      rulesProvider = pkgs.ananicy-rules-cachyos_git;
      extraRules = [
        {
          name = "dotnet";
          type = "Game";
          nice = -20;
        }
      ];
    };
  };
  systemd.services.lact = {
    description = "AMDGPU Control Daemon";
    after = [ "multi-user.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.lact}/bin/lact daemon";
    };
    enable = true;
  };
  environment.systemPackages = with pkgs; [
    lact
  ];
  boot.kernelParams = [ "amdgpu.ppfeaturemask=0xffffffff" ];
  # security.auditd.enable = true;
  programs.system-config-printer.enable = true;
}
