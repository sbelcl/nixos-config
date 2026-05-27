#
# ~/.nixos/modules/software/hyprland.nix
#
# Hyprland - dynamic tiling Wayland compositor
#
{
  config,
  lib,
  pkgs,
  ...
}:
with lib; {
  options.desktop.hyprland = {
    enable = mkEnableOption "Hyprland Wayland compositor";
  };

  config = mkIf config.desktop.hyprland.enable {
    # Required for hyprlock to authenticate via PAM
    security.pam.services.hyprlock = {};

    programs.hyprland = {
      enable = true;
      # xwayland.enable = true; # enabled by default
    };

    # logind handles seat management (seatd can't survive VT switches)

    # XDG portal for Hyprland
    xdg.portal = {
      enable = true;
      extraPortals = [pkgs.xdg-desktop-portal-hyprland];
      configPackages = [pkgs.hyprland];
    };

    # Hyprland ecosystem packages
    environment.systemPackages = with pkgs; [
      # Core utilities
      hyprpaper # wallpaper
      hyprlock # screen locker
      hypridle # idle daemon
      hyprpicker # color picker

      # Notification
      dunst

      # Launcher
      fuzzel

      # Blue light filter
      hyprsunset

      # Screenshot
      grim
      slurp

      # Clipboard
      wl-clipboard
      cliphist

      # Input
      libinput
    ];
  };
}
