{
  lib,
  modulesPath,
  pkgs,
  ...
}:
{
  imports = [
    (modulesPath + "/installer/cd-dvd/installation-cd-minimal.nix")
  ];

  networking.hostName = "konrad-desktop-installer";
  networking.networkmanager.enable = true;

  services.openssh = {
    enable = true;
    settings = {
      KbdInteractiveAuthentication = false;
      PasswordAuthentication = false;
      PermitRootLogin = "prohibit-password";
    };
  };

  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDRfYCXQz7XXM9pupEpNw949Yh2fuMvfJouJZi6+HOIH urio@konrad-m18"
  ];

  services.netbird.enable = true;

  nixpkgs.config.allowUnfree = true;
  hardware.enableAllFirmware = true;
  hardware.enableRedistributableFirmware = true;

  # The nixpkgs default kernel is recent enough for RDNA 4 and avoids
  # rebuilding a large out-of-tree installer kernel.
  boot.kernelPackages = pkgs.linuxPackages;
  boot.supportedFilesystems = lib.mkForce [
    "btrfs"
    "vfat"
  ];

  environment.systemPackages = with pkgs; [
    age
    btrfs-progs
    curl
    cryptsetup
    git
    gptfdisk
    lvm2
    micro
    nvme-cli
    parted
    pciutils
    sops
    smartmontools
    tmux
    usbutils
  ];

  image.baseName = lib.mkForce "konrad-desktop-installer";
  isoImage.squashfsCompression = "zstd -Xcompression-level 6";

  # Installation will use this repository as a flake, so embedding a complete
  # nixpkgs channel would only make the image much larger and slower to build.
  system.installer.channel.enable = false;

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  system.stateVersion = "25.11";
}
