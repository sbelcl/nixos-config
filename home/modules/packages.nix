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
    alacritty
    eza
    bat
    gh
    wl-clipboard
    mission-center
    # CLI utilities
    ripgrep
    fd
    jq
    htop
    tree
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
    # Audio & video
    vlc
    audacity
    # Social media
    discord
    telegram-desktop
  ];

  nixpkgs.config.allowUnfree = true;
}
