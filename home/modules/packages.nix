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
    # Image viewing and manipulation
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
    gh
    wl-clipboard
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
    google-chrome
    thunderbird
    # Remote tools
    filezilla
    putty
    dig
    # Audio & video
    vlc
    audacity
    # Social media
    discord
    telegram-desktop
  ];

  nixpkgs.config.allowUnfreePredicate = pkg:
    builtins.elem (lib.getName pkg) [
      "claude-code"
      "kiro"
      "google-chrome"
      "discord"
      "telegram-desktop"
    ];
}
