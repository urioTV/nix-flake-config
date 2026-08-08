{ self, ... }:
let
  moonshineModule =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    {
      # Full COSMIC desktop environment, installed as a regular desktop
      # (session shows up in SDDM next to Plasma, so it can also be tested
      # locally). It doubles as the "COSMIC Desktop" stream in Moonshine:
      # cosmic-session spawns its components by looking them up in PATH, and
      # start-cosmic re-execs itself through a login shell that sources
      # /etc/profile — with the desktopManager module enabled, all components
      # are in the system profile, so the upstream start-cosmic flow works
      # unmodified inside Moonshine's headless compositor.
      services.desktopManager.cosmic.enable = true;

      # Moonshine — game streaming host for Moonlight clients.
      # Reachable over both the LAN (enp8s0) and the Netbird VPN (wt0).
      services.moonshine = {
        enable = true;
        user = "urio";
        # 1000 is urio's uid; required since it's not declared via users.users.<name>.uid
        uid = 1000;

        # Let the moonshine module open the GameStream ports (TCP 47984/47989/48010,
        # UDP 47998/47999/48000) on all interfaces. This host is on LAN behind
        # NAT with no public port-forwarding, so exposing them broadly is fine
        # and makes the stream reachable over both LAN (enp8s0) and Netbird (wt0).
        openFirewall = true;

        # Silences the per-5s "TLS handshake failed" spam from Moonlight clients
        # idling on the Computers screen (they poll the HTTPS port).
        logFilter = "moonshine=info,moonshine_core::tls=error";

        settings = {
          name = "konrad-desktop";

          # --- Compositor / GPU selection (encoding quality) ---
          compositor = {
            # Pin to the dedicated RX 9070 XT (RDNA4) at PCI 0000:03:00.0.
            # This system has two AMD GPUs (dGPU + Ryzen iGPU at 10:00.0);
            # both score 50 in moonshine's default heuristic, so we pin
            # explicitly to guarantee encoding runs on the dGPU. The value
            # matches PCI_SLOT_NAME in the render-node uevent.
            gpu = "0000:03:00.0";

            # RDNA4 supports HDR (FP16/10-bit render targets). Keep enabled so
            # Moonlight clients that request HDR get true 10-bit BT.2020+PQ.
            hdr = true;

            keyboard = {
              layout = "pl";
              # model "pc104" is the standard full-size Polish layout base.
              model = "pc104";
            };
          };

          # --- Video stream (host-side tunables) ---
          # NOTE: bitrate, codec (H264/HEVC/AV1), resolution and FPS are NOT set
          # here — they are negotiated per-session from the Moonlight client.
          # Choose them in the Moonlight app's stream settings on your device.
          stream = {
            timeout = 60;
            video = {
              # Forward Error Correction overhead per frame. Default 20% is
              # tuned for LAN; bump to 35% for the Netbird VPN path to absorb
              # the occasional dropped packet without a full keyframe.
              fec_percentage = 35;
              # Warn when a frame blows past its encode budget — handy while
              # dialling in client settings; disable once stable.
              log_frame_spikes = true;
            };
          };

          # --- Applications ---
          application = [
            {
              # Full remote desktop: boots the COSMIC desktop environment
              # nested inside Moonshine's headless compositor (see TIPS.md
              # "Run a desktop environment for a full remote desktop").
              # Independent from the host's Plasma session — the physical
              # desktop stays usable while streaming.
              title = "COSMIC Desktop";
              command = [ "${pkgs.cosmic-session}/bin/start-cosmic" ];
            }
            {
              title = "Steam";
              command = [
                "${pkgs.steam}/bin/steam"
                "steam://open/bigpicture"
              ];
              # Close any desktop Steam first so the streaming instance becomes
              # primary (Steam is single-instance per user). See TIPS.md #134.
              pre_command = [
                [
                  "${pkgs.bash}/bin/bash"
                  "-c"
                  "if pgrep -x steam >/dev/null; then steam -shutdown &>/dev/null; for i in $(seq 1 30); do ! pgrep -x steam >/dev/null && break; sleep 1; done; fi"
                ]
              ];
            }
          ];

          # Dynamically discover all installed Steam games so you can stream
          # any of them individually from Moonlight.
          application_scanner = [
            {
              type = "steam";
              library = "$HOME/.local/share/Steam";
              command = [
                "${pkgs.steam}/bin/steam"
                "-bigpicture"
                "steam://rungameid/{game_id}"
              ];
            }
          ];
        };
      };

      # Add urio to the moonshine group so the suspend-inhibit polkit rule
      # (shipped in the package) lets Moonshine hold a sleep block inhibitor
      # for the duration of every stream. inhibit_sleep is on by default.
      users.users.urio.extraGroups = [ "moonshine" ];
    };
in
{
  flake.nixosModules."moonshine-config" = moonshineModule;
}
