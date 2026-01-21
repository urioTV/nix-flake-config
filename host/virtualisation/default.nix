{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
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

  users.users.urio = {
    extraGroups = [
      "libvirtd"
      "podman"
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
