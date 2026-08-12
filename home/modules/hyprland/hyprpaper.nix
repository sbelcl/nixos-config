#
# ~/.nixos/home/modules/hyprland/hyprpaper.nix
#
# Uses awww instead of hyprpaper.  hyprpaper 0.8.3 (nixpkgs) has a startup-
# ordering bug where Wayland outputs are processed before the config is read,
# so wallpapers are never applied.  Its IPC protocol also doesn't match
# Hyprland 0.54.x's hyprctl.
#
# awww is the wallpaper daemon in use. Wayle's own wallpaper engine drives
# the same daemon, so the two coexist.
#
# ~/.config/background must be a regular writable file (not a Nix store
# symlink): wallpaper-next copies the chosen image over it, and hyprlock and
# matugen.nix both read it.
#
{ pkgs, lib, ... }: let
  wallpaper = ../../../assets/wallpapers/default.png;
in {
  home.packages = [ pkgs.awww ];

  # Copy the default wallpaper on first activation only — leaves it as a
  # regular writable file so wallpaper-next can replace it.
  home.activation.initWallpaper = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [ ! -f "$HOME/.config/background" ]; then
      $DRY_RUN_CMD cp ${wallpaper} "$HOME/.config/background"
      $DRY_RUN_CMD chmod 644 "$HOME/.config/background"
    fi
  '';
}
