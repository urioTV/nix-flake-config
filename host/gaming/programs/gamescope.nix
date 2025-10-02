{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
{
  programs.gamescope = {
    enable = true;
    # capSysNice = true;
    env = {
      # SDL_VIDEODRIVER = "x11";
    };
    args = [
      "-h 1200"
      "-w 1920"
      "-H 1200"
      "-W 1920"
      # "--adaptive-sync"
    ];
  };

  # GameMode configuration (commented out in original)
  # programs.gamemode = {
  #   enable = true;
  #   enableRenice = true;
  #   settings = {
  #     general = {
  #       renice = 10;
  #       reaper_freq = 5;
  #       desiredgov = "performance";
  #       igpu_desiredgov = "powersave";
  #       igpu_power_threshold = 0.3;
  #     };
  #     custom = {
  #       start = "${pkgs.libnotify}/bin/notify-send 'GameMode started'";
  #       end = "${pkgs.libnotify}/bin/notify-send 'GameMode ended'";
  #     };
  #   };
  # };
}
