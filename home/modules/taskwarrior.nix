{ pkgs, ... }:
let
  taskNotify = pkgs.writeShellScript "task-notify" ''
    export PATH="${pkgs.taskwarrior3}/bin:${pkgs.libnotify}/bin:$PATH"

    # Overdue tasks
    overdue=$(task rc.verbose=nothing rc.color=off overdue count 2>/dev/null || echo 0)
    if [ "$overdue" -gt 0 ]; then
      list=$(task rc.verbose=nothing rc.color=off overdue 2>/dev/null)
      notify-send -u critical "Overdue Tasks ($overdue)" "$list"
    fi

    # Tasks due today
    today=$(task rc.verbose=nothing rc.color=off due:today count 2>/dev/null || echo 0)
    if [ "$today" -gt 0 ]; then
      list=$(task rc.verbose=nothing rc.color=off due:today 2>/dev/null)
      notify-send -u normal "Due Today ($today)" "$list"
    fi
  '';
in {
  # Taskwarrior reminder — checks every 30 minutes for due/overdue tasks
  systemd.user.services.task-notify = {
    Unit = {
      Description = "Taskwarrior due-date notifications";
      After = [ "graphical-session.target" ];
    };
    Service = {
      Type = "oneshot";
      ExecStart = "${taskNotify}";
    };
  };

  systemd.user.timers.task-notify = {
    Unit.Description = "Taskwarrior reminder timer";
    Timer = {
      OnCalendar = "*:00,30";   # every 30 minutes
      Persistent = true;        # fire missed events after sleep/suspend
    };
    Install.WantedBy = [ "timers.target" ];
  };
}
