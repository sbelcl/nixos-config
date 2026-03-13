#
# ~/.nixos/home/modules/session-variables.nix
#
{
  home.sessionVariables = {
    # User preferences (personal tool choices)
    EDITOR = "nvim";
    VISUAL = "nvim";
    BROWSER = "yandex-browser-beta";
    TERMINAL = "alacritty";

    # Cursor settings
    XCURSOR_SIZE = "24";  # Adjust to 32 or 48 for HiDPI displays
  };

  # Add user bin directory to PATH
  home.sessionPath = [
    "$HOME/.local/bin"
  ];
}
