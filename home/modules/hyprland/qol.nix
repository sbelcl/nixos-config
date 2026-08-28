#
# ~/.nixos/home/modules/hyprland/qol.nix
#
# Small session conveniences, ported from Omarchy: countdown reminders,
# on-demand status notices, an idle-inhibit toggle, a layout switcher, a night
# light toggle, and push-to-talk dictation. Keybinds for all of these live in
# binds.nix, next to every other bind.
#
# Flanker-only, like the rest of hyprland/ — the scripts assume a Wayland
# session with a notification daemon (Wayle) and hypridle.
#
{ pkgs, lib, ... }: let
  notify = "${pkgs.libnotify}/bin/notify-send";

  # ── Reminders ─────────────────────────────────────────────────────────────
  # `remind 7 tea is ready` → notification in 7 minutes. With no arguments,
  # prompts through fuzzel so it can be driven from a keybind.
  #
  # Implemented with a transient systemd timer rather than a background
  # `sleep`: the user manager owns the unit, so it survives the terminal that
  # created it closing, it is listable and cancellable by name, and it does
  # not leave an orphan process per pending reminder.
  #
  # Units are named reminder-<epoch-ns> so the listing and clearing scripts
  # can glob them, and the text is stashed in Description because that is the
  # one field `systemctl show` will hand back verbatim.
  remind = pkgs.writeShellScriptBin "remind" ''
    set -euo pipefail

    if [ $# -eq 0 ]; then
      input=$(${pkgs.fuzzel}/bin/fuzzel --dmenu \
        --prompt-only="remind me in (e.g. 7 tea is ready): " </dev/null) || exit 0
    else
      input="$*"
    fi

    [ -n "''${input// /}" ] || exit 0

    mins=''${input%% *}
    msg=''${input#* }

    # Reject anything that isn't a plain positive integer before handing it to
    # systemd — `--on-active=abcm` fails with a unit error that says nothing
    # useful, and a silent no-op reminder is worse than a rejection.
    case $mins in
      "" | *[!0-9]*)
        ${notify} -u critical "Reminder not set" \
          "Start with a number of minutes, e.g. \`7 tea is ready\`"
        exit 1
        ;;
    esac

    # A bare number with no message is still a useful timer.
    [ "$msg" = "$mins" ] && msg="Time's up"

    ${pkgs.systemd}/bin/systemd-run --user --quiet \
      --unit="reminder-$(${pkgs.coreutils}/bin/date +%s%N)" \
      --description="$msg" \
      --on-active="''${mins}m" \
      ${notify} -u critical "Reminder" "$msg"

    ${notify} -u low "Reminder set" "in $mins min — $msg"
  '';

  reminders-list = pkgs.writeShellScriptBin "reminders-list" ''
    set -euo pipefail

    # NEXT and UNIT columns of list-timers; --no-legend still prints a
    # trailing summary line on some versions, hence the grep for the glob.
    body=""
    while read -r unit; do
      [ -n "$unit" ] || continue
      desc=$(${pkgs.systemd}/bin/systemctl --user show -p Description --value "$unit" 2>/dev/null || true)
      left=$(${pkgs.systemd}/bin/systemctl --user show -p NextElapseUSecRealtime --value "$unit" 2>/dev/null || true)
      body="$body
• $desc''${left:+ (at ''${left#* })}"
    done < <(${pkgs.systemd}/bin/systemctl --user list-units --plain --no-legend --no-pager \
               'reminder-*.timer' 2>/dev/null | ${pkgs.gawk}/bin/awk '{print $1}')

    if [ -z "''${body// /}" ]; then
      ${notify} -u low "Reminders" "None pending"
    else
      ${notify} "Reminders" "$body"
    fi
  '';

  reminders-clear = pkgs.writeShellScriptBin "reminders-clear" ''
    set -euo pipefail

    mapfile -t units < <(${pkgs.systemd}/bin/systemctl --user list-units --plain --no-legend --no-pager \
      'reminder-*.timer' 2>/dev/null | ${pkgs.gawk}/bin/awk '{print $1}')

    if [ ''${#units[@]} -eq 0 ]; then
      ${notify} -u low "Reminders" "None pending"
      exit 0
    fi

    # Stopping a transient timer also unloads it, so there is nothing to reset.
    ${pkgs.systemd}/bin/systemctl --user stop "''${units[@]}"
    ${notify} "Reminders cleared" "''${#units[@]} cancelled"
  '';

  # ── Notices ───────────────────────────────────────────────────────────────
  # Wayle's bar already shows all of this; these are for when the bar is
  # covered by a fullscreen window, which is exactly when you want to check.
  notice-time = pkgs.writeShellScriptBin "notice-time" ''
    exec ${notify} -u low \
      "$(${pkgs.coreutils}/bin/date '+%H:%M')" \
      "$(${pkgs.coreutils}/bin/date '+%A, %-d %B %Y — week %V')"
  '';

  # BAT1 matches hypridle.nix's suspend listener. Globbed rather than
  # hardcoded so a battery renumbering degrades to "unknown" instead of
  # reporting nothing.
  notice-battery = pkgs.writeShellScriptBin "notice-battery" ''
    set -euo pipefail
    bat=$(echo /sys/class/power_supply/BAT* | ${pkgs.coreutils}/bin/cut -d' ' -f1)

    if [ ! -r "$bat/capacity" ]; then
      ${notify} -u critical "Battery" "No battery found"
      exit 0
    fi

    pct=$(< "$bat/capacity")
    state=$(< "$bat/status")
    ${notify} -u low "Battery $pct%" "$state"
  '';

  # wttr.in geolocates by IP, so no location is configured here. -m gives
  # metric units; the timeout keeps a keypress from hanging on a dead network.
  notice-weather = pkgs.writeShellScriptBin "notice-weather" ''
    set -euo pipefail
    out=$(${pkgs.curl}/bin/curl -sf --max-time 5 'https://wttr.in/?format=%l:+%c+%t+(feels+%f)&m' 2>/dev/null || true)

    if [ -z "''${out// /}" ]; then
      ${notify} -u low "Weather" "Unavailable"
    else
      ${notify} -u low "Weather" "$out"
    fi
  '';

  # ── Layout ────────────────────────────────────────────────────────────────
  # Flip general:layout between the scrolling default and dwindle.
  #
  # `hyprctl keyword` is not an option here — with the Lua config format it
  # refuses outright ("keyword can't work with non-legacy parsers. Use
  # eval."), so the switch goes through `hyprctl eval`, which runs a snippet
  # against the live config the same way hyprland.lua does.
  #
  # Reads the current value rather than tracking a counter, so it stays
  # correct if the layout is changed by any other means.
  #
  # Note: workspace 2 pins layout = "dwindle" in its workspace_rule
  # (config.nix), and a per-workspace rule outranks general:layout — so this
  # key does nothing there, by design.
  layout-toggle = pkgs.writeShellScriptBin "layout-toggle" ''
    set -euo pipefail

    cur=$(${pkgs.hyprland}/bin/hyprctl getoption general:layout -j | ${pkgs.jq}/bin/jq -r '.str')
    case "$cur" in
      scrolling) next=dwindle ;;
      *)         next=scrolling ;;
    esac

    ${pkgs.hyprland}/bin/hyprctl eval "hl.config{ general = { layout = \"$next\" } }" >/dev/null
    ${notify} -u low "Layout" "$next"
  '';

  # ── Night light ───────────────────────────────────────────────────────────
  # gammastep (services.nix) follows sunrise and sunset for Ljubljana on its
  # own; this is the manual override for when the warm cast is in the way —
  # judging a photo, picking colours, watching a film.
  #
  # Stopping the unit is enough to get neutral colour back: the adjustment is
  # made through wlr-gamma-control, and the compositor drops it when the
  # client disconnects. Starting it again re-applies whatever is right for
  # the current time of day, so the toggle needs no state of its own.
  #
  # This used to be a fight rather than a toggle: `hyprsunset -t 4500` was
  # started from exec-once at every session while gammastep was already
  # running, so two daemons drove the same protocol and the screen never
  # reached gammastep's 6500K daytime white. hyprsunset is gone.
  nightlight-toggle = pkgs.writeShellScriptBin "nightlight-toggle" ''
    set -uo pipefail
    unit=gammastep.service

    if ${pkgs.systemd}/bin/systemctl --user is-active --quiet "$unit"; then
      ${pkgs.systemd}/bin/systemctl --user stop "$unit"
      ${notify} -u low "Night light off" "Neutral colour restored"
    else
      ${pkgs.systemd}/bin/systemctl --user start "$unit"
      ${notify} -u low "Night light on" "6500K day · 3500K night"
    fi
  '';

  # ── Idle inhibit ──────────────────────────────────────────────────────────
  # hypridle is started from config.nix's exec-once, not by its systemd unit
  # (hypridle.nix forces WantedBy empty), so the toggle stops and starts the
  # process directly rather than going through systemctl.
  #
  # setsid detaches the restarted daemon from this script's process group;
  # without it hypridle dies with the keybind's transient shell.
  idle-toggle = pkgs.writeShellScriptBin "idle-toggle" ''
    set -uo pipefail

    if ${pkgs.procps}/bin/pkill -x hypridle; then
      ${notify} -u normal "Idle inhibited" "Screen will not lock or sleep"
    else
      ${pkgs.util-linux}/bin/setsid ${pkgs.hypridle}/bin/hypridle >/dev/null 2>&1 &
      ${notify} -u low "Idle restored" "Lock 5 min · screen off 10 min"
    fi
  '';
in {
  home.packages = [
    remind
    reminders-list
    reminders-clear
    notice-time
    notice-battery
    notice-weather
    idle-toggle
    layout-toggle
    nightlight-toggle
    # Push-to-talk dictation. The transcription model is a ~1 GB runtime
    # download, not a Nix dependency — run `voxtype setup --download` once,
    # then `voxtype setup check` to confirm the mic and compositor bits.
    pkgs.voxtype
  ];

  # voxtype's keybind entry points (`voxtype record ...`) signal a running
  # daemon; without it every dictation key is a no-op. Gated on
  # HYPRLAND_INSTANCE_SIGNATURE like every other unit in services.nix so it
  # never starts outside a Hyprland session.
  #
  # Restart=on-failure rather than always: with no model downloaded the
  # daemon exits cleanly, and restarting that forever would just spin.
  systemd.user.services.voxtype = {
    Unit = {
      Description = "Voxtype dictation daemon";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
      ConditionEnvironment = "HYPRLAND_INSTANCE_SIGNATURE";
    };
    Service = {
      ExecStart = "${pkgs.voxtype}/bin/voxtype daemon";
      Restart = "on-failure";
      RestartSec = 5;
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };
}
