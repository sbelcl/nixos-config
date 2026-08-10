#
# ~/.nixos/home/modules/hyprland/wayle.nix
#
# Wayle — GTK4/Rust status bar & notification daemon (successor to HyprPanel).
# Runs as `wayle shell` from Hyprland's exec-once (see config.nix).
# Config lives at ~/.config/wayle/config.toml (not managed by home-manager yet —
# start from `wayle config default` and tune interactively via `wayle-settings`).
#
{ pkgs, ... }: {
  home.packages = [ pkgs.wayle ];
}
