#
# ~/.nixos/home/modules/dolphin.nix
#
# Dolphin file manager with thumbnail and KIO support
#
{ pkgs, lib, ... }: {
  # Rebuild KDE service cache at session start so Dolphin finds all apps.
  # Must run inside the user session (needs real XDG_DATA_DIRS + XDG_RUNTIME_DIR).
  systemd.user.services.kbuildsycoca = {
    Unit = {
      Description = "Rebuild KDE service cache";
      After = ["graphical-session.target"];
      PartOf = ["graphical-session.target"];
    };
    Service = {
      Type = "oneshot";
      ExecStart = "${pkgs.kdePackages.kservice}/bin/kbuildsycoca6 --noincremental";
    };
    Install.WantedBy = ["graphical-session.target"];
  };

  home.packages = with pkgs; [
    kdePackages.dolphin
    kdePackages.kio-extras       # sftp://, smb://, fish:// in address bar
    kdePackages.kdegraphics-thumbnailers  # image/SVG thumbnails
    kdePackages.ffmpegthumbs     # video thumbnails
    kdePackages.ark              # archive manager (integrates with Dolphin)
    kdePackages.okular           # PDF & document viewer
  ];
}
