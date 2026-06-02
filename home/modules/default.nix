{...}: {
  imports = [
    ./niri/niri.nix
    ./hyprland/hyprland.nix
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
    ./vibepanel.nix
    ./mpv.nix
    ./dolphin.nix
    ./taskwarrior.nix
    ./matugen.nix
  ];
}
