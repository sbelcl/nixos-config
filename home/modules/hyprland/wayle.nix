#
# ~/.nixos/home/modules/hyprland/wayle.nix
#
# Wayle — GTK4/Rust status bar & notification daemon (successor to HyprPanel).
# Runs as `wayle shell` from Hyprland's exec-once (see config.nix).
#
# Two config layers live in ~/.config/wayle:
#   config.toml  — declarative, managed below (a read-only store symlink)
#   runtime.toml — mutable overrides written by `wayle config set` and the
#                  wayle-settings GUI; overrides config.toml. Deliberately NOT
#                  managed here, so wallpaper-next can keep flipping
#                  styling.matugen-light at runtime (see modules/rofi.nix).
#
# If wayle-settings ever fails to save, it is writing config.toml rather than
# runtime.toml — drop the xdg.configFile block below to make it writable again.
#
{ pkgs, ... }: {
  home.packages = [
    pkgs.wayle
    pkgs.brightnessctl   # backend for Wayle's brightness module + scroll binding
  ];

  xdg.configFile."wayle/config.toml".text = ''
    # Wayle configuration — fiddling round 1
    #   * transparent bar + button backgrounds
    #   * monochrome (fg-colored) icons + labels
    #   * add brightness module
    #   * mouse-wheel volume/brightness

    [bar]
    background-opacity = 0
    button-bg-opacity = 0
    button-group-opacity = 0

    [[bar.layout]]
    monitor = "*"
    show = true
    left   = ["hyprland-workspaces"]
    center = ["media", "clock"]
    right  = ["systray", "battery", "bluetooth", "network", "microphone", "brightness", "volume", "dashboard"]

    # ── Volume ────────────────────────────────────────────────────────────────────
    [modules.volume]
    icon-color     = "fg-default"
    icon-bg-color  = "transparent"
    label-color    = "fg-default"
    scroll-up    = "wayle audio output-volume +5"
    scroll-down  = "wayle audio output-volume -5"

    # ── Brightness (needs pkgs.brightnessctl) ─────────────────────────────────────
    [modules.brightness]
    icon-color     = "fg-default"
    icon-bg-color  = "transparent"
    label-color    = "fg-default"
    scroll-up    = "brightnessctl set +5%"
    scroll-down  = "brightnessctl set 5%-"

    # ── Other modules — force fg color so nothing stays red/blue/yellow ───────────
    [modules.battery]
    icon-color = "fg-default"
    icon-bg-color = "transparent"
    label-color = "fg-default"

    [modules.bluetooth]
    icon-color = "fg-default"
    icon-bg-color = "transparent"
    label-color = "fg-default"

    [modules.network]
    icon-color = "fg-default"
    icon-bg-color = "transparent"
    label-color = "fg-default"

    [modules.microphone]
    icon-color = "fg-default"
    icon-bg-color = "transparent"
    label-color = "fg-default"

    [modules.clock]
    icon-color = "fg-default"
    icon-bg-color = "transparent"
    label-color = "fg-default"
    # Slovenian 24-hour: "pon 10. avg. 14:52"
    format = "%a %d. %b. %H:%M"
    # left-click keeps the Wayle dropdown calendar; middle opens Thunderbird's
    # calendar for a full-featured app view.
    middle-click = "thunderbird -calendar"

    # ── Workspaces (uses named workspaces from Hyprland: web/term/work/game) ─────
    [modules.hyprland-workspaces]
    label-use-name = true
    show-special = false
    active-color = "fg-default"
    container-bg-color = "transparent"

    # ── Dashboard = lock/logout/reboot/poweroff + system status widgets ──────────
    # Uses Wayle's built-in commands (loginctl/systemctl); no external menu needed.
    [modules.dashboard]
    icon-color = "fg-default"
    icon-bg-color = "transparent"

    [modules.media]
    icon-color = "fg-default"
    icon-bg-color = "transparent"
    label-color = "fg-default"

    # ── System tray ──────────────────────────────────────────────────────────
    # Wayle owns org.kde.StatusNotifierWatcher, so it collects tray items
    # whether or not the module is in the layout — without it, udiskie's
    # mount/unmount menu had nowhere to render. Transparent to match the bar.
    [modules.systray]
    button-bg-color = "transparent"
    border-show = false

    # ── Theming: follow the wallpaper ────────────────────────────────────────────
    # The bar is fully transparent, so its text sits on the wallpaper. matugen
    # derives Wayle's palette from the current wallpaper; wallpaper-next flips
    # styling.matugen-light by wallpaper luminance (written to runtime.toml, which
    # overrides this file) so text stays readable on light and dark wallpapers.
    [styling]
    theme-provider = "matugen"
  '';
}
