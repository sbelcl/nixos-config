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
#                 undefined bezier), the startup block, and the generated
#                 keybinds (dispatchers are Lua objects, so expressing them
#                 through settings needs mkLuaInline anyway — plain Lua
#                 reads better).
#
# Binds themselves are not written here: they live as data in binds.nix, which
# also renders the SUPER+ALT+SPACE menu, the SUPER+K cheatsheet and
# docs/keybindings.md.
#
# Every construct here was validated with `Hyprland --verify-config`.
#
{ pkgs, inputs, ... }: let
  binds = import ./binds.nix;

  # Select a screen region, OCR it, put the text on the clipboard.
  #
  # slv+eng, in that order: tesseract weights the first language highest, and
  # the Slovenian model is the one that knows š/č/ž — running eng-only on
  # Slovenian text silently mangles them into s/c/z rather than failing. eng
  # follows because most of what gets grabbed off a screen is English UI text
  # or code. pkgs.tesseract ships every traineddata file, so neither needs
  # requesting separately.
  #
  # Writing grim's output to a file instead of piping it: tesseract seeks
  # its input, so it cannot read a pipe, and `tesseract - -` fails on stdin
  # that isn't a real file.
  ocr-region = pkgs.writeShellScriptBin "ocr-region" ''
    set -euo pipefail

    # slurp exits non-zero when the selection is cancelled (Escape or a
    # zero-width drag). Leave silently — a notification there would fire on
    # every mis-drag.
    region=$(${pkgs.slurp}/bin/slurp) || exit 0

    img=$(mktemp --suffix=.png)
    trap 'rm -f "$img"' EXIT
    ${pkgs.grim}/bin/grim -g "$region" "$img"

    # tesseract writes progress to stderr and exits non-zero on an empty
    # image; treat "no text" as a normal outcome, not a crash.
    text=$(${pkgs.tesseract}/bin/tesseract "$img" - -l slv+eng 2>/dev/null || true)

    # Strip surrounding whitespace: tesseract always appends newlines, and
    # pasting those into a chat box sends the message early. Escaped as
    # ''${ so Nix leaves the parameter expansion for bash instead of trying
    # to interpolate `text` at build time.
    shopt -s extglob
    text="''${text##+([[:space:]])}"
    text="''${text%%+([[:space:]])}"

    if [ -z "$text" ]; then
      ${pkgs.libnotify}/bin/notify-send -u normal "OCR" "No text found in selection"
      exit 0
    fi

    printf '%s' "$text" | ${pkgs.wl-clipboard}/bin/wl-copy
    ${pkgs.libnotify}/bin/notify-send "Text extracted" "$(printf '%s' "$text" | head -c 120)"
  '';
in {
  home.packages = [
    inputs.snappy-switcher.packages.${pkgs.stdenv.hostPlatform.system}.default
    ocr-region
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
      #
      # `size` is absolute pixels, sized for this laptop's 1920x1080 eDP-1.
      # Percentages are NOT usable here: Hyprland 0.56.1's lua path accepts
      # "80% 60%", {"80%","60%"}, {0.8,0.6} and "80%w 60%h" through
      # --verify-config and then silently ignores every one of them — only a
      # two-number vec2 actually applies. Verified with `hyprctl eval`. These
      # will be wrong on an external monitor of a different resolution; revisit
      # if percentages start working upstream.
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
          size = [ 1536 648 ];  # 80% x 60% of 1920x1080
          center = 1;
          workspace = "special:term silent";
        }
        {
          name = "scratchpad-tasks";
          match.class = "scratchtask";
          float = true;
          size = [ 1344 540 ];  # 70% x 50%
          center = 1;
          workspace = "special:tasks silent";
        }

        # ── Keybinding cheatsheet (SUPER+K) — float centered ───────────────
        {
          name = "cheatsheet-float";
          match.class = "cheatsheet";
          float = true;
          size = [ 1100 860 ];  # tall enough for a whole category at once
          center = 1;
        }

        # ── Calculator — float centered ────────────────────────────────────
        {
          name = "calculator-float";
          match.class = "org.gnome.Calculator";
          float = true;
          center = 1;
        }

        # ranger deliberately has no rule. It ran floating until opening an
        # image proved the point: xdg-open launches the viewer into the tiled
        # layout, where the floating ranger covered it. Tiled, they sit side by
        # side. The --class ranger it is launched with still matters though —
        # without it the ws2-terminal rule above would match its Alacritty
        # class and yank every ranger window to workspace 2.

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
          size = [ 1152 756 ];  # 60% x 70%
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
        hl.exec_cmd("alacritty --class scratchterm")
        hl.exec_cmd("alacritty --class scratchtask -e taskwarrior-tui")
      end)

      -- ── Keybinds ───────────────────────────────────────────────────────
      -- Generated from hyprland/binds.nix, which is also what the SUPER+K
      -- cheatsheet, the SUPER+ALT+SPACE menu and docs/keybindings.md are
      -- rendered from. Add or change a bind there, not here.
${binds.lua}
    '';
  };
}
