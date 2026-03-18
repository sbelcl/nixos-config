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
    XCURSOR_SIZE = "24";

    # Native Wayland rendering for Electron apps (VSCode, Discord, Obsidian…)
    NIXOS_OZONE_LAYER = "1";

    # Native Wayland for Firefox
    MOZ_ENABLE_WAYLAND = "1";
  };

  # Add user bin directory to PATH
  home.sessionPath = [
    "$HOME/.local/bin"
  ];
}
