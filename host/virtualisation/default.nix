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
  ];

  # Qemu KVM and virt-manager

  # programs.virt-manager.enable = true;

  virtualisation = {
    podman = {
      enable = true;
      dockerCompat = true;
    };
    # libvirtd = {
    #   enable = true;
    #   qemu = {
    #     package = pkgs.qemu_kvm;
    #     # runAsRoot = true;
    #     swtpm.enable = true;
    #     ovmf = {
    #       enable = true;
    #       packages = [
    #         (pkgs.OVMF.override {
    #           secureBoot = true;
    #           tpmSupport = true;
    #         }).fd
    #       ];
    #     };
    #   };
    # };
    vmware.host.enable = true;
    vmware.host.package = pkgs.nixpkgs-vmware.vmware-workstation;
  };

  users.users.urio = {
    extraGroups = [
      "libvirtd"
      "podman"
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
