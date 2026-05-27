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
        {
          # Suspend after 20 min — only on battery
          timeout = 1200;
          on-timeout = "cat /sys/class/power_supply/BAT1/status | grep -q Discharging && systemctl suspend";
        }
      ];
    };
  };

  # Disable the systemd auto-start — hypridle is launched from exec-once in
  # config.nix so it starts immediately without the env-propagation delay.
  systemd.user.services.hypridle.Install.WantedBy = lib.mkForce [];
}
