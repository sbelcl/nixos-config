#
# ~/.nixos/home/software/packages.nix
#
{
  config,
  pkgs,
  lib,
  ...
}: let
  # xdg-mime dispatches on URL *scheme*, never on domain, so "YouTube links
  # open in FreeTube" cannot be expressed in the table below — https is https.
  # This dispatcher becomes the http/https handler instead: YouTube links go
  # to FreeTube, everything else is handed straight back to the browser.
  # Unrecognised URLs fall through to the browser, so anything this script
  # doesn't understand degrades to normal browsing rather than opening nothing.
  #
  # studio. and music.youtube.com are routed to the browser on purpose —
  # FreeTube renders neither, and swallowing those links silently is worse
  # than just opening them.
  #
  # The browser is launched through its .desktop entry rather than its binary
  # so that --ozone-platform=wayland and --use-angle=gl stay defined in exactly
  # one place (home/modules/yandex.nix). Bypassing them renders every Chromium
  # window blank on the NVIDIA proprietary driver, and a second copy of the
  # flags here would drift out of sync silently.
  youtube-link-dispatch = pkgs.writeShellScriptBin "youtube-link-dispatch" ''
    browser() {
      exec ${pkgs.gtk3}/bin/gtk-launch yandex-browser-beta.desktop "$@"
    }

    [ $# -eq 0 ] && browser

    case "$1" in
      *://studio.youtube.com/*|*://music.youtube.com/*) browser "$@" ;;
      *://youtu.be/*|*://youtube.com/*|*://*.youtube.com/*)
        exec ${pkgs.freetube}/bin/freetube "$1"
        ;;
    esac

    browser "$@"
  '';
in {
  # Enable firefox
  programs.firefox.enable = true;
  programs.firefox.configPath = ".mozilla/firefox";

  # Persistent default app associations
  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      # Browser
      "text/html"                = "yandex-browser-beta.desktop";
      # http/https go through the dispatcher above, not straight to the
      # browser: it forwards YouTube links to FreeTube and everything else
      # back to Yandex. text/html stays on the browser — local .html files
      # are not URLs and never need routing.
      "x-scheme-handler/http"   = "youtube-link-dispatch.desktop";
      "x-scheme-handler/https"  = "youtube-link-dispatch.desktop";
      "x-scheme-handler/ftp"    = "yandex-browser-beta.desktop";
      "x-scheme-handler/about"  = "yandex-browser-beta.desktop";
      "x-scheme-handler/unknown"= "yandex-browser-beta.desktop";
      "application/xhtml+xml"   = "yandex-browser-beta.desktop";
      # File manager
      "inode/directory"          = "org.gnome.Nautilus.desktop";
      # Images → Loupe
      "image/jpeg"               = "org.gnome.Loupe.desktop";
      "image/png"                = "org.gnome.Loupe.desktop";
      "image/gif"                = "org.gnome.Loupe.desktop";
      "image/webp"               = "org.gnome.Loupe.desktop";
      "image/svg+xml"            = "org.gnome.Loupe.desktop";
      "image/tiff"               = "org.gnome.Loupe.desktop";
      "image/bmp"                = "org.gnome.Loupe.desktop";
      "image/heic"               = "org.gnome.Loupe.desktop";
      "image/avif"               = "org.gnome.Loupe.desktop";
      "image/jxl"                = "org.gnome.Loupe.desktop";
      # Video → mpv
      "video/mp4"                = "mpv.desktop";
      "video/mkv"                = "mpv.desktop";
      "video/x-matroska"         = "mpv.desktop";
      "video/webm"               = "mpv.desktop";
      "video/avi"                = "mpv.desktop";
      "video/x-msvideo"          = "mpv.desktop";
      "video/quicktime"          = "mpv.desktop";
      "video/x-flv"              = "mpv.desktop";
      "video/mpeg"               = "mpv.desktop";
      "video/ogg"                = "mpv.desktop";
      # Audio → mpv
      "audio/mpeg"               = "mpv.desktop";
      "audio/mp4"                = "mpv.desktop";
      "audio/ogg"                = "mpv.desktop";
      "audio/flac"               = "mpv.desktop";
      "audio/wav"                = "mpv.desktop";
      "audio/x-wav"              = "mpv.desktop";
      "audio/aac"                = "mpv.desktop";
      "audio/opus"               = "mpv.desktop";
      # PDF → Okular
      "application/pdf"          = "org.kde.okular.desktop";
      # Archives
      "application/zip"          = "org.kde.ark.desktop";
      "application/x-tar"        = "org.kde.ark.desktop";
      "application/x-7z-compressed" = "org.kde.ark.desktop";
      "application/x-rar"        = "org.kde.ark.desktop";
      "application/gzip"         = "org.kde.ark.desktop";
    };
  };

  # Hidden from menus — this is a URL handler, not something to launch.
  xdg.desktopEntries.youtube-link-dispatch = {
    name = "Web Link (YouTube → FreeTube)";
    exec = "${youtube-link-dispatch}/bin/youtube-link-dispatch %u";
    terminal = false;
    type = "Application";
    noDisplay = true;
    mimeType = ["x-scheme-handler/http" "x-scheme-handler/https"];
  };

  # herdr is a TUI and ships no .desktop file, so without an entry of its own
  # it is unreachable from rofi/fuzzel — you would have to open a terminal
  # first. alacritty is spelled out rather than using `terminal = true`, which
  # leaves the choice of terminal to whatever the desktop happens to think it
  # is.
  xdg.desktopEntries.herdr = {
    name        = "herdr";
    genericName = "Agent multiplexer";
    comment     = "Run and switch between multiple coding agents in one terminal";
    exec        = "alacritty -e herdr";
    icon        = "utilities-terminal";
    categories  = [ "Development" "Utility" ];
    terminal    = false;
  };

  home.packages = with pkgs; [
    # Image viewing and manipulation
    gimp
    inkscape
    krita
    qview
    blender
    imagemagick
    sweethome3d.application
    # Upscayl wrapped to disable Electron GPU process (crashes with NVIDIA
    # due to glibc tpp thread-priority assertion). ncnn/Vulkan still works.
    (symlinkJoin {
      name = "upscayl";
      paths = [upscayl];
      nativeBuildInputs = [makeWrapper];
      postBuild = ''
        wrapProgram $out/bin/upscayl --add-flags "--disable-gpu"
      '';
    })
    # Terminal & tools
    eza
    bat
    gh
    wl-clipboard
    libnotify          # notify-send command
    mission-center
    # CLI utilities
    ripgrep
    fd
    jq
    htop
    btop          # nicer top: per-core/gpu graphs, process tree, mouse
    fastfetch     # system summary (the neofetch that is still maintained)
    dua           # interactive disk usage — `dua i /path` to walk and delete
    tldr          # example-first man pages: `tldr tar`
    tree
    lazygit       # git TUI — stage hunks, rebase, resolve conflicts
    lazydocker    # docker TUI — logs, exec, prune (docker is enabled system-wide)
    qrencode      # make QR codes: `qrencode -t ANSIUTF8 'wifi-password'`
    zbar          # read them back: `zbarimg shot.png`
    tesseract   # OCR — extract text from screen regions (Mod+Ctrl+Print)
    wev         # Wayland event viewer — identify key names
    nmap        # network scanner
    psmisc      # killall, fuser, pstree
    poppler-utils # PDF tools (pdftotext, pdfimages, etc.)
    taskwarrior3  # CLI task manager
    taskwarrior-tui # terminal UI for taskwarrior
    # Archive management (ark is in kde-apps.nix)
    p7zip
    unrar
    zip
    unzip
    # Disk & hardware
    gparted
    smartmontools
    nvtopPackages.nvidia
    # Programming
    odin
    nodejs_22
    godot
    dos2unix
    claude-code
    gemini-cli
    kiro
    codex
    herdr         # agent multiplexer — run/switch multiple coding agents in one terminal
    python315
    # LibreOffice
    libreoffice-qt-fresh
    hunspell
    # Annotate and fill PDFs — sign a form, type into a non-fillable one,
    # scribble on a scan. Okular (the default PDF handler in xdg.mimeApps
    # above) only does highlights and sticky notes, so this is a companion
    # to it rather than a replacement; it is deliberately not the mime
    # default.
    xournalpp
    # Web browsers & mail clients
    brave
    google-chrome
    # Thunderbird asked to become the default client on every single start.
    # The startup check (messenger.js) fires when the pref below is true AND
    # isDefaultClient(MAIL | NET_THUNDERBIRD) is false — and that is a bitmask,
    # so it must be default for *both*. mailto already resolves to
    # thunderbird.desktop, but nothing on the system registers the
    # net.thunderbird:// scheme it added, so the second half can never be
    # satisfied and the prompt returns forever.
    #
    # Setting it through the wrapper's autoconfig rather than a profile
    # user.js: prefs.js already had this as false and the dialog came back
    # anyway, and autoconfig applies to every profile and both machines
    # instead of one hardcoded profile directory name.
    #
    # lockPref, not defaultPref, so a stale prefs.js cannot re-enable it. To
    # get the prompt back, drop this override and toggle the checkbox in
    # Settings → General → System Integration.
    (thunderbird.override {
      extraPrefs = ''
        lockPref("mail.shell.checkDefaultClient", false);
      '';
    })
    # Remote tools
    filezilla
    putty
    dig
    gnome-calculator
    # Audio & video
    vlc
    audacity
    stremio-linux-shell
    guvcview      # webcam/microscope viewer with V4L2 controls
    freetube      # NewPipe-style YouTube client; SponsorBlock, local subscriptions
    # Social media
    discord
    telegram-desktop
    antimicrox
    # Other tools
    obsidian
    ranger        # TUI file manager; also popped up on USB mount (services.nix)
  ];

  nixpkgs.config.allowUnfree = true;
}
