#
# ~/.nixos/modules/settings/storage.nix
#
# Removable media, network shares and the filesystem drivers behind them.
#
# This was thunar.nix, and everything in it was justified as "what Thunar
# needs". Thunar is gone (Nautilus is the file manager), but none of what is
# left was ever really about Thunar:
#
#   udisks2  is what actually performs a mount. udiskie — the automount
#            agent, in home/modules/hyprland/services.nix — talks to it over
#            D-Bus and is what pops ranger open on a new mount. Neither file
#            manager automounts anything: GNOME's automount lives in
#            gnome-settings-daemon, which does not run here.
#   gvfs     gives Nautilus its trash, its network browsing (smb://, mtp://)
#            and its mount integration.
#
# Dropped with Thunar: tumbler, its thumbnail service, which Nautilus does
# not use — it has its own thumbnailer and finds it through
# XDG_DATA_DIRS/thumbnailers (see home/modules/nautilus.nix). The system
# copies of ffmpegthumbnailer, p7zip, unzip and unrar went with it too; they
# were there for tumbler and Thunar's archive plugin, and the user profile
# carries its own (home/modules/packages.nix), which is what Ark resolves
# against.
#
{ pkgs, ... }: {
  services = {
    gvfs.enable = true; # trash, smb://, mtp://, admin://, etc.
    udisks2.enable = true; # (auto)mount removable drives
  };

  environment.systemPackages = with pkgs; [
    ntfs3g # NTFS read/write
    cifs-utils # actually mounting SMB shares, as opposed to browsing them
    # Android / MTP support is handled by gvfs (enabled above) — jmtpfs was
    # dropped from nixpkgs as unmaintained.
  ];

  # Better MTP detection (Android phones)
  services.udev.packages = [ pkgs.libmtp ];
}
