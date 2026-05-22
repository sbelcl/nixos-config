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
      ];

      general = {
        gaps_in = 4;
        gaps_out = 8;
        border_size = 2;
        "col.active_border" = "rgba(7fc8ffee) rgba(22d4e0ee) 45deg";
        "col.inactive_border" = "rgba(3c3c6eaa)";
        layout = "dwindle";
        allow_tearing = false;
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

      gestures = {
        workspace_swipe = true;
        workspace_swipe_fingers = 3;
      };

      bind = [
        # ── Apps ────────────────────────────────────────────────────────────
        "$mainMod, Return,  exec, alacritty"
        "$mainMod, T,       exec, alacritty"
        "$mainMod, E,       exec, dolphin"
        "SUPER,    SPACE,   exec, rofi-launcher"
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

      windowrulev2 = [
        "suppressevent maximize, class:.*"
        # Ignore spurious unmanaged XWayland windows
        "nofocus, class:^$, title:^$, xwayland:1, floating:1, fullscreen:0, pinned:0"
      ];
    };
  };
}
