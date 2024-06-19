{ inputs, config, pkgs, chaotic, ... }: {

  services.displayManager.sddm = {
    enable = true;
    # theme = "sddm-chili-theme";
    # package = pkgs.kdePackages.sddm;
  };

  services.desktopManager.plasma6.enable = true;

  services = { flatpak.enable = true; };

  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [ ];
  };

  environment.systemPackages = with pkgs;
    [
      (pkgs.writeTextDir "share/sddm/themes/breeze/theme.conf.user" ''
        [General]
        background=${../../tech-driad.png}
      '')
    ];
}
