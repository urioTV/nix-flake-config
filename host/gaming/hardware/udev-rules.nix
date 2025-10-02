{
  config,
  lib,
  pkgs,
  ...
}:
{
  # Gaming device udev rules (moved from configuration.nix)
  services.udev.packages = [
    (pkgs.writeTextFile {
      name = "darkproject-udev-rules";
      destination = "/lib/udev/rules.d/70-darkproject.rules";
      text = ''
        SUBSYSTEM=="hidraw", ATTRS{idVendor}=="342d", ATTRS{idProduct}=="e40f", TAG+="uaccess"
        SUBSYSTEM=="usb",    ATTRS{idVendor}=="342d", ATTRS{idProduct}=="e40f", TAG+="uaccess"
        SUBSYSTEM=="hidraw", ATTRS{idVendor}=="2442", ATTRS{idProduct}=="b071", TAG+="uaccess"
        SUBSYSTEM=="hidraw", ATTRS{idVendor}=="342d", ATTRS{idProduct}=="e410", TAG+="uaccess"
        SUBSYSTEM=="usb",    ATTRS{idVendor}=="342d", ATTRS{idProduct}=="e410", TAG+="uaccess"
      '';
    })
  ];
}
