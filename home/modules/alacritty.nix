#
# ~/.nixos/home/modules/alacritty.nix
#
{pkgs, ...}: {
  programs.alacritty = {
    enable = true;

    settings = {
      window = {
        padding = { x = 16; y = 14; };
        opacity = 0.92;
        blur = true;
        decorations = "None";         # no title bar — Niri handles window chrome
        dynamic_title = true;
      };

      font = {
        normal = { family = "JetBrainsMono Nerd Font"; style = "Regular"; };
        bold   = { family = "JetBrainsMono Nerd Font"; style = "Bold"; };
        italic = { family = "JetBrainsMono Nerd Font"; style = "Italic"; };
        size = 12.0;
        offset = { x = 0; y = 2; };       # slight extra line spacing
        builtin_box_drawing = true;
      };

      cursor = {
        style = { shape = "Block"; blinking = "On"; };
        blink_interval = 500;
        unfocused_hollow = true;
      };

      scrolling = {
        history = 10000;
        multiplier = 3;
      };

      # Dark theme — matches swayosd/swaync palette
      colors = {
        primary = {
          background = "#0e0e0e";
          foreground = "#d8d8d8";
          dim_foreground = "#888888";
          bright_foreground = "#ffffff";
        };
        cursor = {
          text   = "#0e0e0e";
          cursor = "#7fc8ff";
        };
        vi_mode_cursor = {
          text   = "#0e0e0e";
          cursor = "#a8d8f0";
        };
        selection = {
          text       = "CellForeground";
          background = "#2a3d52";
        };
        normal = {
          black   = "#1c1c1c";
          red     = "#dc5050";
          green   = "#7ec76f";
          yellow  = "#d4b96a";
          blue    = "#5bafd6";
          magenta = "#9d7cd8";
          cyan    = "#4fc1c9";
          white   = "#c0c0c0";
        };
        bright = {
          black   = "#444444";
          red     = "#ff7070";
          green   = "#9edf8f";
          yellow  = "#f0d080";
          blue    = "#7fc8ff";
          magenta = "#bb99ff";
          cyan    = "#6fe0e8";
          white   = "#e8e8e8";
        };
        dim = {
          black   = "#111111";
          red     = "#a03838";
          green   = "#5a9a50";
          yellow  = "#a08840";
          blue    = "#3d7fa0";
          magenta = "#6a50a0";
          cyan    = "#308890";
          white   = "#808080";
        };
      };

      terminal.shell = {
        program = "${pkgs.zsh}/bin/zsh";
      };
    };
  };
}
