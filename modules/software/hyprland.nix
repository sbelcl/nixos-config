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
    programs.hyprland = {
      enable = true;
      # xwayland.enable = true; # enabled by default
    };

    services.seatd.enable = true;

    # XDG portal for Hyprland
    xdg.portal = {
      enable = true;
      extraPortals = [pkgs.xdg-desktop-portal-hyprland];
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
      wofi
      fuzzel

      # Bar
      waybar

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
