#
# ~/.nixos/home/modules/dolphin.nix
#
# Dolphin file manager with thumbnail and KIO support
#
{ pkgs, lib, ... }: {
  # Rebuild KDE service cache after each activation so Dolphin picks up MIME changes
  home.activation.kbuildsycoca = lib.hm.dag.entryAfter ["writeBoundary"] ''
    export XDG_RUNTIME_DIR=$(mktemp -d)
    ${pkgs.kdePackages.kservice}/bin/kbuildsycoca6 --noincremental 2>/dev/null || true
    rm -rf "$XDG_RUNTIME_DIR"
  '';

  home.packages = with pkgs; [
    kdePackages.dolphin
    kdePackages.kio-extras       # sftp://, smb://, fish:// in address bar
    kdePackages.kdegraphics-thumbnailers  # image/SVG thumbnails
    kdePackages.ffmpegthumbs     # video thumbnails
    kdePackages.ark              # archive manager (integrates with Dolphin)
    kdePackages.okular           # PDF & document viewer
  ];
}
