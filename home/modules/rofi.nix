#
# ~/.nixos/home/modules/rofi.nix
#
{pkgs, ...}: let

  # ── Launcher ──────────────────────────────────────────────────────────────
  rofi-launcher = pkgs.writeShellScriptBin "rofi-launcher" ''
    source ~/.config/theme/colors.sh 2>/dev/null || { BG="#1a0a0a"; FG="#e8d5d5"; }
    TIME=$(date '+%H:%M  ·  %A, %-d %B')

    TMPTHEME=$(mktemp /tmp/rofi-XXXXXX.rasi)
    trap "rm -f '$TMPTHEME'" EXIT
    cat > "$TMPTHEME" << RASI_EOF
@import "$HOME/.local/share/rofi/themes/theme.rasi"
textbox-clock {
    content:          "$TIME";
    font:             "Sans Bold 36";
    text-color:       ''${FG};
    background-color: ''${BG};
    horizontal-align: 0.5;
    padding:          0px 0px 20px 0px;
}
mainbox {
    children: [ textbox-clock, inputbar, listview ];
}
RASI_EOF
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
            case "$CLASS" in
              Alacritty|scratchterm|scratchtask)
                ${pkgs.wtype}/bin/wtype -M ctrl -M shift v -m shift -m ctrl ;;
              *.exe)
                # Wine apps: skip auto-paste. Synthetic Ctrl+V from wtype gets
                # translated through XWayland in a way that some WinForms apps
                # (e.g. eSpremnica) interpret as ESC → closes the form. Real
                # Ctrl+V works fine, so leave the entry on the clipboard and
                # let the user paste manually.
                : ;;
              *)
                ${pkgs.wtype}/bin/wtype -M ctrl v -m ctrl ;;
            esac
            exit 0 ;;
        10) echo "$PICK" | cliphist delete ;;
        *)  exit 0 ;;
      esac
    done
  '';

  # ── Power menu ────────────────────────────────────────────────────────────
  rofi-power = pkgs.writeShellScriptBin "rofi-power" ''
    source ~/.config/theme/colors.sh 2>/dev/null || { BG="#1a0a0a"; FG="#e8d5d5"; ACCENT="#c45454"; BG_ALT="#2a1215"; BG_SEL="#3d1e1e"; }
    CHOICE=$(printf "󰌾  Lock\n󰍃  Logout\n󰜉  Reboot\n⏻  Shutdown" \
      | rofi -dmenu \
             -p "  " \
             -theme-str "
               window   { width: 280px; border: 2px solid; border-color: ''${ACCENT};
                           border-radius: 16px; background-color: ''${BG}; }
               mainbox  { padding: 16px; }
               inputbar { background-color: ''${BG_ALT}; border-radius: 10px;
                           border: 1px solid; border-color: ''${ACCENT};
                           padding: 10px 14px; margin: 0px 0px 12px 0px;
                           children: [prompt]; }
               prompt   { background-color: transparent; text-color: ''${ACCENT};
                           font: \"Sans Bold 16\"; }
               entry    { background-color: transparent; text-color: ''${FG}; }
               listview { background-color: transparent; lines: 4;
                           scrollbar: false; spacing: 6px; }
               element  { background-color: ''${BG_ALT}; border-radius: 10px;
                           border: 1px solid; border-color: rgba(255,255,255,0.05);
                           padding: 12px 16px; cursor: pointer; }
               element selected.normal { background-color: ''${BG_SEL};
                           border-color: ''${ACCENT}; }
               element-text { background-color: transparent; text-color: ''${FG};
                           font: \"JetBrainsMono Nerd Font 14\"; }
             ")

    case "$CHOICE" in
      *Lock)     hyprlock ;;
      *Logout)   hyprctl dispatch exit ;;
      *Reboot)   systemctl reboot ;;
      *Shutdown) systemctl poweroff ;;
    esac
  '';

in {
  # wallpaper-next moved to theme.nix — it is a theming action, and it needs
  # the stored light/dark mode that theme-apply owns.
  home.packages = [rofi-launcher rofi-power rofi-clipboard];

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

    theme = ./rofi/theme.rasi;
  };
}
