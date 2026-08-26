#
# ~/.nixos/home/modules/hyprland/binds.nix
#
# Every Hyprland keybind, as data. Three artefacts are generated from this one
# list, so they cannot drift apart:
#
#   lua           → the hl.bind() calls appended to hyprland.lua   (config.nix)
#   menuTsv       → the SUPER+ALT+SPACE action menu                (menu.nix)
#   docsMarkdown  → docs/keybindings.md *and* the SUPER+K cheatsheet
#
# docs/keybindings.md is checked in rather than written at activation: nothing
# in this config writes into ~/.nixos (nixos-update-check.nix explains what
# that cost last time). Regenerate it after editing this file:
#
#   nix eval --raw -f home/modules/hyprland/binds.nix docsMarkdown > docs/keybindings.md
#
# Hence plain Nix — no module arguments, no lib, only builtins — so that
# command works from a bare checkout without evaluating home-manager.
#
# Entry fields (only `desc` and `category` are required):
#
#   keys      combo, spelled exactly as hl.bind() wants it. null means a
#             documentation-only row: nothing is bound, used to fold a
#             generated family (the workspace keys) into one readable line.
#   desc      what it does — one imperative line.
#   category  grouping; must appear in `categories` below, which also fixes
#             the order everything is rendered in.
#   exec      shell command → hl.dsp.exec_cmd(...). Also what the menu runs,
#             so an exec entry is menu-listed unless `menu = false`.
#   lua       raw Lua dispatcher expression, for everything that isn't exec.
#   opts      Lua table for hl.bind's third argument (e.g. release).
#   label     display override for docs/menu — mouse buttons and key ranges
#             that read badly in their bindable spelling.
#   menu      override the "exec entries are menu-listed" default.
#   doc       false hides the row from the docs and the cheatsheet.
#
let
  concat = builtins.concatStringsSep;

  defaults = {
    keys = null;
    exec = null;
    lua = null;
    opts = null;
    label = null;
    doc = true;
  };

  # `menu` and `display` are derived after merging, so they can key off the
  # entry's own defaulted fields.
  norm = b: let e = defaults // b; in e // {
    menu = if b ? menu then b.menu else e.exec != null;
    display = if e.label != null then e.label else e.keys;
  };

  # Workspace 10 lives on the 0 key. Generated rather than written out
  # twenty times — and the documentation row below derives its key range
  # from this same list, so the two cannot disagree.
  wsPairs = builtins.genList (i: let n = i + 1; in {
    key = if n == 10 then "0" else toString n;
    ws = n;
  }) 10;

  wsFirst = (builtins.head wsPairs).key;
  wsLast = (builtins.elemAt wsPairs (builtins.length wsPairs - 1)).key;

  workspaceBinds = builtins.concatMap (p: [
    {
      keys = "SUPER + ${p.key}";
      lua = "hl.dsp.focus{ workspace = ${toString p.ws} }";
      desc = "Switch to workspace ${toString p.ws}";
      category = "Workspaces";
      doc = false;
    }
    {
      keys = "SUPER + SHIFT + ${p.key}";
      lua = "hl.dsp.window.move{ workspace = ${toString p.ws} }";
      desc = "Move window to workspace ${toString p.ws}";
      category = "Workspaces";
      doc = false;
    }
  ]) wsPairs;

  raw = [
    # ── Apps ────────────────────────────────────────────────────────────────
    { keys = "SUPER + Return"; exec = "alacritty"; desc = "Terminal"; category = "Apps"; }
    { keys = "SUPER + E"; exec = "nautilus"; desc = "File manager (Nautilus)"; category = "Apps"; }
    # Same --class udiskie's mount hook uses, so a USB mount and this bind
    # behave identically. See config.nix's window_rule list for why the class
    # is still needed now that ranger tiles.
    { keys = "SUPER + R"; exec = "alacritty --class ranger -e ranger ~"; desc = "File manager (ranger)"; category = "Apps"; }
    # Launching the launcher from the launcher is not a thing anyone needs.
    { keys = "SUPER + SPACE"; exec = "fuzzel"; desc = "App launcher"; category = "Apps"; menu = false; }
    { keys = "SUPER + M"; exec = "missioncenter"; desc = "System monitor"; category = "Apps"; }
    { keys = "XF86Calculator"; exec = "gnome-calculator"; desc = "Calculator"; category = "Apps"; }

    # ── Windows ─────────────────────────────────────────────────────────────
    { keys = "SUPER + Q"; lua = "hl.dsp.window.close()"; desc = "Close window"; category = "Windows"; }
    # Fullscreen family. hl.dsp.window.fullscreen only reads a *table* — a bare
    # number argument is silently ignored and you get the defaults (mode
    # "fullscreen", action "toggle"). This used to read `fullscreen(1)`, which
    # looked like "mode 1 = maximized" but was in fact plain fullscreen.
    { keys = "SUPER + F"; lua = ''hl.dsp.window.fullscreen{ mode = "fullscreen" }''; desc = "Fullscreen — no gaps, no bar"; category = "Windows"; }
    { keys = "SUPER + ALT + F"; lua = ''hl.dsp.window.fullscreen{ mode = "maximized" }''; desc = "Maximize — fills the workspace, keeps gaps and bar"; category = "Windows"; }
    # "Fake" fullscreen: the client is told it is fullscreen (so a video player
    # switches to its fullscreen UI) while the window stays exactly where it
    # is. internal 0 = leave the window alone, client 2 = FSMODE_FULLSCREEN,
    # per FullscreenController.hpp.
    { keys = "SUPER + CTRL + F"; lua = "hl.dsp.window.fullscreen_state{ internal = 0, client = 2, action = \"toggle\" }"; desc = "Fake fullscreen — client thinks it is fullscreen, window unmoved"; category = "Windows"; }
    # No table = toggle.
    { keys = "SUPER + SHIFT + F"; lua = "hl.dsp.window.float()"; desc = "Toggle floating"; category = "Windows"; }
    # Send the focused window off-screen — the manual way to hide phantom
    # windows (e.g. eSpremnica's leftover blank shell after login). Move it
    # back via a workspace switch, or kill it with SUPER+Q if unneeded.
    { keys = "SUPER + H"; lua = "hl.dsp.window.move{ x = -9999, y = -9999 }"; desc = "Hide window off-screen"; category = "Windows"; }

    # ── Focus ───────────────────────────────────────────────────────────────
    # The arrow family, where the modifier says how much moves:
    #   SUPER              focus          SUPER+SHIFT  the window
    #   SUPER+CTRL         the whole column
    { keys = "SUPER + left"; lua = ''hl.dsp.focus{ direction = "left" }''; desc = "Focus left"; category = "Focus"; }
    { keys = "SUPER + right"; lua = ''hl.dsp.focus{ direction = "right" }''; desc = "Focus right"; category = "Focus"; }
    { keys = "SUPER + up"; lua = ''hl.dsp.focus{ direction = "up" }''; desc = "Focus up"; category = "Focus"; }
    { keys = "SUPER + down"; lua = ''hl.dsp.focus{ direction = "down" }''; desc = "Focus down"; category = "Focus"; }
    { keys = "SUPER + SHIFT + left"; lua = ''hl.dsp.window.move{ direction = "left" }''; desc = "Move window left"; category = "Focus"; }
    { keys = "SUPER + SHIFT + right"; lua = ''hl.dsp.window.move{ direction = "right" }''; desc = "Move window right"; category = "Focus"; }
    { keys = "SUPER + SHIFT + up"; lua = ''hl.dsp.window.move{ direction = "up" }''; desc = "Move window up"; category = "Focus"; }
    { keys = "SUPER + SHIFT + down"; lua = ''hl.dsp.window.move{ direction = "down" }''; desc = "Move window down"; category = "Focus"; }
    # swapcol exchanges the focused column with its neighbour, carrying every
    # window in it; focus stays with the column and the viewport follows. It
    # wraps (scrolling:wrap_swapcol defaults true). No vertical equivalent
    # exists — columns are only ordered horizontally. Scrolling-layout only,
    # so it silently does nothing on workspace 2, which pins dwindle.
    { keys = "SUPER + CTRL + left"; lua = ''hl.dsp.layout("swapcol l")''; desc = "Move column left"; category = "Focus"; }
    { keys = "SUPER + CTRL + right"; lua = ''hl.dsp.layout("swapcol r")''; desc = "Move column right"; category = "Focus"; }
    { keys = "ALT + Tab"; exec = "snappy-switcher next"; desc = "Next window"; category = "Focus"; menu = false; }
    { keys = "ALT + SHIFT + Tab"; exec = "snappy-switcher prev"; desc = "Previous window"; category = "Focus"; menu = false; }

    # ── Layout ──────────────────────────────────────────────────────────────
    { keys = "SUPER + bracketleft"; label = "SUPER + [";  lua = ''hl.dsp.layout("colresize -conf")''; desc = "Narrower column"; category = "Layout"; }
    { keys = "SUPER + bracketright"; label = "SUPER + ]"; lua = ''hl.dsp.layout("colresize +conf")''; desc = "Wider column"; category = "Layout"; }
    # Not SUPER+L, which is hyprlock — losing the lock key to a layout toggle
    # would be a bad trade.
    { keys = "SUPER + ALT + L"; exec = "layout-toggle"; desc = "Switch layout: scrolling ↔ dwindle"; category = "Layout"; }

    # ── Workspaces ──────────────────────────────────────────────────────────
    { keys = null; label = "SUPER + ${wsFirst}-${wsLast}"; desc = "Switch to workspace 1-10 (0 = 10)"; category = "Workspaces"; }
    { keys = null; label = "SUPER + SHIFT + ${wsFirst}-${wsLast}"; desc = "Move window to workspace 1-10"; category = "Workspaces"; }

    # ── Scratchpads ─────────────────────────────────────────────────────────
    # cedilla is the key left of 1 on the si layout.
    { keys = "cedilla"; label = "cedilla (key left of 1)"; lua = ''hl.dsp.workspace.toggle_special("term")''; desc = "Drop-down terminal"; category = "Scratchpads"; }
    { keys = "SUPER + T"; lua = ''hl.dsp.workspace.toggle_special("tasks")''; desc = "Task list (taskwarrior-tui)"; category = "Scratchpads"; }
    { keys = "SUPER + S"; lua = ''hl.dsp.workspace.toggle_special("magic")''; desc = "Scratchpad"; category = "Scratchpads"; }
    { keys = "SUPER + SHIFT + S"; lua = ''hl.dsp.window.move{ workspace = "special:magic" }''; desc = "Send window to the scratchpad"; category = "Scratchpads"; }

    # ── Capture ─────────────────────────────────────────────────────────────
    { keys = "Print"; exec = ''grim -g "$(slurp)" - | wl-copy''; desc = "Screenshot region → clipboard"; category = "Capture"; }
    { keys = "SUPER + Print"; exec = "grim - | wl-copy"; desc = "Screenshot screen → clipboard"; category = "Capture"; }
    # Region → satty → wherever you send it. See hyprland/screenshot.nix for
    # what satty does and does not save by itself.
    { keys = "SHIFT + Print"; exec = "screenshot-annotate"; desc = "Screenshot region → annotate → clipboard"; category = "Capture"; }
    { keys = "SUPER + CTRL + Print"; exec = "ocr-region"; desc = "OCR region → clipboard (slv+eng)"; category = "Capture"; }
    # Not SUPER+Print (Omarchy's key for this) — that is already full-screen
    # capture here.
    { keys = "SUPER + SHIFT + Print"; exec = "hyprpicker -a"; desc = "Pick a colour → clipboard"; category = "Capture"; }

    # ── Clipboard ───────────────────────────────────────────────────────────
    { keys = "SUPER + V"; exec = "rofi-clipboard"; desc = "Clipboard history"; category = "Clipboard"; }

    # ── Reminders ───────────────────────────────────────────────────────────
    # No argument opens a fuzzel prompt; `remind 7 tea is ready` from a shell
    # does the same thing without one.
    { keys = "SUPER + CTRL + R"; exec = "remind"; desc = "Set a reminder"; category = "Reminders"; }
    { keys = "SUPER + CTRL + ALT + R"; exec = "reminders-list"; desc = "List pending reminders"; category = "Reminders"; }
    { keys = "SUPER + CTRL + SHIFT + R"; exec = "reminders-clear"; desc = "Cancel all reminders"; category = "Reminders"; }

    # ── Notices ─────────────────────────────────────────────────────────────
    # Wayle's bar shows all three already; these are for when a fullscreen
    # window is covering it.
    { keys = "SUPER + CTRL + ALT + T"; exec = "notice-time"; desc = "Time and date"; category = "Notices"; }
    { keys = "SUPER + CTRL + ALT + B"; exec = "notice-battery"; desc = "Battery level"; category = "Notices"; }
    { keys = "SUPER + CTRL + ALT + W"; exec = "notice-weather"; desc = "Weather"; category = "Notices"; }

    # ── Toggles ─────────────────────────────────────────────────────────────
    { keys = "SUPER + CTRL + I"; exec = "idle-toggle"; desc = "Toggle idle inhibit (no lock, no sleep)"; category = "Toggles"; }
    # Manual override for gammastep, which otherwise follows the sun by itself.
    { keys = "SUPER + CTRL + N"; exec = "nightlight-toggle"; desc = "Toggle night light"; category = "Toggles"; }

    # ── Appearance ──────────────────────────────────────────────────────────
    # Repaints the wallpaper and re-runs matugen, so the whole session — bar,
    # terminal, launchers, lock screen — retints from the new image.
    { keys = "SUPER + SHIFT + W"; exec = "wallpaper-next"; desc = "Next wallpaper (retints the session)"; category = "Appearance"; }

    # ── Dictation ───────────────────────────────────────────────────────────
    # Toggle for long dictation; F9 is hold-to-talk, so it needs a second bind
    # for the key-up edge. `{ release = true }` is the Lua API's spelling of
    # hyprlang's bindr (LuaBindingsToplevel.cpp reads the opts table's
    # `release` field) — note that --verify-config accepts any key here,
    # including misspelled ones, so this cannot be checked by parsing alone.
    { keys = "SUPER + CTRL + X"; exec = "voxtype record toggle"; desc = "Toggle dictation"; category = "Dictation"; }
    { keys = "F9"; exec = "voxtype record start"; desc = "Hold to dictate"; category = "Dictation"; menu = false; }
    { keys = "F9"; exec = "voxtype record stop"; opts = "{ release = true }"; category = "Dictation"; desc = "Stop dictating on key release"; doc = false; menu = false; }

    # ── Media ───────────────────────────────────────────────────────────────
    # These called swayosd-client until df79e86 removed swayosd with the Niri
    # stack, leaving six dead binds. Wayle draws its own OSD and is already
    # what the bar's scroll bindings use, so no extra daemon.
    { keys = "XF86AudioRaiseVolume"; exec = "wayle audio output-volume +5"; desc = "Volume up"; category = "Media"; menu = false; }
    { keys = "XF86AudioLowerVolume"; exec = "wayle audio output-volume -5"; desc = "Volume down"; category = "Media"; menu = false; }
    { keys = "XF86AudioMute"; exec = "wayle audio output-mute"; desc = "Mute output"; category = "Media"; menu = false; }
    { keys = "XF86AudioMicMute"; exec = "wayle audio input-mute"; desc = "Mute microphone"; category = "Media"; menu = false; }
    { keys = "XF86MonBrightnessUp"; exec = "brightnessctl set +5%"; desc = "Brightness up"; category = "Media"; menu = false; }
    { keys = "XF86MonBrightnessDown"; exec = "brightnessctl set 5%-"; desc = "Brightness down"; category = "Media"; menu = false; }

    # ── System ──────────────────────────────────────────────────────────────
    { keys = "SUPER + ALT + SPACE"; exec = "hypr-menu"; desc = "Action menu — everything on this page, searchable"; category = "System"; menu = false; }
    { keys = "SUPER + K"; exec = "hypr-cheatsheet"; desc = "Show this keybinding list"; category = "System"; }
    { keys = "SUPER + L"; exec = "hyprlock"; desc = "Lock screen"; category = "System"; }
    { keys = "SUPER + SHIFT + Q"; exec = "rofi-power"; desc = "Power menu"; category = "System"; }

    # ── Mouse ───────────────────────────────────────────────────────────────
    { keys = "SUPER + mouse:272"; label = "SUPER + drag LMB"; lua = "hl.dsp.window.drag()"; desc = "Move window"; category = "Mouse"; }
    { keys = "SUPER + mouse:273"; label = "SUPER + drag RMB"; lua = "hl.dsp.window.resize()"; desc = "Resize window"; category = "Mouse"; }
  ] ++ workspaceBinds;

  all = map norm raw;

  inCategory = cat: builtins.filter (b: b.category == cat) all;

  # ── Renderers ─────────────────────────────────────────────────────────────

  # Long brackets rather than quotes: several commands contain " and $(...),
  # and [[ ]] passes both through to Lua untouched.
  luaBind = b:
    let
      dispatcher = if b.exec != null then "hl.dsp.exec_cmd([[${b.exec}]])" else b.lua;
      opts = if b.opts != null then ", ${b.opts}" else "";
    in ''hl.bind("${b.keys}", ${dispatcher}${opts})'';

  luaSection = cat:
    let bound = builtins.filter (b: b.exec != null || b.lua != null) (inCategory cat);
    in if bound == [] then []
       else [ (concat "\n" ([ "-- ── ${cat} ──" ] ++ map luaBind bound)) ];

  mdSection = cat:
    let documented = builtins.filter (b: b.doc) (inCategory cat);
    in if documented == [] then []
       else [ (concat "\n" ([ "## ${cat}" "" "| Keybind | Action |" "|---|---|" ]
                            ++ map (b: "| `${b.display}` | ${b.desc} |") documented)) ];

  menuSection = cat:
    map (b: "${cat} · ${b.desc}  ·  ${b.display}\t${b.exec}")
      (builtins.filter (b: b.menu && b.exec != null) (inCategory cat));
