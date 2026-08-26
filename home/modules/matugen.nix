#
# ~/.nixos/home/modules/matugen.nix
#
# Matugen template configuration — generates per-app color schemes from the
# current wallpaper. HyprPanel used to invoke matugen; it was replaced by
# Wayle, so the trigger is now wallpaper-next (modules/rofi.nix, SUPER+SHIFT+W).
# home-manager owns the templates; matugen owns the output files.
#
{
  config,
  pkgs,
  lib,
  ...
}: let
  # Every template this module owns, keyed by its xdg.configFile path. Each
  # entry's .source is a store path derived from its text, so hashing the set
  # of paths yields a value that changes iff some template's content changed.
  matugenTemplates =
    lib.filterAttrs (name: _: lib.hasPrefix "matugen/templates/" name) config.xdg.configFile;

  templateStampFile =
    pkgs.writeText "matugen-templates-stamp"
    (builtins.hashString "sha256"
      (lib.concatMapStringsSep "\n" (f: toString f.source) (lib.attrValues matugenTemplates)));
in {
  home.packages = [ pkgs.matugen ];

  # ── Matugen config ──────────────────────────────────────────────────────────

  xdg.configFile."matugen/config.toml".text = ''
    [config]
    scheme_type = "scheme-monochrome"
    contrast    = 0.0

    [templates.kdeglobals]
    input_path  = "~/.config/matugen/templates/kdeglobals.ini"
    output_path = "~/.config/kdeglobals"
    post_hook   = "dbus-send --session --type=signal /KGlobalSettings org.kde.KGlobalSettings.notifyChange int32:0 int32:0 2>/dev/null || true"

    [templates.alacritty-colors]
    input_path  = "~/.config/matugen/templates/alacritty-colors.toml"
    output_path = "~/.config/alacritty/colors.toml"

    [templates.hyprland-colors]
    input_path  = "~/.config/matugen/templates/hypr-colors.lua"
    output_path = "~/.config/hypr/colors.lua"
    # Applies the new borders to the running compositor. `hyprctl keyword` is
    # refused by the Lua parser (see qol.nix), and eval takes a Lua snippet,
    # so the snippet is simply "load the file we just wrote". Without this the
    # colours would only appear at the next Hyprland start.
    post_hook   = '${pkgs.hyprland}/bin/hyprctl eval "dofile([[${config.home.homeDirectory}/.config/hypr/colors.lua]])" >/dev/null 2>&1 || true'

    [templates.hyprlock-colors]
    input_path  = "~/.config/matugen/templates/hyprlock-colors.conf"
    output_path = "~/.config/hypr/hyprlock-colors.conf"

    [templates.fuzzel]
    input_path  = "~/.config/matugen/templates/fuzzel.ini"
    output_path = "~/.config/fuzzel/fuzzel.ini"

    [templates.rofi-colors]
    input_path  = "~/.config/matugen/templates/rofi-colors.rasi"
    output_path = "~/.config/rofi/colors.rasi"

    [templates.btop]
    input_path  = "~/.config/matugen/templates/btop.theme"
    output_path = "~/.config/btop/themes/matugen.theme"

    [templates.colors-sh]
    input_path  = "~/.config/matugen/templates/colors.sh"
    output_path = "~/.config/theme/colors.sh"
  '';

  # ── Templates ───────────────────────────────────────────────────────────────

  xdg.configFile."matugen/templates/kdeglobals.ini".text = ''
    [General]
    ColorScheme=Matugen

    [KDE]
    LookAndFeelPackage=org.kde.breezedark.desktop

    [Colors:View]
    BackgroundNormal={{colors.background.default.red}},{{colors.background.default.green}},{{colors.background.default.blue}}
    BackgroundAlternate={{colors.surface_variant.default.red}},{{colors.surface_variant.default.green}},{{colors.surface_variant.default.blue}}
    ForegroundNormal={{colors.on_surface.default.red}},{{colors.on_surface.default.green}},{{colors.on_surface.default.blue}}
    ForegroundInactive={{colors.on_surface_variant.default.red}},{{colors.on_surface_variant.default.green}},{{colors.on_surface_variant.default.blue}}
    ForegroundActive={{colors.primary.default.red}},{{colors.primary.default.green}},{{colors.primary.default.blue}}
    ForegroundLink={{colors.secondary.default.red}},{{colors.secondary.default.green}},{{colors.secondary.default.blue}}
    ForegroundNegative={{colors.error.default.red}},{{colors.error.default.green}},{{colors.error.default.blue}}
    ForegroundNeutral={{colors.tertiary.default.red}},{{colors.tertiary.default.green}},{{colors.tertiary.default.blue}}
    ForegroundPositive={{colors.tertiary_container.default.red}},{{colors.tertiary_container.default.green}},{{colors.tertiary_container.default.blue}}
    ForegroundVisited={{colors.outline.default.red}},{{colors.outline.default.green}},{{colors.outline.default.blue}}
    DecorationFocus={{colors.primary.default.red}},{{colors.primary.default.green}},{{colors.primary.default.blue}}
    DecorationHover={{colors.primary.default.red}},{{colors.primary.default.green}},{{colors.primary.default.blue}}

    [Colors:Window]
    BackgroundNormal={{colors.surface.default.red}},{{colors.surface.default.green}},{{colors.surface.default.blue}}
    BackgroundAlternate={{colors.surface.default.red}},{{colors.surface.default.green}},{{colors.surface.default.blue}}
    ForegroundNormal={{colors.on_surface.default.red}},{{colors.on_surface.default.green}},{{colors.on_surface.default.blue}}

    [Colors:Button]
    BackgroundNormal={{colors.surface_variant.default.red}},{{colors.surface_variant.default.green}},{{colors.surface_variant.default.blue}}
    BackgroundAlternate={{colors.surface_variant.default.red}},{{colors.surface_variant.default.green}},{{colors.surface_variant.default.blue}}
    ForegroundNormal={{colors.on_surface.default.red}},{{colors.on_surface.default.green}},{{colors.on_surface.default.blue}}

    [Colors:Selection]
    BackgroundNormal={{colors.primary.default.red}},{{colors.primary.default.green}},{{colors.primary.default.blue}}
    ForegroundNormal={{colors.on_primary.default.red}},{{colors.on_primary.default.green}},{{colors.on_primary.default.blue}}

    [Colors:Tooltip]
    BackgroundNormal={{colors.surface_variant.default.red}},{{colors.surface_variant.default.green}},{{colors.surface_variant.default.blue}}
    ForegroundNormal={{colors.on_surface_variant.default.red}},{{colors.on_surface_variant.default.green}},{{colors.on_surface_variant.default.blue}}
  '';

  xdg.configFile."matugen/templates/alacritty-colors.toml".text = ''
    [colors.primary]
    background        = "{{colors.background.default.hex}}"
    foreground        = "{{colors.on_background.default.hex}}"
    dim_foreground    = "{{colors.on_surface_variant.default.hex}}"
    bright_foreground = "{{colors.inverse_on_surface.default.hex}}"

    [colors.cursor]
    text   = "{{colors.on_primary.default.hex}}"
    cursor = "{{colors.primary.default.hex}}"

    [colors.vi_mode_cursor]
    text   = "{{colors.on_secondary.default.hex}}"
    cursor = "{{colors.secondary.default.hex}}"

    [colors.selection]
    text       = "CellForeground"
    background = "{{colors.surface_variant.default.hex}}"

    # ANSI slots must be *foreground* roles. Material `*_container` and
    # `surface_*` roles are background tones by design — using them as text
    # gave 2.0:1 contrast on every wallpaper (normal.magenta/cyan and
    # bright.blue/magenta/cyan were all effectively invisible, which is what
    # made ranger's directory and symlink colors unreadable).
    #
    # `primary|secondary|tertiary|error` are ~11:1 and the `*_fixed` /
    # `on_*_container` family is ~14:1, in dark mode, for every wallpaper in
    # ~/Slike/Ozadja — checked by computing WCAG contrast for all 22. Keep new
    # entries inside those two families.
    #
    # black/bright.black stay dark on purpose: that is what those slots mean.
    [colors.normal]
    black   = "{{colors.surface_variant.default.hex}}"
    red     = "{{colors.error.default.hex}}"
    green   = "{{colors.tertiary.default.hex}}"
    yellow  = "{{colors.secondary.default.hex}}"
    blue    = "{{colors.primary.default.hex}}"
    magenta = "{{colors.tertiary_fixed_dim.default.hex}}"
    cyan    = "{{colors.primary_fixed_dim.default.hex}}"
    white   = "{{colors.on_surface_variant.default.hex}}"

    [colors.bright]
    black   = "{{colors.outline.default.hex}}"
    red     = "{{colors.on_error_container.default.hex}}"
    green   = "{{colors.tertiary_fixed.default.hex}}"
    yellow  = "{{colors.secondary_fixed.default.hex}}"
    blue    = "{{colors.primary_fixed.default.hex}}"
    magenta = "{{colors.on_tertiary_container.default.hex}}"
    cyan    = "{{colors.on_primary_container.default.hex}}"
    white   = "{{colors.on_surface.default.hex}}"

    # No [colors.dim]: alacritty derives dim from the normal colors when it is
    # unset, which is strictly better than the previous hand-mapping — that one
    # pointed every dim slot at a container role too.
  '';

  # Window borders. Loaded by hyprland.lua at start (guarded — see config.nix)
  # and re-applied live by the post_hook above, so a wallpaper change retints
  # the focused window's border along with everything else.
  #
  # primary → tertiary for the active gradient: both are foreground-role
  # accents, so they stay visible against any wallpaper-derived background,
  # and they differ enough from each other to read as a gradient rather than
  # a flat edge. outline at 88 alpha for inactive, which is what the
  # hand-picked rgba(39393988) it replaces was doing.
  xdg.configFile."matugen/templates/hypr-colors.lua".text = ''
    -- Generated by matugen from the current wallpaper. Do not edit:
    -- the template is in ~/.nixos/home/modules/matugen.nix.
    hl.config{ general = {
      ["col.active_border"] = {
        colors = { "rgba({{colors.primary.default.hex_stripped}}ee)",
                   "rgba({{colors.tertiary.default.hex_stripped}}ff)" },
        angle = 45,
      },
      ["col.inactive_border"] = "rgba({{colors.outline.default.hex_stripped}}88)",
    } }
  '';

  # Hyprlang variables sourced by hyprlock.conf
  xdg.configFile."matugen/templates/hyprlock-colors.conf".text = ''
    $inputOutline  = rgba({{colors.primary.default.hex_stripped}}aa)
    $inputBg       = rgba({{colors.background.default.hex_stripped}}cc)
    $inputFg       = rgb({{colors.on_background.default.hex_stripped}})
    $checkColor    = rgba({{colors.primary.default.hex_stripped}}ff)
    $failColor     = rgba({{colors.error.default.hex_stripped}}ff)
    $capslockColor = rgba(f97316ff)
    $clockColor    = rgba({{colors.on_background.default.hex_stripped}}ff)
    $dateColor     = rgba({{colors.on_surface_variant.default.hex_stripped}}cc)
  '';

  xdg.configFile."matugen/templates/fuzzel.ini".text = ''
    [main]
    font=JetBrainsMono Nerd Font:size=12
    lines=10
    width=42
    horizontal-pad=20
    vertical-pad=12
    inner-pad=8
    icon-theme=Papirus-Dark
    icons-enabled=yes
    prompt="> "
    placeholder=Search apps...
    anchor=center
    match-mode=fuzzy
    show-actions=yes

    # border-width/border-radius are not [main] keys — fuzzel warns and skips
    # them there. They live in [border] as width/radius.
    [border]
    width=2
    radius=10

    [colors]
    background={{colors.background.default.hex_stripped}}f5
    text={{colors.on_background.default.hex_stripped}}ff
    prompt={{colors.primary.default.hex_stripped}}ff
    placeholder={{colors.on_surface_variant.default.hex_stripped}}aa
    input={{colors.on_background.default.hex_stripped}}ff
    match={{colors.primary.default.hex_stripped}}ff
    selection={{colors.surface_variant.default.hex_stripped}}ff
    selection-text={{colors.on_surface.default.hex_stripped}}ff
    selection-match={{colors.primary.default.hex_stripped}}ff
    border={{colors.outline.default.hex_stripped}}cc
  '';

  # Variables for rofi theme.rasi (@import "~/.config/rofi/colors.rasi")
  xdg.configFile."matugen/templates/rofi-colors.rasi".text = ''
    * {
        bg:          {{colors.background.default.hex}};
        bg-alt:      {{colors.surface.default.hex}};
        bg-hover:    {{colors.surface_variant.default.hex}};
        fg:          {{colors.on_background.default.hex}};
        fg-dim:      {{colors.on_surface_variant.default.hex}};
        cyan:        {{colors.secondary.default.hex}};
        accent: {{colors.primary.default.hex}};
        pink:        {{colors.error.default.hex}};
        transparent: rgba(0,0,0,0);
    }
  '';

  # btop theme. Keys btop does not find fall back to its built-in defaults, so
  # a partial theme degrades rather than breaks — but every slot that draws
  # something on the default screen is covered here.
  #
  # The *_start/_mid/_end triples are gradients drawn low→high, so they run
  # calm→alarming: tertiary through secondary to error. Boxes and dividers use
  # outline, which is what a border is for.
  xdg.configFile."matugen/templates/btop.theme".text = ''
    # Generated by matugen from the current wallpaper. Do not edit:
    # the template is in ~/.nixos/home/modules/matugen.nix.
    theme[main_bg]="{{colors.background.default.hex}}"
    theme[main_fg]="{{colors.on_background.default.hex}}"
    theme[title]="{{colors.primary.default.hex}}"
    theme[hi_fg]="{{colors.primary.default.hex}}"
    theme[selected_bg]="{{colors.surface_variant.default.hex}}"
    theme[selected_fg]="{{colors.on_surface.default.hex}}"
    theme[inactive_fg]="{{colors.outline.default.hex}}"
    theme[graph_text]="{{colors.on_surface_variant.default.hex}}"
    theme[meter_bg]="{{colors.surface_variant.default.hex}}"
    theme[proc_misc]="{{colors.tertiary.default.hex}}"

    theme[cpu_box]="{{colors.outline.default.hex}}"
    theme[mem_box]="{{colors.outline.default.hex}}"
    theme[net_box]="{{colors.outline.default.hex}}"
    theme[proc_box]="{{colors.outline.default.hex}}"
    theme[div_line]="{{colors.outline.default.hex}}"

    theme[temp_start]="{{colors.tertiary.default.hex}}"
    theme[temp_mid]="{{colors.secondary.default.hex}}"
    theme[temp_end]="{{colors.error.default.hex}}"

    theme[cpu_start]="{{colors.tertiary.default.hex}}"
    theme[cpu_mid]="{{colors.secondary.default.hex}}"
    theme[cpu_end]="{{colors.error.default.hex}}"

    theme[free_start]="{{colors.primary_fixed_dim.default.hex}}"
    theme[free_mid]="{{colors.primary.default.hex}}"
    theme[free_end]="{{colors.primary_fixed.default.hex}}"

    theme[cached_start]="{{colors.secondary_fixed_dim.default.hex}}"
    theme[cached_mid]="{{colors.secondary.default.hex}}"
    theme[cached_end]="{{colors.secondary_fixed.default.hex}}"

    theme[available_start]="{{colors.tertiary_fixed_dim.default.hex}}"
    theme[available_mid]="{{colors.tertiary.default.hex}}"
    theme[available_end]="{{colors.tertiary_fixed.default.hex}}"

    theme[used_start]="{{colors.tertiary.default.hex}}"
    theme[used_mid]="{{colors.secondary.default.hex}}"
    theme[used_end]="{{colors.error.default.hex}}"

    theme[download_start]="{{colors.primary_fixed_dim.default.hex}}"
    theme[download_mid]="{{colors.primary.default.hex}}"
    theme[download_end]="{{colors.primary_fixed.default.hex}}"

    theme[upload_start]="{{colors.tertiary_fixed_dim.default.hex}}"
    theme[upload_mid]="{{colors.tertiary.default.hex}}"
    theme[upload_end]="{{colors.tertiary_fixed.default.hex}}"

    theme[process_start]="{{colors.tertiary.default.hex}}"
    theme[process_mid]="{{colors.secondary.default.hex}}"
    theme[process_end]="{{colors.error.default.hex}}"
  '';

  # btop only reads the theme above if its config points at it, and the theme
  # only exists where matugen runs — which is this module, flanker-only. So
  # the pointer lives here too rather than in packages.nix, where btop itself
  # is installed for both machines; fulcrum keeps btop's own default theme.
  #
  # theme_background = false lets Alacritty's own (translucent, blurred)
  # background through instead of painting the wallpaper's background colour
  # over it.
  programs.btop = {
    enable = true;
    settings = {
      color_theme = "matugen";
      theme_background = false;
      vim_keys = true;
    };
  };

  # Shell-sourceable colors for rofi scripts and other shell tools
  xdg.configFile."matugen/templates/colors.sh".text = ''
    BG="{{colors.background.default.hex}}"
    BG_ALT="{{colors.surface.default.hex}}"
    BG_SEL="{{colors.surface_variant.default.hex}}"
    FG="{{colors.on_background.default.hex}}"
    FG_DIM="{{colors.on_surface_variant.default.hex}}"
    ACCENT="{{colors.primary.default.hex}}"
    BORDER="{{colors.outline.default.hex}}"
    ERROR="{{colors.error.default.hex}}"
  '';

  # ── Activation ───────────────────────────────────────────────────────────────
  # home-manager owns the templates above, but matugen owns their *outputs*, so
  # editing a template here changes nothing until matugen runs again. Regenerate
  # on updhome whenever the template set changes (or an output has gone missing,
  # which also covers first run). A wallpaper change is still handled at runtime
  # by the panel's matugen hook, not here.
  #
  # templateStamp is a pure-eval hash of every template's store path, so it moves
  # exactly when a template's content does — no hashing at activation time.
  home.activation.matugenRegen = lib.hm.dag.entryAfter ["writeBoundary"] ''
    templateStamp="${config.xdg.cacheHome}/matugen-templates.stamp"
    if [ -f "$HOME/.config/background" ] &&
       { [ ! -f "${config.xdg.configHome}/rofi/colors.rasi" ] ||
         ! ${pkgs.diffutils}/bin/cmp -s ${templateStampFile} "$templateStamp"; }; then
      echo "matugen: regenerating color schemes (templates changed or outputs missing)..."
      # --prefer is mandatory: this wallpaper yields several candidate source
      # colors, and matugen aborts rather than pick one when it has no TTY to
      # ask on — which is always the case during activation.
      $DRY_RUN_CMD ${pkgs.matugen}/bin/matugen image "$HOME/.config/background" --prefer saturation || true
      $DRY_RUN_CMD ${pkgs.coreutils}/bin/install -Dm644 ${templateStampFile} "$templateStamp"
    fi
  '';
}
