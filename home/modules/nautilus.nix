#
# ~/.nixos/home/modules/nautilus.nix
#
# Nautilus — the GUI file manager on both machines, replacing Dolphin.
# ranger (SUPER+R) is still the TUI half of the pair.
#
# The KDE apps that came in with Dolphin did not leave with it: Ark and
# Okular are still the archive and PDF handlers in packages.nix's mimeApps
# table, and they live in kde-apps.nix now.
#
# System-side bits are in modules/software/nautilus.nix — only the
# context-menu terminal extension needs to be there, because it loads from a
# session variable.
#
{ pkgs, ... }: {
  home.packages = with pkgs; [
    nautilus
    # Space-bar preview, the way GNOME does Quick Look. Nautilus asks for it
    # over D-Bus, so installing it is the whole setup.
    sushi
    # Thumbnailers are found through XDG_DATA_DIRS/thumbnailers/*.thumbnailer,
    # so having the package on the profile is enough — no service to enable.
    # Images are built into gdk-pixbuf; these cover the two gaps that matter
    # here. (PDF thumbnails would need evince-thumbnailer, which is a whole
    # second document viewer next to Okular, so they stay off.)
    ffmpegthumbnailer
    webp-pixbuf-loader
  ];

  dconf.settings = {
    "org/gnome/nautilus/preferences" = {
      default-folder-viewer = "list-view";
      # Shift+Delete without the "move to trash first" detour.
      show-delete-permanently = true;
      # Searching a NFS mount (/mnt/storage on flanker) recursively stalls on
      # the network round trip; local-only keeps type-to-search instant.
      recursive-search = "local-only";
    };
    "org/gnome/nautilus/list-view".use-tree-view = true;
    "org/gtk/settings/file-chooser".sort-directories-first = true;

    # libadwaita reads this, and Nautilus is libadwaita. Without it the window
    # comes up white next to everything else in the session.
    #
    # This is the default, not the owner: theme-mode (theme.nix) rewrites it
    # at runtime, and re-applies the stored mode after every switch, so a
    # light session survives `updhome` even though this says dark.
    "org/gnome/desktop/interface".color-scheme = "prefer-dark";

    # The terminal for "Open in Terminal" is NOT set here: the NixOS module
    # (modules/software/nautilus.nix) writes it into the system dconf profile
    # with lockAll, which would win over anything home-manager put here.
  };
}