in rec {
  # Rendering order for every artefact below.
  categories = [
    "Apps"
    "Windows"
    "Focus"
    "Layout"
    "Workspaces"
    "Scratchpads"
    "Capture"
    "Clipboard"
    "Reminders"
    "Notices"
    "Toggles"
    "Appearance"
    "Dictation"
    "Media"
    "System"
    "Mouse"
  ];

  # The normalised entries, for anything that wants to render them differently.
  inherit all;

  lua = concat "\n\n" (builtins.concatMap luaSection categories);

  # display<TAB>command, one runnable action per line. menu.nix shows column
  # one and looks the command back up by exact match, so the display strings
  # have to stay unique — category + description keeps them so.
  menuTsv = concat "\n" (builtins.concatMap menuSection categories) + "\n";

  docsMarkdown = concat "\n\n" ([
    ("<!-- Generated from home/modules/hyprland/binds.nix — do not edit by hand.\n"
     + "     Regenerate: nix eval --raw -f home/modules/hyprland/binds.nix docsMarkdown > docs/keybindings.md -->")
    "# Hyprland keybindings"
    "**SUPER** is the Windows key. `SUPER+ALT+SPACE` opens the searchable action menu; `SUPER+K` shows this list in a window."
  ] ++ builtins.concatMap mdSection categories) + "\n";
}
