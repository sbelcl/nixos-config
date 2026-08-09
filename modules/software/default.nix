#
# ~/.nixos/modules/software/default.nix
#
{
  config,
  pkgs,
  ...
}: {
  imports = [
    ./common.nix
    ./thunar.nix
    ./steam.nix
    ./docker.nix
    ./libvirt.nix
    ./packages.nix
    ./hyprland.nix
    ./ollama.nix
  ];
}
