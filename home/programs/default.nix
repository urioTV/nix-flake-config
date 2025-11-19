{
  inputs,
  config,
  pkgs,
  chaotic,
  lib,
  ...
}:
{
  imports = [
    ./shells.nix
  ];

  programs = {
    git = {
      enable = true;
      settings = {
        user = {
          email = "uriootv@protonmail.com";
          name = "urioTV";
        };
      };
    };
    bat = {
      enable = true;
    };
    obs-studio = {
      enable = true;
      plugins = with pkgs; [
        # obs-studio-plugins.obs-vaapi
        # obs-studio-plugins.obs-vkcapture
      ];
    };
    # mangohud = {
    #   enable = true;
    #   settings = {
    #     # horizontal = true;
    #     cpu_stats = true;
    #     gpu_stats = true;
    #     ram = true;
    #     vram = true;
    #     fps = true;
    #     frametime = 0;
    #     frame_timing = 1;
    #     hud_no_margin = true;
    #     gpu_power = true;
    #     cpu_power = true;

    #     background_alpha = lib.mkForce 0.3;
    #     alpha = 1.0;

    #     font_size = lib.mkForce 24;
    #     font_scale = lib.mkForce 1.0;
    #     font_size_text = lib.mkForce 24;
    #     font_scale_media_player = lib.mkForce 0.55;
    #     # no_small_font = true;
    #   };
    # };
  };

}
