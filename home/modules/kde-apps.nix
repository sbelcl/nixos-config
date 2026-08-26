#
# ~/.nixos/home/modules/kde-apps.nix
#
# What is left of the KDE side after Dolphin was replaced by Nautilus: Ark
# and Okular, which packages.nix still points at for archives and PDFs.
#
# The service-cache bits below came with Dolphin but are not about it — they
# are what lets any KDE application resolve "open with" against the desktop
# files on this system, which Ark needs to hand a file to anything else.
#
{ pkgs, lib, ... }: {
  # kbuildsycoca6 needs applications.menu to find desktop files.
  # Without it, it builds an empty database and KDE apps see no applications
  # at all in their "open with" menus.
  xdg.configFile."menus/applications.menu".text = ''
    <!DOCTYPE Menu PUBLIC "-//freedesktop//DTD Menu 1.0//EN"
    "http://www.freedesktop.org/standards/menu-spec/menu-1.0.dtd">
    <Menu>
      <Name>Applications</Name>
      <DefaultAppDirs/>
      <DefaultDirectoryDirs/>
    </Menu>
  '';

  # Rebuild the KDE service cache at session start.
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
    kdePackages.ark              # archive handler (xdg.mimeApps)
    kdePackages.okular           # PDF & document viewer (xdg.mimeApps)
  ];
}
