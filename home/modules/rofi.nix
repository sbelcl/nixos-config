#
# ~/.nixos/home/modules/rofi.nix
#
{pkgs, ...}: let

  # ── Launcher ──────────────────────────────────────────────────────────────
  rofi-launcher = pkgs.writeShellScriptBin "rofi-launcher" ''
    TIME=$(date '+%H:%M  ·  %A, %-d %B')

    TMPTHEME=$(mktemp /tmp/rofi-XXXXXX.rasi)
    trap "rm -f '$TMPTHEME'" EXIT
    cat > "$TMPTHEME" << EOF
@import "$HOME/.local/share/rofi/themes/theme.rasi"
textbox-clock {
    content:          "$TIME";
    font:             "Sans Bold 36";
    text-color:       #e8d5d5;
    background-color: #1a0a0a;
    horizontal-align: 0.5;
    padding:          0px 0px 20px 0px;
}
mainbox {
    children: [ textbox-clock, inputbar, listview ];
}
EOF
    exec rofi -show drun -theme "$TMPTHEME"
  '';

  # ── Clipboard picker ──────────────────────────────────────────────────────
  rofi-clipboard = pkgs.writeShellScriptBin "rofi-clipboard" ''
    # Loop so Alt+Delete removes an entry and re-shows the list
    while true; do
      ENTRIES=$(cliphist list)
      [ -z "$ENTRIES" ] && exit 0

      PICK=$(echo "$ENTRIES" | rofi -dmenu \
        -p "󰅇" \
        -kb-custom-1 "Alt+Delete" \
        -theme-str '
          window   { width: 680px; }
          listview { lines: 12; columns: 1; dynamic: false; scrollbar: false; }
          element  { orientation: horizontal; spacing: 10px; }
          element-icon { size: 0px; }
        ')
      EXIT=$?

      [ -z "$PICK" ] && exit 0

      case $EXIT in
        0)  echo "$PICK" | cliphist decode | wl-copy
            sleep 0.1
            CLASS=$(hyprctl activewindow -j | ${pkgs.jq}/bin/jq -r '.class')
            if [ "$CLASS" = "Alacritty" ] || [ "$CLASS" = "scratchterm" ] || [ "$CLASS" = "scratchtask" ]; then
              ${pkgs.wtype}/bin/wtype -M ctrl -M shift v -m shift -m ctrl
            else
              ${pkgs.wtype}/bin/wtype -M ctrl v -m ctrl
            fi
            exit 0 ;;
        10) echo "$PICK" | cliphist delete ;;
        *)  exit 0 ;;
      esac
    done
  '';

  # ── Wallpaper cycler ───────────────────────────────────────────────────────
  wallpaper-next = pkgs.writeShellScriptBin "wallpaper-next" ''
    DIR="$HOME/Slike/Wallpapers"
    if [ ! -d "$DIR" ] || [ -z "$(ls "$DIR"/*.{jpg,jpeg,png,webp} 2>/dev/null)" ]; then
      exit 0
    fi
    NEXT=$(ls "$DIR"/*.{jpg,jpeg,png,webp} 2>/dev/null | shuf -n1)
    if [ -n "$NIRI_SOCKET" ]; then
      pkill swaybg 2>/dev/null; sleep 0.1
      ${pkgs.swaybg}/bin/swaybg -i "$NEXT" -m fill &
    elif [ -n "$HYPRLAND_INSTANCE_SIGNATURE" ]; then
      hyprctl hyprpaper preload "$NEXT"
      hyprctl hyprpaper wallpaper ",$NEXT"
    fi
    echo "$NEXT" > /tmp/current-wallpaper
  '';

  # ── Power menu ────────────────────────────────────────────────────────────
  rofi-power = pkgs.writeShellScriptBin "rofi-power" ''
    CHOICE=$(printf "󰌾  Lock\n󰍃  Logout\n󰜉  Reboot\n⏻  Shutdown" \
      | rofi -dmenu \
             -p "  " \
             -theme-str '
               window   { width: 280px; border: 4px solid; border-color: #c45454;
                           border-radius: 16px; background-color: #1a0a0a; }
               mainbox  { padding: 16px; }
               inputbar { background-color: #2a1215; border-radius: 10px;
                           border: 1px solid; border-color: rgba(196,84,84,0.3);
                           padding: 10px 14px; margin: 0px 0px 12px 0px;
                           children: [prompt]; }
               prompt   { background-color: transparent; text-color: #c45454;
                           font: "Sans Bold 16"; }
               entry    { background-color: transparent; text-color: #e8d5d5; }
               listview { background-color: transparent; lines: 4;
                           scrollbar: false; spacing: 6px; }
               element  { background-color: #2a1215; border-radius: 10px;
                           border: 1px solid; border-color: rgba(255,255,255,0.05);
                           padding: 12px 16px; cursor: pointer; }
               element selected.normal { background-color: #3d1e1e;
                           border-color: #c45454; }
               element-text { background-color: transparent; text-color: #e8d5d5;
                           font: "JetBrainsMono Nerd Font 14"; }
             ')

    case "$CHOICE" in
      *Lock)
        if   [ -n "$NIRI_SOCKET" ];                    then swaylock
        elif [ -n "$HYPRLAND_INSTANCE_SIGNATURE" ];    then hyprlock
        fi ;;
      *Logout)
        if   [ -n "$NIRI_SOCKET" ];                    then niri msg action quit
        elif [ -n "$HYPRLAND_INSTANCE_SIGNATURE" ];    then hyprctl dispatch exit
        fi ;;
      *Reboot)   systemctl reboot ;;
      *Shutdown) systemctl poweroff ;;
    esac
  '';

in {
  home.packages = [rofi-launcher rofi-power rofi-clipboard wallpaper-next];

  programs.rofi = {
    enable  = true;
    package = pkgs.rofi;
    terminal = "${pkgs.alacritty}/bin/alacritty";

    extraConfig = {
      modi                   = "drun";
      show-icons             = true;
      icon-theme             = "Papirus";
      drun-display-format    = "{name}";
      display-drun           = "  ";
      disable-history        = false;
      hide-scrollbar         = true;
      steal-focus            = true;
      drun-use-desktop-cache = true;
    };

    theme = ./niri/rofi/theme.rasi;
  };
}
