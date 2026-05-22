#
# ~/.nixos/home/modules/hyprland/hypridle.nix
#
# Mirrors swayidle timeouts: lock at 5 min, monitors off at 10 min.
#
{ lib, ... }: {
  services.hypridle = {
    enable = true;
    settings = {
      general = {
        lock_cmd = "pidof hyprlock || hyprlock";
        before_sleep_cmd = "hyprlock";
        after_sleep_cmd = "hyprctl dispatch dpms on";
        ignore_dbus_inhibit = false;
      };
      listener = [
        {
          timeout = 300;
          on-timeout = "hyprlock";
        }
        {
          timeout = 600;
          on-timeout = "hyprctl dispatch dpms off";
          on-resume = "hyprctl dispatch dpms on";
        }
      ];
    };
  };

  # Only run in Hyprland sessions
  systemd.user.services.hypridle.Unit.ConditionEnvironment =
    lib.mkForce "HYPRLAND_INSTANCE_SIGNATURE";
}
