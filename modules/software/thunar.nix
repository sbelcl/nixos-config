#
# ~/.nixos/modules/software/thunar.nix
#
{ pkgs, lib, ... }:

{
  # Thunar + useful plugins
  programs.thunar = {
    enable = true;
    plugins = with pkgs; [
      thunar-archive-plugin
      thunar-volman
      thunar-media-tags-plugin
    ];
  };

  # Filesystem helpers Thunar relies on
  services = {
    gvfs.enable = true;        # trash, smb://, mtp://, admin://, etc.
    tumbler.enable = true;     # thumbnails (images/video/pdf/…)
    udisks2.enable = true;     # (auto)mount removable drives
  };

  # Optional but handy
  # programs.file-roller.enable = true;  # archive manager (used by archive plugin)

  environment.systemPackages = with pkgs; [
    ntfs3g
    ffmpegthumbnailer     # video thumbs
    p7zip unzip unrar     # archive formats
    # SMB mounting from Thunar (only needed for actual mounts, not just browsing):
    cifs-utils
    # Android / MTP support quality-of-life:
    jmtpfs
  ];

  # Better MTP detection (Android phones)
  services.udev.packages = [ pkgs.libmtp ];
}

