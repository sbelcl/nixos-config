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

  # Launch via Hyprland exec-once (not systemd) so it starts after monitors are registered.
  # Disable the auto-generated systemd service.
  systemd.user.services.hyprpaper.Install.WantedBy = lib.mkForce [];
}
