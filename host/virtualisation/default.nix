{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
{
  # Qemu KVM and virt-manager

  programs.virt-manager.enable = true;

  virtualisation = {
    docker = {
      enable = true;
    };
    libvirtd = {
      enable = true;
      qemu = {
        package = pkgs.qemu_kvm;
        runAsRoot = true;
        swtpm.enable = true;
        ovmf = {
          enable = true;
          packages = [
            (pkgs.OVMF.override {
              secureBoot = true;
              tpmSupport = true;
            }).fd
          ];
        };
      };
    };
  };

  users.users.urio = {
    extraGroups = [ "libvirtd" ];
  };
}
