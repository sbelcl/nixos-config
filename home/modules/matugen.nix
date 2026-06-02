#
# ~/.nixos/home/modules/matugen.nix
#
# Matugen template configuration — generates per-app color schemes from the
# current wallpaper whenever HyprPanel calls `matugen image <wallpaper>`.
# home-manager owns the templates; matugen owns the output files.
#
{ pkgs, lib, ... }: {

  home.packages = [ pkgs.matugen ];

  # ── Matugen config ──────────────────────────────────────────────────────────

  xdg.configFile."matugen/config.toml".text = ''
    [templates.kdeglobals]
    input_path  = "~/.config/matugen/templates/kdeglobals.ini"
    output_path = "~/.config/kdeglobals"
    post_hook   = "dbus-send --session --type=signal /KGlobalSettings org.kde.KGlobalSettings.notifyChange int32:0 int32:0 2>/dev/null || true"

    [templates.alacritty-colors]
    input_path  = "~/.config/matugen/templates/alacritty-colors.toml"
    output_path = "~/.config/alacritty/colors.toml"

    [templates.hyprlock-colors]
    input_path  = "~/.config/matugen/templates/hyprlock-colors.conf"
    output_path = "~/.config/hypr/hyprlock-colors.conf"

    [templates.fuzzel]
    input_path  = "~/.config/matugen/templates/fuzzel.ini"
    output_path = "~/.config/fuzzel/fuzzel.ini"

    [templates.rofi-colors]
    input_path  = "~/.config/matugen/templates/rofi-colors.rasi"
    output_path = "~/.config/rofi/colors.rasi"

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
    BackgroundNormal={{colors.background.default.rgb.r}},{{colors.background.default.rgb.g}},{{colors.background.default.rgb.b}}
    BackgroundAlternate={{colors.surface_variant.default.rgb.r}},{{colors.surface_variant.default.rgb.g}},{{colors.surface_variant.default.rgb.b}}
    ForegroundNormal={{colors.on_surface.default.rgb.r}},{{colors.on_surface.default.rgb.g}},{{colors.on_surface.default.rgb.b}}
    ForegroundInactive={{colors.on_surface_variant.default.rgb.r}},{{colors.on_surface_variant.default.rgb.g}},{{colors.on_surface_variant.default.rgb.b}}
    ForegroundActive={{colors.primary.default.rgb.r}},{{colors.primary.default.rgb.g}},{{colors.primary.default.rgb.b}}
    ForegroundLink={{colors.secondary.default.rgb.r}},{{colors.secondary.default.rgb.g}},{{colors.secondary.default.rgb.b}}
    ForegroundNegative={{colors.error.default.rgb.r}},{{colors.error.default.rgb.g}},{{colors.error.default.rgb.b}}
    ForegroundNeutral={{colors.tertiary.default.rgb.r}},{{colors.tertiary.default.rgb.g}},{{colors.tertiary.default.rgb.b}}
    ForegroundPositive={{colors.tertiary_container.default.rgb.r}},{{colors.tertiary_container.default.rgb.g}},{{colors.tertiary_container.default.rgb.b}}
    ForegroundVisited={{colors.outline.default.rgb.r}},{{colors.outline.default.rgb.g}},{{colors.outline.default.rgb.b}}
    DecorationFocus={{colors.primary.default.rgb.r}},{{colors.primary.default.rgb.g}},{{colors.primary.default.rgb.b}}
    DecorationHover={{colors.primary.default.rgb.r}},{{colors.primary.default.rgb.g}},{{colors.primary.default.rgb.b}}

    [Colors:Window]
    BackgroundNormal={{colors.surface.default.rgb.r}},{{colors.surface.default.rgb.g}},{{colors.surface.default.rgb.b}}
    BackgroundAlternate={{colors.surface.default.rgb.r}},{{colors.surface.default.rgb.g}},{{colors.surface.default.rgb.b}}
    ForegroundNormal={{colors.on_surface.default.rgb.r}},{{colors.on_surface.default.rgb.g}},{{colors.on_surface.default.rgb.b}}

    [Colors:Button]
    BackgroundNormal={{colors.surface_variant.default.rgb.r}},{{colors.surface_variant.default.rgb.g}},{{colors.surface_variant.default.rgb.b}}
    BackgroundAlternate={{colors.surface_variant.default.rgb.r}},{{colors.surface_variant.default.rgb.g}},{{colors.surface_variant.default.rgb.b}}
    ForegroundNormal={{colors.on_surface.default.rgb.r}},{{colors.on_surface.default.rgb.g}},{{colors.on_surface.default.rgb.b}}

    [Colors:Selection]
    BackgroundNormal={{colors.primary.default.rgb.r}},{{colors.primary.default.rgb.g}},{{colors.primary.default.rgb.b}}
    ForegroundNormal={{colors.on_primary.default.rgb.r}},{{colors.on_primary.default.rgb.g}},{{colors.on_primary.default.rgb.b}}

    [Colors:Tooltip]
    BackgroundNormal={{colors.surface_variant.default.rgb.r}},{{colors.surface_variant.default.rgb.g}},{{colors.surface_variant.default.rgb.b}}
    ForegroundNormal={{colors.on_surface_variant.default.rgb.r}},{{colors.on_surface_variant.default.rgb.g}},{{colors.on_surface_variant.default.rgb.b}}
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

    [colors.normal]
    black   = "{{colors.surface.default.hex}}"
    red     = "{{colors.error.default.hex}}"
    green   = "{{colors.tertiary.default.hex}}"
    yellow  = "{{colors.secondary.default.hex}}"
    blue    = "{{colors.primary.default.hex}}"
    magenta = "{{colors.secondary_container.default.hex}}"
    cyan    = "{{colors.tertiary_container.default.hex}}"
    white   = "{{colors.on_surface.default.hex}}"

    [colors.bright]
    black   = "{{colors.surface_variant.default.hex}}"
    red     = "{{colors.on_error_container.default.hex}}"
    green   = "{{colors.on_tertiary_container.default.hex}}"
    yellow  = "{{colors.on_secondary_container.default.hex}}"
    blue    = "{{colors.primary_container.default.hex}}"
    magenta = "{{colors.tertiary_container.default.hex}}"
    cyan    = "{{colors.secondary_container.default.hex}}"
    white   = "{{colors.on_background.default.hex}}"

    [colors.dim]
    black   = "{{colors.background.default.hex}}"
    red     = "{{colors.error_container.default.hex}}"
    green   = "{{colors.tertiary_container.default.hex}}"
    yellow  = "{{colors.secondary_container.default.hex}}"
    blue    = "{{colors.primary_container.default.hex}}"
    magenta = "{{colors.on_tertiary.default.hex}}"
    cyan    = "{{colors.on_secondary.default.hex}}"
    white   = "{{colors.outline.default.hex}}"
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
    border-width=2
    border-radius=10
    icon-theme=Papirus-Dark
    icons-enabled=yes
    prompt=
    placeholder=Search apps...
    anchor=center
    match-mode=fuzzy
    show-actions=yes

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
        niri-active: {{colors.primary.default.hex}};
        pink:        {{colors.error.default.hex}};
        transparent: rgba(0,0,0,0);
    }
  '';

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

  # ── First-run activation ─────────────────────────────────────────────────────
  # Generate color files once on first updhome (HyprPanel handles subsequent
  # updates when the wallpaper changes).
  home.activation.matugenInit = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [ ! -f "$HOME/.config/rofi/colors.rasi" ] && [ -f "$HOME/.config/background" ]; then
      echo "matugen: generating initial color schemes from wallpaper..."
      $DRY_RUN_CMD ${pkgs.matugen}/bin/matugen image "$HOME/.config/background" 2>/dev/null || true
    fi
  '';
}
