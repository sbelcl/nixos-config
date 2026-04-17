#
# ~/.nixos/home/modules/dolphin.nix
#
# Dolphin file manager with thumbnail and KIO support
#
{ pkgs, ... }: {
  home.packages = with pkgs; [
    kdePackages.dolphin
    kdePackages.kio-extras       # sftp://, smb://, fish:// in address bar
    kdePackages.kdegraphics-thumbnailers  # image/SVG thumbnails
    kdePackages.ffmpegthumbs     # video thumbnails
    kdePackages.ark              # archive manager (integrates with Dolphin)
  ];
}
