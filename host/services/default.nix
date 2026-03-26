{
  config,
  lib,
  pkgs,
  ...
}:
{
  services = {
    flatpak = {
      enable = true;
      update = {
        onActivation = true;
      };
      packages = [
        "com.github.tchx84.Flatseal"
        "com.microsoft.Edge"
        "com.mikrotik.WinBox"
        "com.rustdesk.RustDesk"
        "com.spotify.Client"
        "com.stremio.Stremio"
        "io.github.flattool.Warehouse"
        "net.codelogistics.clicker"
        "com.usebottles.bottles"
      ];
      overrides = {
        global = {
          Context.filesystems = [
            "/run/current-system/sw/share/icons:ro"
            "/run/current-system/sw/share/fonts:ro"
          ];
        };
      };
    };
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
    ananicy = {
      enable = true;
      package = pkgs.ananicy-cpp;
      rulesProvider = pkgs.ananicy-rules-cachyos;
      extraRules = [
        {
          name = "dotnet";
          type = "Game";
          nice = -20;
        }
        {
          name = "dwarfort";
          type = "Game";
          nice = -20;
        }
        {
          name = "WoW.exe";
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
  # security.auditd.enable = true;
  programs.system-config-printer.enable = true;
}
