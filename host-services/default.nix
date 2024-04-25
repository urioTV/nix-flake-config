{ config, lib, pkgs, chaotic, inputs, ... }: {

  imports = [
    # Include the results of the hardware scan.

  ];

  services = {
    fwupd.enable= true;
  };

}
