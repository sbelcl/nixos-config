#
# ~/.nixos/home/software/packages.nix
#
{
  config,
  pkgs,
  lib,
  ...
}: let
  kimi-cli = pkgs.callPackage ../pkgs/kimi-cli.nix {};
in {
  # Enable firefox
  programs.firefox.enable = true;

  # Persistent default app associations
  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      # Browser
      "text/html"                = "yandex-browser-beta.desktop";
      "x-scheme-handler/http"   = "yandex-browser-beta.desktop";
      "x-scheme-handler/https"  = "yandex-browser-beta.desktop";
      "x-scheme-handler/ftp"    = "yandex-browser-beta.desktop";
      "x-scheme-handler/about"  = "yandex-browser-beta.desktop";
      "x-scheme-handler/unknown"= "yandex-browser-beta.desktop";
      "application/xhtml+xml"   = "yandex-browser-beta.desktop";
      # File manager
      "inode/directory"          = "org.kde.dolphin.desktop";
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
    tree
    tesseract   # OCR — extract text from screen regions (Mod+Ctrl+Print)
    wev         # Wayland event viewer — identify key names
    nmap        # network scanner
    psmisc      # killall, fuser, pstree
    poppler-utils # PDF tools (pdftotext, pdfimages, etc.)
    # Archive management (ark is in dolphin.nix)
    p7zip
    unrar
    zip
    unzip
    # Disk & hardware
    gparted
    smartmontools
    nvtopPackages.nvidia
    # Programming
    nodejs_20
    godot
    dos2unix
    claude-code
    gemini-cli
    kimi-cli
    kiro
    codex
    python315
    # LibreOffice
    libreoffice-qt-fresh
    hunspell
    # Web browsers & mail clients
    brave
    google-chrome
    thunderbird
    # Remote tools
    filezilla
    putty
    dig
    gnome-calculator
    # Audio & video
    vlc
    audacity
    # Social media
    discord
    telegram-desktop
  ];

  nixpkgs.config.allowUnfree = true;
}
