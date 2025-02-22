{
  config,
  lib,
  pkgs,
  ...
}:
{
  fileSystems = {
    "/".options = [ "compress=zstd" ];
    "/home".options = [ "compress=zstd" ];
    "/nix".options = [
      "compress=zstd"
      "noatime"
    ];
  };

  services = {
    btrfs.autoScrub = {
      enable = true;
      interval = "monthly";
      fileSystems = [ "/" ];
    };
  };

  boot.supportedFilesystems = [
    "ntfs"
    "exfat"
    "cifs"
    "nfs"
    "ceph"
  ];
}
