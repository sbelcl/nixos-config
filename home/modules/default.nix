#
# Shared home-manager modules (DE/WM-agnostic).
# The Hyprland stack is imported per-host from home/hosts/<host>.nix so it
# doesn't leak into Plasma-only fulcrum.
#
{...}: {
  imports = [
    ./fonts.nix
    ./packages.nix
    ./neovim.nix
    ./users/imnos.nix
    ./session-variables.nix

    ./yandex.nix
    ./git.nix
    ./alacritty.nix
    ./rofi.nix
    ./fuzzel.nix
    ./battery.nix
    ./mpv.nix
    ./dolphin.nix
    ./taskwarrior.nix
    ./matugen.nix
  ];
}
