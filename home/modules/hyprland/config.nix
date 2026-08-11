#
# ~/.nixos/home/modules/hyprland/config.nix
#
# Lua config format (Hyprland 0.55+). hyprlang/.conf is removed in 0.57.
#
# Split of concerns:
#   settings    — data-shaped calls home-manager renders as hl.<name>(...):
#                 config, env, monitor, workspace_rule, window_rule.
#   extraConfig — raw Lua, appended last. Holds curves/animations (which must
#                 be defined in order — settings renders alphabetically, so
#                 `animation` would emit before `curve` and fail on an
#                 undefined bezier) and binds (dispatchers are Lua objects,
#                 so expressing them through settings needs mkLuaInline
#                 anyway — plain Lua reads better).
#
# Every construct here was validated with `Hyprland --verify-config`.
#
{ pkgs, inputs, ... }: {
  home.packages = [
    inputs.snappy-switcher.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];

  wayland.windowManager.hyprland = {
    enable = true;
    configType = "lua";

    # Export Hyprland env vars into the systemd user session so that
    # ConditionEnvironment = HYPRLAND_INSTANCE_SIGNATURE gates work.
    systemd = {
      enable = true;
      variables = [ "--all" ];
    };

    settings = {
      # `output = ""` is the catch-all monitor (hyprlang's leading empty field).
      monitor = {
        output = "";
        mode = "preferred";
        position = "auto";
        scale = 1;
      };

      # Each entry is a multi-argument hl.env(NAME, VALUE) call.
      env = [
        { _args = [ "XCURSOR_SIZE" "24" ]; }
        { _args = [ "HYPRCURSOR_SIZE" "24" ]; }
        # NVIDIA: disable hardware cursor planes — avoids a ~15 s DRM init
        # timeout that delays the first frame. Harmless on AMD.
        { _args = [ "WLR_NO_HARDWARE_CURSORS" "1" ]; }
        { _args = [ "NIXOS_OZONE_WL" "1" ]; }
        { _args = [ "ELECTRON_OZONE_PLATFORM_HINT" "auto" ]; }
        # NVIDIA GPU vars (LIBVA_DRIVER_NAME, NVD_BACKEND, GBM_BACKEND,
        # __GLX_VENDOR_LIBRARY_NAME) are set per-host in home/hosts/fulcrum.nix.
      ];

      # One hl.config{...} call. dwindle/scrolling are top-level keys, not
      # nested under `layout` — `layout` there is the *name* of the layout.
      config = {
        general = {
          gaps_in = 4;
          gaps_out = 8;
          border_size = 2;
          # Gradients are { colors = [...], angle = N }, not a hyprlang string.
          "col.active_border" = {
            colors = [ "rgba(e2e2e2ee)" "rgba(ffffffff)" ];
            angle = 45;
          };
          "col.inactive_border" = "rgba(39393988)";
          layout = "scrolling";
          allow_tearing = true; # tearing opt-in per window via "immediate" rule
        };

        scrolling = {
          column_width = 1.0; # each column = full screen width
          fullscreen_on_one_column = true;
          focus_fit_method = 1; # fit (not center) when focusing
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

        animations.enabled = true;

        dwindle.preserve_split = true;

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
      };

      # Workspace names and per-workspace settings.
      workspace_rule = [
        { workspace = "1"; default_name = "web"; }
        { workspace = "2"; default_name = "term"; layout = "dwindle"; }
        { workspace = "3"; default_name = "work"; }
        # No gaps on 4 — games are fullscreen.
        { workspace = "4"; default_name = "game"; gaps_in = 0; gaps_out = 0; }
      ];

      # Window rules. "silent" on workspace assignments = don't auto-switch
      # when the app opens.
      window_rule = [
        # ── Workspace assignments ──────────────────────────────────────────
        {
          name = "ws1-browser";
          match.class = "yandex-browser-beta|firefox";
          workspace = "1 silent";
        }
        {
          name = "ws2-terminal";
          match.class = "Alacritty";
          workspace = "2 silent";
        }
        {
          name = "ws4-launchers";
          match.class = "steam|net\\.lutris\\.Lutris|heroic";
          workspace = "4 silent";
        }
        # Steam/Proton game windows: workspace + all gaming tweaks in one rule
        {
          name = "ws4-games";
          match.class = "steam_app_";
          workspace = "4 silent";
          fullscreen = true;
          immediate = true; # allow tearing (requires allow_tearing = true)
          idle_inhibit = "always"; # no screensaver / lock mid-game
        }
        # Steam popup dialogs (news, guard, friends) float over the tiled layout
        {
          name = "steam-dialogs";
          match = {
            class = "steam";
            title = "Steam - News|Steam Guard|Friends List";
          };
          float = true;
          center = 1;
        }

        # ── Scratchpads ────────────────────────────────────────────────────
        {
          name = "scratchpad-term";
          match.class = "scratchterm";
          float = true;
          size = "80% 60%";
          center = 1;
          workspace = "special:term silent";
        }
        {
          name = "scratchpad-tasks";
          match.class = "scratchtask";
          float = true;
          size = "70% 50%";
          center = 1;
          workspace = "special:tasks silent";
        }

        # ── Calculator — float centered ────────────────────────────────────
        {
          name = "calculator-float";
          match.class = "org.gnome.Calculator";
          float = true;
          center = 1;
        }

        # ── Browser file pickers (Yandex/Chrome XWayland) ──────────────────
        # Yandex/Chrome set _NET_WM_WINDOW_TYPE_DIALOG on file pickers, so they
        # float — but the browser sizes them ~fullscreen and pins to (0,0).
        # Constrain + center so upload/download dialogs land in the middle.
        {
          name = "browser-file-dialog";
          match = {
            class = "Yandex-browser-beta|google-chrome";
            float = true;
          };
          size = "60% 70%";
          center = 1;
        }

        # ── Dolphin — slight transparency ──────────────────────────────────
        {
          name = "dolphin-opacity";
          match.class = "org.kde.dolphin";
          opacity = "0.9 override 0.85 override";
        }

        # ── Global sanity rules ────────────────────────────────────────────
        {
          name = "suppress-maximize-events";
          match.class = ".*";
          suppress_event = "maximize";
        }
        {
          name = "fix-xwayland-drags";
          match = {
            class = "^$";
            title = "^$";
            xwayland = true;
            float = true;
            fullscreen = false;
            pin = false;
          };
          no_focus = true;
        }
      ];
    };

    extraConfig = ''
      local mod = "SUPER"

      -- ── Curves and animations ───────────────────────────────────────────
      -- Curves first: hl.animation resolves the bezier by name at call time.
      hl.curve("easeOut", { type = "bezier", points = { {0.16, 1}, {0.3, 1} } })
      hl.curve("easeIn",  { type = "bezier", points = { {0.4, 0}, {1, 1} } })

      hl.animation{ leaf = "windows",    enabled = true, speed = 5,  bezier = "easeOut" }
      hl.animation{ leaf = "windowsOut", enabled = true, speed = 5,  bezier = "easeIn", style = "popin 80%" }
      hl.animation{ leaf = "border",     enabled = true, speed = 10, bezier = "default" }
      hl.animation{ leaf = "fade",       enabled = true, speed = 7,  bezier = "default" }
      hl.animation{ leaf = "workspaces", enabled = true, speed = 6,  bezier = "easeOut", style = "fade" }

      -- ── Startup ─────────────────────────────────────────────────────────
      -- hyprlang's exec-once. hyprlock on boot is flanker-only (auto-login,
      -- no greeter); on fulcrum SDDM already authenticates.
      hl.on("hyprland.start", function()
        hl.exec_cmd("awww-daemon")                          -- wallpaper daemon
        hl.exec_cmd("awww img ~/.config/background")         -- initial wallpaper
        hl.exec_cmd("wayle shell")                           -- panel + notifications
        hl.exec_cmd("hypridle")                              -- lock 5 min, DPMS 10 min
        hl.exec_cmd("snappy-switcher --daemon")              -- animated Alt+Tab
        hl.exec_cmd("hyprsunset -t 4500")                    -- blue light filter
        hl.exec_cmd("alacritty --class scratchterm")
        hl.exec_cmd("alacritty --class scratchtask -e taskwarrior-tui")
      end)

      -- ── Apps ────────────────────────────────────────────────────────────
      hl.bind(mod .. " + Return",    hl.dsp.exec_cmd("alacritty"))
      hl.bind(mod .. " + E",         hl.dsp.exec_cmd("dolphin"))
      hl.bind(mod .. " + SPACE",     hl.dsp.exec_cmd("fuzzel"))
      hl.bind(mod .. " + SHIFT + Q", hl.dsp.exec_cmd("rofi-power"))
      hl.bind(mod .. " + M",         hl.dsp.exec_cmd("missioncenter"))

      -- ── Window management ───────────────────────────────────────────────
      hl.bind(mod .. " + Q", hl.dsp.window.close())
      hl.bind(mod .. " + F", hl.dsp.window.fullscreen(1))
      -- Send focused window off-screen — manual way to hide phantom windows
      -- (e.g. eSpremnica's leftover blank shell after login). Move it back via
      -- a workspace switch, or kill it with mod+Q if unneeded.
      hl.bind(mod .. " + H", hl.dsp.window.move{ x = -9999, y = -9999 })

      -- ── Lock ────────────────────────────────────────────────────────────
      hl.bind(mod .. " + L", hl.dsp.exec_cmd("hyprlock"))

      -- ── Focus ───────────────────────────────────────────────────────────
      hl.bind(mod .. " + left",  hl.dsp.focus{ direction = "left" })
      hl.bind(mod .. " + right", hl.dsp.focus{ direction = "right" })
      hl.bind(mod .. " + up",    hl.dsp.focus{ direction = "up" })
      hl.bind(mod .. " + down",  hl.dsp.focus{ direction = "down" })

      -- ── Alt+Tab switcher (snappy-switcher) ──────────────────────────────
      hl.bind("ALT + Tab",         hl.dsp.exec_cmd("snappy-switcher next"))
      hl.bind("ALT + SHIFT + Tab", hl.dsp.exec_cmd("snappy-switcher prev"))

      -- ── Move windows ────────────────────────────────────────────────────
      hl.bind(mod .. " + SHIFT + left",  hl.dsp.window.move{ direction = "left" })
      hl.bind(mod .. " + SHIFT + right", hl.dsp.window.move{ direction = "right" })
      hl.bind(mod .. " + SHIFT + up",    hl.dsp.window.move{ direction = "up" })
      hl.bind(mod .. " + SHIFT + down",  hl.dsp.window.move{ direction = "down" })

      -- ── Scrolling layout ────────────────────────────────────────────────
      hl.bind(mod .. " + comma",        hl.dsp.layout("swapcol l"))
      hl.bind(mod .. " + period",       hl.dsp.layout("swapcol r"))
      hl.bind(mod .. " + bracketleft",  hl.dsp.layout("colresize -conf"))
      hl.bind(mod .. " + bracketright", hl.dsp.layout("colresize +conf"))

      -- ── Workspaces ──────────────────────────────────────────────────────
      for i = 1, 9 do
        hl.bind(mod .. " + " .. i,            hl.dsp.focus{ workspace = i })
        hl.bind(mod .. " + SHIFT + " .. i,    hl.dsp.window.move{ workspace = i })
      end
      hl.bind(mod .. " + 0",         hl.dsp.focus{ workspace = 10 })
      hl.bind(mod .. " + SHIFT + 0", hl.dsp.window.move{ workspace = 10 })

      -- ── Scratchpad ──────────────────────────────────────────────────────
      hl.bind("cedilla",             hl.dsp.workspace.toggle_special("term"))
      hl.bind(mod .. " + T",         hl.dsp.workspace.toggle_special("tasks"))
      hl.bind(mod .. " + S",         hl.dsp.workspace.toggle_special("magic"))
      hl.bind(mod .. " + SHIFT + S", hl.dsp.window.move{ workspace = "special:magic" })

      -- ── Screenshot ──────────────────────────────────────────────────────
      -- Print = region → clipboard, mod+Print = full screen → clipboard
      hl.bind("Print",             hl.dsp.exec_cmd([[grim -g "$(slurp)" - | wl-copy]]))
      hl.bind(mod .. " + Print",   hl.dsp.exec_cmd("grim - | wl-copy"))

      -- ── Clipboard ───────────────────────────────────────────────────────
      hl.bind(mod .. " + V", hl.dsp.exec_cmd("rofi-clipboard"))

      -- ── Wallpaper ───────────────────────────────────────────────────────
      hl.bind(mod .. " + SHIFT + W", hl.dsp.exec_cmd("wallpaper-next"))

      -- ── Media keys ──────────────────────────────────────────────────────
      -- These called swayosd-client until df79e86 removed swayosd with the
      -- Niri stack, leaving six dead binds. Wayle draws its own OSD and is
      -- already what the bar's scroll bindings use, so no extra daemon.
      hl.bind("XF86AudioRaiseVolume",  hl.dsp.exec_cmd("wayle audio output-volume +5"))
      hl.bind("XF86AudioLowerVolume",  hl.dsp.exec_cmd("wayle audio output-volume -5"))
      hl.bind("XF86AudioMute",         hl.dsp.exec_cmd("wayle audio output-mute"))
      hl.bind("XF86AudioMicMute",      hl.dsp.exec_cmd("wayle audio input-mute"))
      hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd("brightnessctl set +5%"))
      hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl set 5%-"))
      hl.bind("XF86Calculator",        hl.dsp.exec_cmd("gnome-calculator"))

      -- ── Mouse binds (hold modifier + drag) ──────────────────────────────
      hl.bind(mod .. " + mouse:272", hl.dsp.window.drag())
      hl.bind(mod .. " + mouse:273", hl.dsp.window.resize())
    '';
  };
}
