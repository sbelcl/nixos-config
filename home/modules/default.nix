{ ... }:
{
  imports = [
    ./niri/niri.nix
    ./fonts.nix
    ./packages.nix
    ./neovim.nix
    ./users/imnos.nix
    ./session-variables.nix
    ./polkit-gnome.nix
    ./yandex.nix
    ./git.nix
  ];
}
