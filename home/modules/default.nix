{...}: {
  imports = [
    ./niri/niri.nix
    ./fonts.nix
    ./packages.nix
    ./neovim.nix
    ./users/imnos.nix
    ./session-variables.nix

    ./yandex.nix
    ./git.nix
    ./alacritty.nix
    ./rofi.nix
    ./battery.nix
    ./vibepanel.nix
    ./mpv.nix
    ./dolphin.nix
  ];
}
