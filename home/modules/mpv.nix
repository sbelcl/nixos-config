#
# ~/.nixos/home/modules/mpv.nix
#
{pkgs, ...}: {

  home.packages = [
    pkgs.loupe    # GTK4 image viewer
    pkgs.yt-dlp   # streaming (used by mpv)
  ];

  xdg.mimeApps.defaultApplications = let
    loupe = "org.gnome.Loupe.desktop";
    mpv   = "mpv.desktop";
  in {
    # Images → loupe
    "image/jpeg"    = loupe;
    "image/png"     = loupe;
    "image/gif"     = loupe;
    "image/webp"    = loupe;
    "image/tiff"    = loupe;
    "image/bmp"     = loupe;
    "image/svg+xml" = loupe;
    "image/heic"    = loupe;
    "image/avif"    = loupe;
    "image/jxl"     = loupe;
    # Video → mpv
    "video/mp4"         = mpv;
    "video/mkv"         = mpv;
    "video/x-matroska"  = mpv;
    "video/webm"        = mpv;
    "video/avi"         = mpv;
    "video/x-msvideo"   = mpv;
    "video/quicktime"   = mpv;
    "video/x-flv"       = mpv;
    "video/mpeg"        = mpv;
    "video/ogg"         = mpv;
    # Audio → mpv
    "audio/mpeg"        = mpv;
    "audio/mp4"         = mpv;
    "audio/flac"        = mpv;
    "audio/ogg"         = mpv;
    "audio/wav"         = mpv;
    "audio/x-wav"       = mpv;
    "audio/aac"         = mpv;
    "audio/opus"        = mpv;
  };

  programs.mpv = {
    enable  = true;
    scripts = with pkgs.mpvScripts; [
      uosc       # modern UI (replaces default OSC)
      thumbfast  # fast timeline thumbnails (works with uosc)
    ];

    config = {
      # ── Video output ──────────────────────────────────────────────────────
      vo          = "gpu-next";
      gpu-api     = "auto";
      hwdec       = "vaapi";          # VA-API is enabled on this machine
      profile     = "gpu-hq";

      # ── Scaling ───────────────────────────────────────────────────────────
      scale       = "ewa_lanczossharp";
      cscale      = "ewa_lanczossharp";
      dscale      = "mitchell";

      # ── Smooth playback ───────────────────────────────────────────────────
      video-sync    = "display-resample";
      interpolation = true;
      tscale        = "oversample";

      # ── Subtitles ─────────────────────────────────────────────────────────
      sub-auto      = "fuzzy";         # load matching subtitle files
      sub-font      = "Inter";
      sub-font-size = 42;
      sub-color     = "#ffffff";
      sub-border-color = "#000000";
      sub-border-size  = 2;
      sub-shadow-offset = 1;

      # ── UI — disable default OSC/bar, uosc replaces them ─────────────────
      osc     = false;
      osd-bar = false;
      border  = false;

      # ── yt-dlp streaming ──────────────────────────────────────────────────
      ytdl-format = "bestvideo[height<=?1080]+bestaudio/best";
    };

    scriptOpts = {
      uosc = {
        timeline_style        = "bar";
        timeline_size         = 6;
        timeline_size_fullscreen = 8;
        controls              = "menu,gap,subtitles,<has_many_audio>audio,<has_many_video>video,<has_many_sub>subtitles,gap,speed,spacer,shuffle,loop-playlist,loop-file,gap,prev,items,next,gap,fullscreen";
        top_bar               = "no-border";
        color                 = "foreground=ffffff,foreground_text=000000,background=0d0e1f,background_text=ffffff,curtain=111111,success=7fc8ff,error=ec4899";
        font                  = "Inter";
      };
      thumbfast = {
        socket    = "/tmp/mpv-thumbfast.sock";
        spawn_first = true;
      };
    };
  };
}
