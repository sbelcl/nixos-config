#
# ~/.nixos/home/modules/session-variables.nix
#
{
  home.sessionVariables = {
    # User preferences
    EDITOR = "nvim";
    VISUAL = "nvim";
    BROWSER = "yandex-browser-beta";
    TERMINAL = "alacritty";

    # Cursor
    XCURSOR_THEME = "Bibata-Modern-Classic";
    XCURSOR_SIZE = "24";

    # Native Wayland rendering for Electron apps (VSCode, Discord, Obsidian…).
    # The variable is NIXOS_OZONE_WL; this read NIXOS_OZONE_LAYER, which is not
    # a thing, so the setting did nothing. It went unnoticed because
    # modules/settings/env.nix sets the correct name system-wide — this one
    # only matters if the home config is ever used on a non-NixOS host.
    NIXOS_OZONE_WL = "1";

    # Native Wayland for Firefox
    MOZ_ENABLE_WAYLAND = "1";

    # LIBVA_DRIVER_NAME is host-scoped (nvidia on fulcrum, autodetect on flanker).
  };

  xdg.userDirs.setSessionVariables = true;

  # Propagate cursor into the systemd user environment (picked up by Wayland apps)
  systemd.user.sessionVariables = {
    XCURSOR_THEME = "Bibata-Modern-Classic";
    XCURSOR_SIZE = "24";
  };

  # Add user bin directory to PATH
  home.sessionPath = [
    "$HOME/.local/bin"
  ];
}
