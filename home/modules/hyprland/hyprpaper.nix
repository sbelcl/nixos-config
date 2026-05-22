#
# ~/.nixos/home/modules/hyprland/hyprpaper.nix
#
{ lib, ... }: let
  wallpaper = ../../../assets/wallpapers/default.png;
in {
  services.hyprpaper = {
    enable = true;
    settings = {
      preload = [ "${wallpaper}" ];
      wallpaper = [ ",${wallpaper}" ];  # empty monitor = all outputs
      splash = false;
    };
  };

  # Only run in Hyprland sessions
  systemd.user.services.hyprpaper.Unit.ConditionEnvironment =
    lib.mkForce "HYPRLAND_INSTANCE_SIGNATURE";
}
