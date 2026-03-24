#
# ~/.nixos/home/modules/thunar.nix
#
# Thunar file manager with:
#  - Archive plugin (right-click compress/extract via file-roller)
#  - Tumbler thumbnail service (images, videos)
#  - ffmpegthumbnailer for video thumbnails
#
{pkgs, lib, ...}: {

  home.packages = with pkgs; [
    xfce.thunar-archive-plugin   # right-click archive support
    xfce.thunar-volman            # auto-mount removable drives
    tumbler                       # D-Bus thumbnail service
    ffmpegthumbnailer             # video thumbnails for tumbler
    libgsf                        # office doc thumbnails
  ];

  # Tumbler is D-Bus activated automatically when Thunar requests thumbnails.
  # We just need the package installed; no explicit service needed.

  # Thunar preferences — show hidden files, single-click, thumbnail view
  xfconf.settings."thunar" = {
    "last-show-hidden"         = true;
    "misc-single-click"        = false;
    "misc-thumbnail-mode"      = "THUNAR_THUMBNAIL_MODE_ALWAYS";
    "misc-date-style"          = "THUNAR_DATE_STYLE_SIMPLE";
    "last-view"                = "ThunarDetailsView";
    "last-details-view-column-widths" = "50,144,100,50,93,167";
  };
}
