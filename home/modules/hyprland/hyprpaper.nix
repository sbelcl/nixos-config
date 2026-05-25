#
# ~/.nixos/home/modules/hyprland/hyprpaper.nix
#
# Uses swww instead of hyprpaper.  hyprpaper 0.8.3 (nixpkgs) has a startup-
# ordering bug where Wayland outputs are processed before the config is read,
# so wallpapers are never applied.  Its IPC protocol also doesn't match
# Hyprland 0.54.x's hyprctl.
#
# swww is the wallpaper daemon HyprPanel already expects — it uses the
# /home/imnos/.config/background symlink for its wallpaper-cycling feature.
#
{ pkgs, ... }: let
  wallpaper = ../../../assets/wallpapers/default.png;
in {
  home.packages = [ pkgs.swww ];

  # Symlink the default wallpaper to ~/.config/background so HyprPanel's
  # wallpaper-cycling feature knows where to find the current wallpaper.
  home.file.".config/background".source = wallpaper;
}
