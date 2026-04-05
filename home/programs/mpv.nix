# home.nix lub moduł mpv.nix
{ pkgs, ... }:

{
  home.file.".mozilla/native-messaging-hosts/ff2mpv.json".source =
    "${pkgs.ff2mpv-go}/lib/mozilla/native-messaging-hosts/ff2mpv.json";

  home.file.".zen/native-messaging-hosts/ff2mpv.json".source =
    "${pkgs.ff2mpv-go}/lib/mozilla/native-messaging-hosts/ff2mpv.json";

  programs.mpv = {
    enable = true;

    extraMakeWrapperArgs = [
      "--set"
      "LIBVA_DRIVER_NAME"
      "radeonsi"
      "--set"
      "VDPAU_DRIVER"
      "radeonsi"
      # "--set"   "DRI_PRIME"   "1"
      # "--set-default"  "WAYLAND_DISPLAY"    "wayland-1"
      "--set-default"
      "XDG_RUNTIME_DIR"
      "/run/user/1000"
    ];

    # Skrypty - pełny GUI jak VLC
    scripts = with pkgs.mpvScripts; [
      # --- Core UI ---
      uosc # nowoczesny UI, zastępuje domyślny OSC
      thumbfast # miniatury w seekbarze (wymaga uosc)

      # --- Playlist & Files ---
      mpv-playlistmanager # zarządzanie playlistą
      memo # menu ostatnich plików

      # --- YouTube/Streaming ---
      sponsorblock # pomijanie reklam i sponsorów na YouTube
      quality-menu # zmiana jakości streamów na żywo

      # --- System Integration ---
      mpris # integracja z KDE Media Controls (Wayland)

      # --- Utilities ---
      mpv-cheatsheet-ng # skróty klawiszowe (dostępne przez menu)
    ];

    # mpv.conf
    config = {
      #---------------------------------------------------------
      # RENDERING — Vulkan (najlepsza ścieżka na Wayland/RDNA3)
      #---------------------------------------------------------
      vo = "gpu-next";
      gpu-api = "vulkan";
      gpu-context = "waylandvk";
      hwdec = "vulkan";
      hwdec-codecs = "all";

      # KLUCZOWA POPRAWKA: ogranicz wyjście mpv do 60fps
      # mpv ignoruje 480Hz monitora i renderuje jak na 60Hz
      display-fps-override = 60;

      # Interpolacja teraz generuje 60fps z 25fps — OK zamiast 480fps
      video-sync = "display-resample";
      interpolation = true;
      tscale = "oversample";

      # Skalowanie — możesz zostawić ewa_lanczos, przy 60Hz to OK
      scale = "ewa_lanczos";
      cscale = "ewa_lanczos";
      correct-downscaling = true;
      sigmoid-upscaling = true;

      #---------------------------------------------------------
      # BUFOROWANIE (streaming YouTube)
      #---------------------------------------------------------
      cache = true;
      cache-secs = 120;
      demuxer-max-bytes = "150MiB";
      demuxer-max-back-bytes = "75MiB";

      #---------------------------------------------------------
      # AUDIO
      #---------------------------------------------------------
      ao = "pipewire"; # KDE Plasma 6 używa PipeWire
      audio-channels = "stereo";
      volume-max = 200;

      #---------------------------------------------------------
      # INTERFEJS — VLC-like
      #---------------------------------------------------------
      osc = false; # wyłącz domyślny OSC — używamy uosc
      osd-bar = false; # uosc ma własny pasek
      border = false; # brak ramki okna
      force-window = "immediate"; # zawsze pokaż okno (nawet dla audio)
      keep-open = true; # nie zamykaj po końcu filmu
      save-position-on-quit = true; # zapamiętaj pozycję
      resume-playback = true; # wznów odtwarzanie
      autofit-larger = "90%x90%"; # skaluj duże filmy do ekranu

      #---------------------------------------------------------
      # YT-DLP — format pobierania z YouTube
      # AV1 do 1080p (VCN4 dekoduje sprzętowo), VP9 powyżej
      #---------------------------------------------------------
      ytdl = true;
      ytdl-format = "bestvideo[height<=?1080][vcodec^=av01]+bestaudio/bestvideo[height<=?2160][vcodec^=vp9]+bestaudio/bestvideo+bestaudio/best";

      #---------------------------------------------------------
      # NAPISY — Inter Nerd Font (zgodnie ze stylix)
      #---------------------------------------------------------
      sub-auto = "fuzzy"; # automatyczne dopasowanie napisów
      sub-font = "Inter Nerd Font";
      sub-font-size = 55;
      sub-bold = false; # Inter już ma odpowiednią wagę
      sub-color = "#FFFFFF";
      sub-border-color = "#000000";
      sub-border-size = 3;
      sub-shadow-offset = 1;
      sub-shadow-color = "#00000080";

      #---------------------------------------------------------
      # ZRZUTY EKRANU
      #---------------------------------------------------------
      screenshot-directory = "~/Pictures/mpv-screenshots";
      screenshot-template = "%F-%P-%#04n";
      screenshot-format = "png";
    };

    # Profile — opcjonalnie dla 4K
    profiles = {
      "4k" = {
        ytdl-format = "bestvideo[height<=?2160][vcodec^=av01]+bestaudio/bestvideo[height<=?2160][vcodec^=vp9]+bestaudio/best";
        scale = "ewa_lanczossharp";
      };

      # Profil oszczędnościowy (bateria)
      "battery" = {
        hwdec = "vaapi";
        vo = "gpu-next";
        gpu-api = "vulkan";
        scale = "bilinear";
        video-sync = "audio";
        interpolation = false;
      };
    };

    # script-opts — opcje skryptów
    scriptOpts = {
      # ─── uosc — konfiguracja UI (VLC-like) ───────────────────
      uosc = {
        # Pasek postępu — zawsze widoczny jako cieniutka linia
        progress = "always";
        progress_size = 2;
        progress_line_width = 18;

        # Timeline — duży, z czasem i rozdziałami
        timeline_style = "bar";
        timeline_size = 40;
        timeline_persistency = "paused,audio-tracks";
        timeline_border = 1;

        # Pasek kontrolny (jak w VLC)
        controls = "menu,gap,subtitles,<has_many_audio>audio,<has_chapter>chapters,gap,speed:button,stream-quality,gap,fullscreen";
        controls_size = 32;
        controls_persistency = "paused";

        # Pasek głośności po prawej
        volume = "right";
        volume_size = 40;

        # Top bar z tytułem (jak pasek tytułu VLC)
        top_bar = "no-border";
        top_bar_size = 40;
        top_bar_persistency = "paused";
        top_bar_title = "\${media-title}";

        # Zakresy rozdziałów (SponsorBlock)
        chapter_ranges = "openings:30abf964,endings:30abf964,ads:c54e4e80";

        # Jakości streamu dostępne z UI
        stream_quality_options = "360p,480p,720p,1080p,1440p,2160p";

        # Animacje i font
        font_scale = 1.0;
        text_border = 1.2;

        # Język
        languages = "pl,en";
      };

      # ─── thumbfast ────────────────────────────────────────────
      thumbfast = {
        network = true; # miniatury dla URL (YouTube)
        hwdec = true; # sprzętowe dekodowanie miniatur
        max_height = 200; # wysokość miniatury w seekbarze
      };

      # ─── SponsorBlock ─────────────────────────────────────────
      sponsorblock = {
        skip_categories = "sponsor,selfpromo,interaction,intro,outro,preview,filler";
        local_database = true;
      };

      # ─── Playlist manager ─────────────────────────────────────
      playlistmanager = {
        showamount = 10; # liczba pozycji do wyświetlenia (-1 = auto)
        playlist_display_timeout = 0;
      };

      # ─── Quality menu (YouTube) ─────────────────────────────
      quality-menu = {
        # Brak dodatkowych opcji - używa domyślnych
      };
    };

    # Skróty klawiszowe (input.conf) — VLC-like z wizualnym feedback
    bindings = {
      # --- Mysz ---
      "MBTN_RIGHT" = "script-binding uosc/menu"; # menu kontekstowe
      "MBTN_LEFT_DBL" = "cycle fullscreen"; # podwójne kliknięcie = fullscreen

      # --- Scroll = głośność ---
      "WHEEL_UP" = "no-osd add volume 5; script-binding uosc/flash-volume";
      "WHEEL_DOWN" = "no-osd add volume -5; script-binding uosc/flash-volume";

      # --- Nawigacja (VLC style) ---
      "RIGHT" = "seek 5; script-binding uosc/flash-timeline";
      "LEFT" = "seek -5; script-binding uosc/flash-timeline";
      "UP" = "no-osd add volume 10; script-binding uosc/flash-volume";
      "DOWN" = "no-osd add volume -10; script-binding uosc/flash-volume";
      "Shift+RIGHT" = "seek 30; script-binding uosc/flash-timeline";
      "Shift+LEFT" = "seek -30; script-binding uosc/flash-timeline";

      # --- Głośność ---
      "9" = "no-osd add volume -2; script-binding uosc/flash-volume";
      "0" = "no-osd add volume 2; script-binding uosc/flash-volume";
      "m" = "no-osd cycle mute; script-binding uosc/flash-volume";

      # --- Prędkość ---
      "[" = "no-osd add speed -0.25; script-binding uosc/flash-speed";
      "]" = "no-osd add speed 0.25; script-binding uosc/flash-speed";
      "\\" = "no-osd set speed 1; script-binding uosc/flash-speed";
      "BS" = "no-osd set speed 1; script-binding uosc/flash-speed";

      # --- Playlist ---
      "n" = "playlist-next";
      "p" = "playlist-prev";
      "ENTER" = "playlist-next";
      "Shift+ENTER" = "playlist-prev";
      "DEL" = "playlist-remove current";

      # --- Okno ---
      "f" = "cycle fullscreen";
      "ESC" = "cycle fullscreen";
      "T" = "cycle ontop";

      # --- Pauza ---
      "SPACE" = "cycle pause; script-binding uosc/flash-pause-indicator";
      "Alt+p" = "cycle pause";

      # --- uosc Menu ---
      "o" = "script-binding uosc/open-file";
      "s" = "script-binding uosc/subtitles";
      "a" = "script-binding uosc/audio";
      "v" = "script-binding uosc/video";
      "c" = "script-binding uosc/chapters";
      "P" = "script-binding uosc/playlist";
      "q" = "script-binding uosc/stream-quality";
      "Tab" = "script-binding uosc/toggle-ui";
      "F1" = "script-binding uosc/keybinds"; # lista skrótów

      # --- Zrzuty ekranu ---
      "S" = "screenshot";
      "Ctrl+s" = "async screenshot";

      # --- Inne ---
      "i" = "script-binding stats/display-page 1";
      "I" = "script-binding stats/display-page 2";
      "`" = "script-binding console/enable";
    };
  };
}
