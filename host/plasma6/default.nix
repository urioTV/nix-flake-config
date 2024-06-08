{ inputs, config, pkgs, chaotic, ... }: {
  
  services.displayManager.sddm.enable = true;
  services.desktopManager.plasma6.enable = true;

  services = { flatpak.enable = true; };

  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [ ];
  };

  environment.systemPackages = with pkgs;
    [
      
    ];
}
