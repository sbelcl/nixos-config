#
# ~/.nixos/home/modules/rofi.nix
#
{pkgs, ...}: let

  # ── Launcher ──────────────────────────────────────────────────────────────
  rofi-launcher = pkgs.writeShellScriptBin "rofi-launcher" ''
    # Clock
    TIME=$(date '+%H:%M  ·  %A, %B %-d')

    # Battery (BAT1)
    BAT_PATH=/sys/class/power_supply/BAT1
    if [ -f "$BAT_PATH/capacity" ]; then
      BAT_CAP=$(cat "$BAT_PATH/capacity")
      BAT_STATUS=$(cat "$BAT_PATH/status")
      if [ "$BAT_STATUS" = "Charging" ]; then
        BAT_ICON="󰂄"
      elif [ "$BAT_CAP" -ge 80 ]; then
        BAT_ICON="󰁹"
      elif [ "$BAT_CAP" -ge 50 ]; then
        BAT_ICON="󰁾"
      elif [ "$BAT_CAP" -ge 20 ]; then
        BAT_ICON="󰁼"
      else
        BAT_ICON="󰁺"
      fi
      BAT="$BAT_ICON $BAT_CAP%"
    else
      BAT="󰁹 AC"
    fi

    # WiFi
    WIFI=$(nmcli -t -f active,ssid dev wifi 2>/dev/null | grep '^yes:' | cut -d: -f2-)
    if [ -n "$WIFI" ]; then
      WIFI="󰤨  $WIFI"
    else
      WIFI="󰤭  Offline"
    fi

    # Volume
    VOL_RAW=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null)
    VOL_PCT=$(echo "$VOL_RAW" | awk '{printf "%d", $2*100}')
    if echo "$VOL_RAW" | grep -q MUTED; then
      VOL="󰝟  Muted"
    else
      VOL="󰕾  $VOL_PCT%"
    fi

    # Brightness
    BRIGHT_CUR=$(brightnessctl get 2>/dev/null)
    BRIGHT_MAX=$(brightnessctl max 2>/dev/null)
    if [ -n "$BRIGHT_CUR" ] && [ -n "$BRIGHT_MAX" ] && [ "$BRIGHT_MAX" -gt 0 ]; then
      BRIGHT_PCT=$(( BRIGHT_CUR * 100 / BRIGHT_MAX ))
      BRIGHT="󰃠  $BRIGHT_PCT%"
    else
      BRIGHT="󰃠  N/A"
    fi

    STATUS="$BAT    $WIFI    $VOL    $BRIGHT"

    TMPTHEME=$(mktemp /tmp/rofi-XXXXXX.rasi)
    trap "rm -f '$TMPTHEME'" EXIT
    cat > "$TMPTHEME" << EOF
@import "$HOME/.local/share/rofi/themes/theme.rasi"
textbox-clock {
    content:          "$TIME";
    font:             "Sans Bold 36";
    text-color:       white;
    background-color: #0d0e1f;
    horizontal-align: 0.5;
    padding:          0px 0px 6px 0px;
}
textbox-status {
    content:          "$STATUS";
    font:             "JetBrainsMono Nerd Font 13";
    text-color:       #7878a8;
    background-color: #0d0e1f;
    horizontal-align: 0.5;
    padding:          0px 0px 20px 0px;
}
mainbox {
    children: [ textbox-clock, textbox-status, inputbar, listview ];
}
EOF
    exec rofi -show drun -theme "$TMPTHEME"
  '';

  # ── Power menu ────────────────────────────────────────────────────────────
  rofi-power = pkgs.writeShellScriptBin "rofi-power" ''
    CHOICE=$(printf "󰌾  Lock\n󰍃  Logout\n󰜉  Reboot\n⏻  Shutdown" \
      | rofi -dmenu \
             -p "  " \
             -theme-str '
               window   { width: 280px; border: 4px solid; border-color: #7fc8ff;
                           border-radius: 16px; background-color: #0d0e1f; }
               mainbox  { padding: 16px; }
               inputbar { background-color: #13152e; border-radius: 10px;
                           border: 1px solid; border-color: rgba(127,200,255,0.3);
                           padding: 10px 14px; margin: 0px 0px 12px 0px;
                           children: [prompt]; }
               prompt   { background-color: transparent; text-color: #7fc8ff;
                           font: "Sans Bold 16"; }
               entry    { background-color: transparent; text-color: #f0f0f8; }
               listview { background-color: transparent; lines: 4;
                           scrollbar: false; spacing: 6px; }
               element  { background-color: #13152e; border-radius: 10px;
                           border: 1px solid; border-color: rgba(255,255,255,0.05);
                           padding: 12px 16px; cursor: pointer; }
               element selected.normal { background-color: #1a1d3d;
                           border-color: #7fc8ff; }
               element-text { background-color: transparent; text-color: #f0f0f8;
                           font: "JetBrainsMono Nerd Font 14"; }
             ')

    case "$CHOICE" in
      *Lock)     swaylock ;;
      *Logout)   niri msg action quit ;;
      *Reboot)   systemctl reboot ;;
      *Shutdown) systemctl poweroff ;;
    esac
  '';

in {
  home.packages = [rofi-launcher rofi-power];

  programs.rofi = {
    enable  = true;
    package = pkgs.rofi;
    terminal = "${pkgs.alacritty}/bin/alacritty";

    extraConfig = {
      modi                = "drun";
      show-icons          = true;
      icon-theme          = "Papirus";
      drun-display-format = "{name}";
      display-drun        = "  ";
      disable-history     = false;
      hide-scrollbar      = true;
      steal-focus         = true;
    };

    theme = ./niri/rofi/theme.rasi;
  };
}
