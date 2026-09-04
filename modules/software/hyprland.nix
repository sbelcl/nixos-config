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
      # Session entry point. home/modules/users/imnos.nix execs this from zsh
      # on TTY1 for the auto-login hosts. It lives here, behind the same mkIf
      # as the compositor, so the command exists exactly where Hyprland does.
      # Paired with the `command -v` guard on the caller, a host that does not
      # enable this module drops to a normal shell instead of a getty respawn
      # loop. Before this, the caller exec'd a name nothing in the repo
      # defined -- survivable only on a host with a display manager that never
      # reached TTY1, and a login loop the moment one didn't.
      (writeShellScriptBin "start-hyprland" ''
        exec ${config.programs.hyprland.package}/bin/Hyprland "$@"
      '')

      # Core utilities
      hyprpaper # wallpaper
      hyprlock # screen locker
      hypridle # idle daemon
      hyprpicker # color picker

      # Notification
      dunst

      # Launcher
      fuzzel

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
