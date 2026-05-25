#
# ~/.nixos/home/modules/hyprland/config.nix
#
{ ... }: {
  wayland.windowManager.hyprland = {
    enable = true;

    # Export Hyprland env vars into the systemd user session so that
    # ConditionEnvironment = HYPRLAND_INSTANCE_SIGNATURE gates work.
    systemd = {
      enable = true;
      variables = [ "--all" ];
    };

    settings = {
      monitor = ",preferred,auto,1";

      "$mainMod" = "SUPER";

      env = [
        "XCURSOR_SIZE,24"
        "HYPRCURSOR_SIZE,24"
        # NVIDIA: disable hardware cursor planes — avoids a ~15 s DRM init
        # timeout that delays the first frame (and thus all exec-once apps).
        "WLR_NO_HARDWARE_CURSORS,1"
        "LIBVA_DRIVER_NAME,nvidia"
        "NVD_BACKEND,direct"
      ];

      general = {
        gaps_in = 4;
        gaps_out = 8;
        border_size = 2;
        "col.active_border" = "rgba(7fc8ffee) rgba(22d4e0ee) 45deg";
        "col.inactive_border" = "rgba(3c3c6eaa)";
        layout = "dwindle";
        allow_tearing = true;   # tearing opt-in per window via "immediate" rule
      };

      decoration = {
        rounding = 10;
        blur = {
          enabled = true;
          size = 8;
          passes = 2;
        };
        shadow = {
          enabled = true;
          range = 4;
          render_power = 3;
          color = "rgba(1a1a2eee)";
        };
      };

      animations = {
        enabled = true;
        bezier = [
          "easeOut, 0.16, 1, 0.3, 1"
          "easeIn,  0.4,  0, 1,   1"
        ];
        animation = [
          "windows,    1, 5, easeOut"
          "windowsOut, 1, 5, easeIn, popin 80%"
          "border,     1, 10, default"
          "fade,       1, 7, default"
          "workspaces, 1, 6, easeOut"
        ];
      };

      dwindle = {
        pseudotile = true;
        preserve_split = true;
      };

      # Workspace names and per-workspace settings
      workspace = [
        "1, name:web"
        "2, name:term"
        "3, name:work"
        "4, name:game, gapsin:0, gapsout:0"   # no gaps — games are fullscreen
      ];


      exec-once = [
        "swww-daemon"                                    # wallpaper daemon
        "swww img ~/.config/background"                  # set initial wallpaper
        "hyprpanel"    # launch directly — avoids systemd env-propagation delay
        "hypridle"     # idle daemon — lock at 5 min, monitors off at 10 min
      ];

      misc = {
        force_default_wallpaper = 0;
        disable_hyprland_logo = true;
      };

      input = {
        kb_layout = "si";
        follow_mouse = 1;
        sensitivity = 0;
        touchpad = {
          natural_scroll = true;
          disable_while_typing = true;
        };
      };

      bind = [
        # ── Apps ────────────────────────────────────────────────────────────
        "$mainMod, Return,  exec, alacritty"
        "$mainMod, T,       exec, alacritty"
        "$mainMod, E,       exec, dolphin"
        "SUPER,    SPACE,   exec, fuzzel"
        "$mainMod SHIFT, Q, exec, rofi-power"
        "$mainMod, M,       exec, missioncenter"

        # ── Window management ───────────────────────────────────────────────
        "$mainMod, Q,       killactive,"
        "$mainMod, V,       togglefloating,"
        "$mainMod, F,       fullscreen, 0"
        "$mainMod, P,       pseudo,"          # dwindle pseudotile
        "$mainMod, J,       togglesplit,"     # dwindle split direction

        # ── Lock ────────────────────────────────────────────────────────────
        "$mainMod, L,       exec, hyprlock"

        # ── Focus ───────────────────────────────────────────────────────────
        "$mainMod, left,    movefocus, l"
        "$mainMod, right,   movefocus, r"
        "$mainMod, up,      movefocus, u"
        "$mainMod, down,    movefocus, d"

        # ── Move windows ────────────────────────────────────────────────────
        "$mainMod SHIFT, left,  movewindow, l"
        "$mainMod SHIFT, right, movewindow, r"
        "$mainMod SHIFT, up,    movewindow, u"
        "$mainMod SHIFT, down,  movewindow, d"

        # ── Workspaces ──────────────────────────────────────────────────────
        "$mainMod, 1, workspace, 1"
        "$mainMod, 2, workspace, 2"
        "$mainMod, 3, workspace, 3"
        "$mainMod, 4, workspace, 4"
        "$mainMod, 5, workspace, 5"
        "$mainMod, 6, workspace, 6"
        "$mainMod, 7, workspace, 7"
        "$mainMod, 8, workspace, 8"
        "$mainMod, 9, workspace, 9"
        "$mainMod, 0, workspace, 10"

        "$mainMod SHIFT, 1, movetoworkspace, 1"
        "$mainMod SHIFT, 2, movetoworkspace, 2"
        "$mainMod SHIFT, 3, movetoworkspace, 3"
        "$mainMod SHIFT, 4, movetoworkspace, 4"
        "$mainMod SHIFT, 5, movetoworkspace, 5"
        "$mainMod SHIFT, 6, movetoworkspace, 6"
        "$mainMod SHIFT, 7, movetoworkspace, 7"
        "$mainMod SHIFT, 8, movetoworkspace, 8"
        "$mainMod SHIFT, 9, movetoworkspace, 9"
        "$mainMod SHIFT, 0, movetoworkspace, 10"

        # ── Scratchpad ──────────────────────────────────────────────────────
        "$mainMod,       S, togglespecialworkspace, magic"
        "$mainMod SHIFT, S, movetoworkspace, special:magic"

        # ── Screenshot ──────────────────────────────────────────────────────
        # Print = region screenshot → clipboard
        # Super+Print = full screen → clipboard
        ",        Print, exec, grim -g \"$(slurp)\" - | wl-copy"
        "$mainMod, Print, exec, grim - | wl-copy"

        # ── Clipboard ───────────────────────────────────────────────────────
        "$mainMod, C, exec, rofi-clipboard"

        # ── Wallpaper ───────────────────────────────────────────────────────
        "$mainMod SHIFT, W, exec, wallpaper-next"

        # ── Media keys ──────────────────────────────────────────────────────
        ", XF86AudioRaiseVolume,  exec, swayosd-client --output-volume raise"
        ", XF86AudioLowerVolume,  exec, swayosd-client --output-volume lower"
        ", XF86AudioMute,         exec, swayosd-client --output-volume mute-toggle"
        ", XF86AudioMicMute,      exec, swayosd-client --input-volume mute-toggle"
        ", XF86MonBrightnessUp,   exec, swayosd-client --brightness raise"
        ", XF86MonBrightnessDown, exec, swayosd-client --brightness lower"
        ", XF86Calculator,        exec, gnome-calculator"
      ];

      # Mouse binds (hold modifier + drag)
      bindm = [
        "$mainMod, mouse:272, movewindow"
        "$mainMod, mouse:273, resizewindow"
      ];

    };

    # Window rules use the 0.45+ block syntax — not serialisable through the
    # settings attrset, so written as raw extraConfig.
    # "silent" on workspace assignments = don't auto-switch when the app opens.
    extraConfig = ''
      # ── Workspace assignments ──────────────────────────────────────────────
      windowrule {
          name = ws1-browser
          match:class = yandex-browser-beta|firefox
          workspace = 1 silent
      }

      windowrule {
          name = ws2-terminal
          match:class = Alacritty
          workspace = 2 silent
      }

      windowrule {
          name = ws4-launchers
          match:class = steam|net\.lutris\.Lutris|heroic
          workspace = 4 silent
      }

      # Steam/Proton game windows: workspace + all gaming tweaks in one block
      windowrule {
          name = ws4-games
          match:class = steam_app_

          workspace    = 4 silent
          fullscreen   = true
          immediate    = true       # allow tearing (requires allow_tearing = true)
          idle_inhibit = always     # no screensaver / lock mid-game
      }

      # Steam popup dialogs (news, guard, friends) float over the tiled layout
      windowrule {
          name = steam-dialogs
          match:class = steam
          match:title = Steam - News|Steam Guard|Friends List

          float  = true
          center = 1
      }

      # ── Global sanity rules ────────────────────────────────────────────────
      windowrule {
          name = suppress-maximize-events
          match:class = .*
          suppress_event = maximize
      }

      windowrule {
          name = fix-xwayland-drags
          match:class      = ^$
          match:title      = ^$
          match:xwayland   = true
          match:float      = true
          match:fullscreen = false
          match:pin        = false
          no_focus = true
      }
    '';
  };
}
