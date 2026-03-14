{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  sh = "${pkgs.bash}/bin/sh";
in
{
  environment.systemPackages = with pkgs; [
    distrobox
    podman-tui
    podman-compose
    OVMFFull
    quickemu
    quickgui
  ];

  environment.sessionVariables = {
    DBX_CONTAINER_MANAGER = "podman";
    DBX_CONTAINER_HOME_PREFIX = "/home/urio/distrobox";
  };

  # Qemu KVM and virt-manager

  programs.virt-manager.enable = true;

  virtualisation = {
    podman = {
      enable = true;
      dockerCompat = true;
    };
    # docker = {
    #   enable = true;
    # };
    libvirtd = {
      enable = true;
      qemu = {
        package = pkgs.qemu_kvm;
        runAsRoot = true;
        swtpm.enable = true;
      };
    };
    # vmware.host.enable = true;
  };

  # Fix: nixpkgs bug - virt-secret-init-encryption.service uses /usr/bin/sh which doesn't exist on NixOS
  # systemd.services doesn't override units from systemd.packages, so we use a drop-in file instead
  systemd.services.virt-secret-init-encryption.serviceConfig = {
    ExecStart = [
      "" # reset the list from the package unit
      "${sh} -c 'umask 0077 && (dd if=/dev/random status=none bs=32 count=1 | systemd-creds encrypt --name=secrets-encryption-key - /var/lib/libvirt/secrets/secrets-encryption-key)'"
    ];
  };

  users.users.urio = {
    extraGroups = [
      "libvirtd"
      "podman"
      "docker"
      "kvm"
    ];
    # subGidRanges = [
    #   {
    #     count = 65536;
    #     startGid = 1000;
    #   }
    # ];
    # subUidRanges = [
    #   {
    #     count = 65536;
    #     startUid = 1000;
    #   }
    # ];
  };
}
