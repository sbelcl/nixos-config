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

  home.packages = with pkgs; [
    # Image viewing and manipultaion
    gimp
    inkscape
    krita
    qview
    blender
    imagemagick
    upscayl
    # Terminal & tools
    alacritty
    eza
    bat
    mako
    swaylock
    swaybg
    wl-clipboard
    wlr-randr
    xwayland-satellite
    fuzzel
    mission-center
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
    google-chrome #vivaldi
    thunderbird
    # Remote tools
    filezilla
    putty
    dig #rustdesk anydesk
    # Audi&Videi playback and manipulation
    vlc
    audacity
    # Social media
    #discord telegram-desktop

    #Temp for testing
    dconf
    gsettings-desktop-schemas
  ];

  nixpkgs.config.allowUnfreePredicate = pkg:
    builtins.elem (lib.getName pkg) [
      "claude-code"
      "kiro"
      "google-chrome"
    ];
}
