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
    text-color:       white;
    background-color: #0d0e1f;
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
        0)  echo "$PICK" | cliphist decode | wl-copy; exit 0 ;;
        10) echo "$PICK" | cliphist delete ;;
        *)  exit 0 ;;
      esac
    done
  '';

  # ── Scratchpad terminal (spawn or focus) ──────────────────────────────────
  scratchpad = pkgs.writeShellScriptBin "scratchpad" ''
    WIN_ID=$(niri msg windows 2>/dev/null \
      | ${pkgs.jq}/bin/jq -r '.[] | select(.app_id == "scratchpad") | .id' \
      | head -1)
    if [ -n "$WIN_ID" ]; then
      niri msg action focus-window --id "$WIN_ID"
    else
      alacritty --class scratchpad &
    fi
  '';

  # ── Wallpaper cycler ───────────────────────────────────────────────────────
  wallpaper-next = pkgs.writeShellScriptBin "wallpaper-next" ''
    DIR="$HOME/Slike/Wallpapers"
    if [ ! -d "$DIR" ] || [ -z "$(ls "$DIR"/*.{jpg,jpeg,png,webp} 2>/dev/null)" ]; then
      exit 0
    fi
    NEXT=$(ls "$DIR"/*.{jpg,jpeg,png,webp} 2>/dev/null | shuf -n1)
    pkill swaybg 2>/dev/null; sleep 0.1
    ${pkgs.swaybg}/bin/swaybg -i "$NEXT" -m fill &
    echo "$NEXT" > /tmp/current-wallpaper
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
  home.packages = [rofi-launcher rofi-power rofi-clipboard scratchpad wallpaper-next];

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
