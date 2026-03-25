#
# ~/.nixos/home/software/packages.nix
#
{
  config,
  pkgs,
  lib,
  ...
}: {
  # Enable firefox
  programs.firefox.enable = true;

  # Persistent default app associations
  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "text/html"                = "yandex-browser-beta.desktop";
      "x-scheme-handler/http"   = "yandex-browser-beta.desktop";
      "x-scheme-handler/https"  = "yandex-browser-beta.desktop";
      "x-scheme-handler/ftp"    = "yandex-browser-beta.desktop";
      "x-scheme-handler/about"  = "yandex-browser-beta.desktop";
      "x-scheme-handler/unknown"= "yandex-browser-beta.desktop";
      "application/xhtml+xml"   = "yandex-browser-beta.desktop";
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
    # Archive management
    file-roller
    p7zip
    unrar
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
