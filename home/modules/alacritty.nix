#
# ~/.nixos/home/modules/alacritty.nix
#
{pkgs, ...}: {
  programs.alacritty = {
    enable = true;

    settings = {
      window = {
        padding = { x = 16; y = 14; };
        opacity = 0.88;
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

      # Binary Red theme
      colors = {
        primary = {
          background = "#1a0a0a";
          foreground = "#e8d5d5";
          dim_foreground = "#887070";
          bright_foreground = "#fff0f0";
        };
        cursor = {
          text   = "#1a0a0a";
          cursor = "#c45454";
        };
        vi_mode_cursor = {
          text   = "#1a0a0a";
          cursor = "#d4797a";
        };
        selection = {
          text       = "CellForeground";
          background = "#3d1e1e";
        };
        normal = {
          black   = "#1c0e0e";
          red     = "#c45454";
          green   = "#7e9a6f";
          yellow  = "#d4a86a";
          blue    = "#7a8aa0";
          magenta = "#9d6088";
          cyan    = "#8a7070";
          white   = "#c0b0b0";
        };
        bright = {
          black   = "#4a2828";
          red     = "#d4797a";
          green   = "#9eaf8f";
          yellow  = "#f0c080";
          blue    = "#9aaccc";
          magenta = "#bb80a0";
          cyan    = "#a08888";
          white   = "#e8d8d8";
        };
        dim = {
          black   = "#110808";
          red     = "#a03838";
          green   = "#5a7a50";
          yellow  = "#a08040";
          blue    = "#506878";
          magenta = "#6a4060";
          cyan    = "#605050";
          white   = "#807070";
        };
      };

      terminal.shell = {
        program = "${pkgs.zsh}/bin/zsh";
      };
    };
  };
}
