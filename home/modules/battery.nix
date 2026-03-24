#
# ~/.nixos/home/modules/battery.nix
#
# - poweralertd: listens to UPower D-Bus events, notifies at 20 / 10 / 5 / 2%
#   and on charge/discharge transitions
# - battery-check timer: backup every 3 min; persistent critical alert below 10%
#   with escalating urgency so it can't be silently missed
#
{pkgs, ...}: {

  home.packages = [ pkgs.poweralertd ];

  # ── poweralertd ───────────────────────────────────────────────────────────
  systemd.user.services.poweralertd = {
    Unit = {
      Description     = "Power alert daemon (UPower → libnotify)";
      After           = [ "graphical-session.target" ];
      PartOf          = [ "graphical-session.target" ];
      ConditionEnvironment = "NIRI_SOCKET";
    };
    Service = {
      ExecStart   = "${pkgs.poweralertd}/bin/poweralertd";
      Restart     = "on-failure";
      RestartSec  = "5s";
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };

  # ── backup battery-check timer ────────────────────────────────────────────
  systemd.user.services.battery-check = {
    Unit = {
      Description = "Battery level check — escalating alerts when low";
      ConditionEnvironment = "NIRI_SOCKET";
    };
    Service = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "battery-check" ''
        BAT=/sys/class/power_supply/BAT1
        [ -f "$BAT/capacity" ] || exit 0

        STATUS=$(cat "$BAT/status")
        [ "$STATUS" = "Charging" ] && exit 0   # plugged in — nothing to warn

        CAP=$(cat "$BAT/capacity")

        if   [ "$CAP" -le 5 ]; then
          ${pkgs.libnotify}/bin/notify-send \
            --urgency=critical \
            --expire-time=0 \
            --icon=battery-caution \
            "⚠ Battery Critical: $CAP%" \
            "Plug in now or your work will be lost."
        elif [ "$CAP" -le 10 ]; then
          ${pkgs.libnotify}/bin/notify-send \
            --urgency=critical \
            --expire-time=15000 \
            --icon=battery-low \
            "Battery Low: $CAP%" \
            "Please plug in soon."
        elif [ "$CAP" -le 20 ]; then
          ${pkgs.libnotify}/bin/notify-send \
            --urgency=normal \
            --expire-time=8000 \
            --icon=battery-low \
            "Battery: $CAP%" \
            "Consider plugging in."
        fi
      '';
    };
  };

  systemd.user.timers.battery-check = {
    Unit.Description = "Battery check every 3 minutes";
    Timer = {
      OnBootSec     = "2min";
      OnUnitActiveSec = "3min";
      Unit          = "battery-check.service";
    };
    Install.WantedBy = [ "timers.target" ];
  };
}
