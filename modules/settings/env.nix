#
# ~/.nixos/modules/settings/env.nix
#
# Environment variables for Wayland sessions
# Note: XDG_CURRENT_DESKTOP is set by the session/display manager
#
{
  environment.variables = {
    # Wayland session type
    XDG_SESSION_TYPE = "wayland";

    # Enable Wayland support for applications (system-wide requirements)
    MOZ_ENABLE_WAYLAND = "1"; # Firefox Wayland backend
    QT_QPA_PLATFORM = "wayland"; # Qt applications
    GDK_BACKEND = "wayland"; # GTK applications
    CLUTTER_BACKEND = "wayland"; # Clutter applications
    SDL_VIDEODRIVER = "wayland"; # SDL applications
    NIXOS_OZONE_WL = "1"; # Chromium/Electron Wayland support
    ELECTRON_OZONE_PLATFORM_HINT = "auto"; # Electron apps Wayland auto-detection

    # Java applications on non-reparenting window managers
    _JAVA_AWT_WM_NONREPARENTING = "1";

    # NVIDIA Wayland support
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    GBM_BACKEND = "nvidia-drm";

    # wlroots-based compositors (Niri, Hyprland) may need this
    WLR_NO_HARDWARE_CURSORS = "1";
  };
}
