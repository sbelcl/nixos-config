#
# Shared home-manager modules (DE/WM-agnostic).
# WM-specific bits (Hyprland stack, rofi/fuzzel launchers, matugen theme sync,
# battery alerts) are imported per-host from home/hosts/<host>.nix so a host
# that does not run the compositor never pulls them in — tomcat (GNOME) is the
# one that doesn't today.
#
{...}: {
  imports = [
    ./fonts.nix
    ./packages.nix
    ./neovim.nix
    ./users/imnos.nix
    ./session-variables.nix

    ./yandex.nix
    ./webapps.nix
    ./git.nix
    ./alacritty.nix
    ./mpv.nix
    ./nautilus.nix
    ./kde-apps.nix
    ./ranger.nix
    ./taskwarrior.nix
  ];
}
